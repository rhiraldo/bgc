#$Servers = Get-DBMSServers -envsels pilot01 -typesels app
$Servers = "TOR01L1BBCON01","TOR01L1BBCON02"
$StartTime = Get-Date
Invoke-Command -ComputerName $Servers -ScriptBlock{
#Define update criteria.
$Script = 
@'
$InstallCriteria = "IsInstalled=0 and Type='Software'"
$UninstallCriteria = "DeploymentAction='Uninstallation' and IsInstalled=1"

#Search for relevant updates.

$Searcher = New-Object -ComObject Microsoft.Update.Searcher

$InstallSearchResult = $Searcher.Search($InstallCriteria).Updates
$UninstallSearchResult = $Searcher.Search($UninstallCriteria).Updates

If(!($InstallSearchResult) -and !($UninstallSearchResult))
{
    return "Nothing to update"
}
Else
{
    $NeedDownload = $InstallSearchResult | ?{$_.IsDownloaded -eq $false}
    #Download updates.
    if($NeedDownload)
    {
        $Session = New-Object -ComObject Microsoft.Update.Session

        $Downloader = $Session.CreateUpdateDownloader()

        $Downloader.Updates = $InstallSearchResult

        $Downloader.Download()
    }


    #Install updates.



    $Installer = New-Object -ComObject Microsoft.Update.Installer
    if($UninstallSearchResult.Count -ge 1)
    {
        $Installer.Updates = $UninstallSearchResult

        $Result = $Installer.Uninstall()
        If($Result.rebootRequired) 
        {
            
            schtasks /create /TN "Windows-Updates" /SC "ONSTART" /TR "powershell.exe -file C:\Temp\Windows-Updates.ps1" /IT /F /RU "NT AUTHORITY\SYSTEM"
            shutdown.exe /t 0 /r
        }
    }

    if($InstallSearchResult.Count -ge 1)
    {
        $Installer.Updates = $InstallSearchResult
        $Result = $Installer.Install()
        if($Result.rebootRequired) 
        {
            schtasks /create /TN "Windows-Updates" /SC "ONSTART" /TR "powershell.exe -file C:\Temp\Windows-Updates.ps1" /IT /F /RU "NT AUTHORITY\SYSTEM"
            shutdown.exe /t 0 /r
        }        
    }
    $Criteria = "IsInstalled=0 and Type='Software' or (DeploymentAction='Uninstallation' and IsInstalled=1)"
    $Searcher = New-Object -ComObject Microsoft.Update.Searcher
    $SearchResult = $Searcher.Search($Criteria).Updates

    if(($SearchResult).Count -eq 0)
    {
        schtasks /delete /TN "Windows-Updates" /F 
    }
}

'@
$Script | Out-File C:\temp\Windows-Updates.ps1 -Force
$ExecutionTime = (Get-Date).AddMinutes(1).ToString("HH:mm")
schtasks /create /TN "Windows-Updates" /SC "ONCE" /TR "powershell.exe -file C:\Temp\Windows-Updates.ps1" /IT /F /RU "NT AUTHORITY\SYSTEM" /ST $ExecutionTime

}

$FullReport = @()
$Report=@()
$PendingComputers = @()
Do
{
	$Unreachable = @()
    $PendingComputers = (diff @($Report | ?{$_.Pending -lt 1} | Select -ExpandProperty PSComputerName) $Servers -ErrorAction SilentlyContinue) | Select -ExpandProperty InputObject -ErrorAction SilentlyContinue
    foreach($Computer in $PendingComputers)
    {
        If(!(Test-Connection $Computer -Count 1 -ErrorAction SilentlyContinue)) {$Unreachable += $Computer}
    }
    $PendingComputers = $PendingComputers | ?{$Unreachable -notcontains $_}

	$Report = Invoke-Command -ComputerName $PendingComputers -ScriptBlock{
		
            $Session = New-Object -ComObject "Microsoft.Update.Session"
            $Searcher = $Session.CreateUpdateSearcher()

            $historyCount = $Searcher.GetTotalHistoryCount()

            $Allhistory = $Searcher.QueryHistory(0, $historyCount) | Select-Object Title,  Date,@{name="Status";expression={switch($_.ResultCode){2{"Successful"};4{"Failed"}}}},

                @{name="Operation"; expression={switch($_.operation){

                    1 {"Installation"}; 2 {"Uninstallation"}; 3 {"Other"}        
            }}}
            $Allhistory = $Allhistory | ?{$_.Date -ge (Get-date).AddDays(-5)}
            $LogPath = "C:\Temp\Log\Windows-Updates"
            if(!(Test-Path $LogPath))
            {
                New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
            }
            if($Allhistory -ne $null)
            {
                $Allhistory | Export-Csv "C:\Temp\Log\Windows-Updates\$($Env:COMPUTERNAME)-$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation -Force
            }
            else
            {
                $Allhistory = New-Object -TypeName PSObject -Property @{
                    Operation= ''
                    Title = ''
                    Status = ''
                    Date = (Get-Date)
                }
            }
            
            $Criteria = "IsInstalled=0 and Type='Software' or (DeploymentAction='Uninstallation' and IsInstalled=1)"
            $Searcher = New-Object -ComObject Microsoft.Update.Searcher
            $SearchResult = $Searcher.Search($Criteria).Updates
            $LastReboot = (Get-WinEvent -FilterHashtable @{logname=’System’; id=1074} -MaxEvents 1).TimeCreated
            $Obj = New-Object -TypeName PSObject -Property @{
			Pending = $SearchResult.Count
			Installed = $Allhistory.Count
            Rebooted = if($LastReboot -gt $Allhistory[0].Date){"Yes"}Else{"No"}
            LastRebootTime = $LastReboot
		}
		return $Obj
	}
    $FullReport += $Report
    $FullReport = $FullReport |Sort-Object Installed, PSComputerName | Select PSComputerName,Pending,Installed,Rebooted,LastRebootTime -Unique
    [System.Array]$PendingComputers += $Unreachable

    clear
    Write-Host "******************************************************************" -ForegroundColor Cyan
    Write-Host "******************** WINDOWS UPDATES REPORT **********************" -ForegroundColor Cyan
    Write-Host "******************************************************************" -ForegroundColor Cyan
    $FullReport | ft -AutoSize #| Out-GridView
    Write-Host "******************************************************************" -ForegroundColor Cyan
    if($Unreachable -ne $null)
    {
        Write-Host "Unreachable systems: $unreachable" -ForegroundColor Yellow
    }
    sleep 3

} while ($PendingComputers.Count -gt 0)
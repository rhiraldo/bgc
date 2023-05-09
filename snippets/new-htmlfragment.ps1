Function New-HTMLFragment 
{  
    Param([cmdletbinding()]
            [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [string]$HeadersFont = "Gisha",
            [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [string]$HeadersFontColor = "Maroon",
            [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [string]$HeadersBackgroundColor = "White",
            [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [string]$TableFont = "Gisha",
            [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [string]$TableFontColor = "Black",
            [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [string]$TableBackgroundColor = "White",
             [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [string]$TableHeaderFontColor = "White",
            [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [string]$TableHeaderBackgroundColor = "Maroon",
            [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [array]$subheaderdata,
            [parameter(Mandatory=$false,ValueFromPipeline=$false)][ValidateSet('List','Table','Text')]
                  [String]$ContentAs = "Table",
            [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [string]$headingimage = ".\Images\bgc-logo.png",
            [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [string]$headingtext = "$(hostname) @ $(get-date)",
            [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [switch]$heading,
            [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [switch]$noheadingimage,
            [parameter(Mandatory=$false,ValueFromPipeline=$false)]
                  [switch]$noheadingtext,
            [parameter(Mandatory=$false,ValueFromPipeline=$true)]
                  $data

    )
$style = ''
$date = get-date -f "yyyyMMddhhmmss"
$headercss = @"
<style>
table.header$date {
  font-family: $HeadersFont;
  border-collapse: collapse;
  width: 100%;
}
table.header$date th {
  border: 0px solid #ffffff;
  padding: 8px;
  text-align: center;
  background-color: $HeadersBackgroundColor;
  color: $HeadersFontColor;
  font-weight:900;
  font-size:40px;
}
table.header$date td {
  padding-top: 12px;
  padding-bottom: 12px;
  background-color: $HeadersBackgroundColor;
  color: $HeadersFontColor;
  font-weight:900;
  font-size:40px;
}
</style>`n
"@
$datacss = @"
<style>
table.data$date {
  font-family: $tablefont;
  border-collapse: collapse;
  width: 100%;
}
table.data$date td,
table.data$date th {
  border: 2px solid black;
  padding: 8px;
  text-align: center;
}
table.data$date td {

  background-color: $TableBackgroundColor;
  color: $TableFontColor;
}
table.data$date th {
  background: $TableHeaderBackgroundColor;
  color: $TableHeaderFontColor;
}
</style>`n
"@
$subheadercss = @"
<style>
h1,h2,h3,h4,h5,h6 {
font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
line-height:1.1;
margin-bottom:5px;
color:#000;
text-align: left;
}
h1 {
font-weight:500;
font-size:27px;
}
h2 {
font-weight:500;
font-size:23px;
}
</style>`n
"@
$header = ''
$subheader = ''
$tabledata= ''
if ( $heading )
{
    $style += $headercss
    if(Test-Path -Path $headingimage) { $imagedata = [convert]::ToBase64String((get-content $headingimage -encoding byte)) }
    else { $noheadingimage = $true }
    $header += @"

<table class="header$date">
  <thead>
    <tr>`n
"@
    if ( !$noheadingimage ) 
    { 
        $header += "<!--Imagefile`%<th><img alt=`"bgc`" src=`"$headingimage`"></th>`%ImageFile-->`n"
        $header += "<!--HeaderImage`%<th><img alt=`"bgc`" src=`"$($headingimage.split('\')[-1])`"></th>`%HeaderImage-->`n"
        $header += "<th><img src=`"data:image/png;base64,$imagedata`" alt=`"bgc`"/></th>`n" 
    }
    if ( !$noheadingtext ) { $header += "<th>$headingtext</th>`n" }
    $header += @"
    </tr>
  </thead>
</table>`n
"@
}
if ($subheaderdata)
{            
    $style += $subheadercss
    foreach ($item in $subheaderdata)
    {
        $Num = ([array]::IndexOf($subheaderdata,$item)) + 1
        if ($num -gt 1)
        {
            $subheader += "<h2>$item</h2>`n"
        }
        else
        {
            $subheader += "<h1>$item</h1>`n"
        }
    }
}
if ($contentas -like 'Text') { $HTMLFragment = "<BR>`n" + $($data -join "<BR>`n") + "<BR>`n" }
else
{
    $style += $datacss
    $HTMLFragment = $data | ConvertTo-Html -as $contentas -Fragment 
}

$tabledata += $HTMLFragment -replace '<table>',"<table class=`"data$date`">"
$tabledata += "<BR>"

$htmldata += $style
$htmldata += $header
$htmldata += $subheader
$htmldata += $tabledata
$htmldata
}
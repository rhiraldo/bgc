# Load the System.Windows.Forms.DataVisualization assembly
Add-Type -TypeDefinition @"
    using System;
    using System.Windows.Forms;
    using System.Windows.Forms.DataVisualization.Charting;
"@

# Sample data from your API response
$data = @(
    @{ month = "Aug-15-2023"; value = 80.74 },
    @{ month = "Sep-01-2023"; value = 81.25 },
    @{ month = "Sep-15-2023"; value = 78.41 }
)

# Create a form
$form = New-Object Windows.Forms.Form
$form.Text = "API Data Chart"
$form.Width = 800
$form.Height = 600

# Create a chart
$chart = New-Object Windows.Forms.DataVisualization.Charting.Chart
$chart.Width = 750
$chart.Height = 500
$chartArea = New-Object Windows.Forms.DataVisualization.Charting.ChartArea
$chart.ChartAreas.Add($chartArea)

# Create a series
$series = New-Object Windows.Forms.DataVisualization.Charting.Series
$series.Name = "Data"

# Add data points to the series
$data | ForEach-Object {
    $point = New-Object DataPoint
    $point.AxisLabel = $_.month
    $point.YValues = @([double]$_.value)
    $series.Points.Add($point)
}

$chart.Series.Add($series)

# Create X and Y axis labels
$chartArea.AxisX.Title = "Month"
$chartArea.AxisY.Title = "Value"

# Add the chart to the form
$form.Controls.Add($chart)

# Show the form
$form.ShowDialog()

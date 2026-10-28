#Identify Sentinel Excel Files for Report
write-host "Identify Sentinel Files for report"
$SourceFolder = "C:\Users\Administrator.ADATUM\Desktop\Github"
$ImportFiles = @(
    "Inventory.csv"
    "DomainResults.csv"
    "Eventlogs.csv"
    "FirewallResults.csv"
    "RecoveryResults.csv"
)

#Import CSV Files
Write-Host "Import Sentinel Reports"

$Headline = @()
$Overview = foreach ($FileName in $ImportFiles) {
    $Path = Join-Path $SourceFolder $FileName
    $Data = @()
    $Status = "Missing"
    if (Test-Path $Path) {
        try {
            $Data = @(Import-csv $Path -ErrorAction Stop)
            $Status = "Availaible"
        }
        catch {
            $Status = "Read Error"   
        }
    }
    $HeadLine += "<h2>$FileName</h2>"
    if ($Status -eq "Availaible") {
        $HeadLine += ($Data | ConvertTo-Html -Fragment)
    }
    else {
        $HeadLine += "<p>Status: $Status</p>"
    }
    [PSCustomObject]@{
        File    = $FileName
        Records = $Data.Count
        Status  = $Status
    }
}

$Overview | Format-Table -AutoSize
#Generate HTML Report
Write-Host "Generate HTML Report"
$Body = @(
    "<h1>Operation Sentinel - Infrastructure Report</h1>"
    "<p>Generated: $(Get-Date)</p>"
    "<h2>Report Summary</h2>"
    ($Overview | ConvertTo-Html -Fragment)
) + $Headline
#Save HTML Report
$ReportPath = Join-Path $SourceFolder "SentinelReport.html"

ConvertTo-Html -Title "Operation Sentinel" -Body $Body |
Out-File $ReportPath 
Write-Host "Report saved to: $ReportPath"
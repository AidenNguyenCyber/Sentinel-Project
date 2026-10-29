# Identify Windows servers in Active Directory
$Servers = Get-ADComputer -Filter * -Properties OperatingSystem |
    Where-Object { $_.OperatingSystem -like "*Server*" }

if (-not $Servers) {
    Write-Warning "No Windows servers found in Active Directory."
    return
}

$SourceFolder = Split-Path -Path $PSScriptRoot -Parent
$EventLogPath = Join-Path $SourceFolder "EventLogs.csv"

# Get Critical (1), Error (2), and Warning (3) System events from the last 7 days
Write-Host "Retrieve recent Windows System events"
$Events = @(Invoke-Command -ComputerName $Servers.Name -ErrorAction SilentlyContinue -ScriptBlock {
    $Filter = @{
        LogName   = "System"
        Level     = @(1, 2, 3)
        StartTime = (Get-Date).AddDays(-7)
    }
    Get-WinEvent -FilterHashtable $Filter -MaxEvents 100 -ErrorAction SilentlyContinue
})

if (-not $Events) {
    Write-Host "No matching System events found."
    return
}

# Keep the information needed for review and reporting
$Results = $Events | Select-Object PSComputerName, TimeCreated,
    @{Name = "Severity"; Expression = { $_.LevelDisplayName }},
    Id, ProviderName, Message

$Results | Format-Table -AutoSize -Wrap

# Review service events and recurring issues
Write-Host "Check service related events"
$ServiceFailures = $Events | Where-Object { $_.ProviderName -like "*Service*" }
$ServiceFailures | Format-Table -AutoSize

$RecurringIssues = $ServiceFailures |
    Group-Object PSComputerName, ProviderName, Id |
    Where-Object { $_.Count -gt 1 } |
    Sort-Object Count -Descending
$RecurringIssues | Format-Table -AutoSize

# Save results
Write-Host "Export Windows events"
$Results | Export-Csv -Path $EventLogPath -NoTypeInformation

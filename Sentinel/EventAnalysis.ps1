#Investigate Windows errors and warnings.
#Identify Server in Network
$Servers = Get-ADComputer -Filter * -Properties OperatingSystem |
Where-Object OperatingSystem -Like "*Server*"

if (-not $Servers) {
    Write-Host "No servers found in Active Directory matching '*Server*'." -ForegroundColor Yellow
    return
}

#Retrieve recent Windows Event Logs.
# Define the log query parameters using a high-performance FilterHashtable
Write-Host "Retrieve recent Windows Event Logs"
# Level 1 = Critical, Level 2 = Error, Level 3 = Warning
$Events = invoke-Command -ComputerName $servers.name -ErrorAction SilentlyContinue -ScriptBlock {
    $Filter = @{
        LogName   = 'System'
        Level     = @(1, 2, 3)
        StartTime = (Get-Date).AddDays(-7) # Adjust timeframe as needed
    }
    Get-WinEvent -FilterHashtable $Filter -MaxEvents 100 -ErrorAction SilentlyContinue
}
$Events | Format-Table -AutoSize


#Filter errors and warnings
Write-Host "Filter errors and warnings"
$Errors = $Events | Where-Object {
    $_.LevelDisplayName -ne "Information"
}

$Errors | Format-Table -AutoSize
if ($Errors) {
    # Shape the results once so they can be displayed and exported
    $Results = $Errors | Select-Object TimeCreated, 
    @{N = 'Severity'; E = { $_.LevelDisplayName } }, 
    Id, 
    ProviderName, 
    Message

    # Display the results cleanly in the console
    # -Wrap shows the full Message text instead of truncating it
    $Results | Format-Table -AutoSize -Wrap
    
#Identify Service Failure
Write-Host "Identify Service Failure"

$ServiceFailures = $Errors | Where-Object {
    $_.ProviderName -like "*Service*"
}
$ServiceFailures | Format-Table -AutoSize

# Identify actual service failures
Write-Host "Identify Service Failures"

$RecurringIssues = $ServiceFailures |
    Group-Object PSComputerName, ProviderName, Id |
    Where-Object { $_.Count -gt 1 } |
    Sort-Object Count -Descending

$RecurringIssues | Format-Table -AutoSize

#Export Event
Write-Host "Export Event"
$Errors | Export-Csv -Path "C:\Users\Administrator.ADATUM\Desktop\Github\EventLogs.csv" -NoTypeInformation

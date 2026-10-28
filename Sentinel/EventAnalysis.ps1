#Investigate Windows errors and warnings.
#Identify Server in Network
$Servers = Get-ADComputer -Filter * -Properties OperatingSystem |
Where-Object OperatingSystem -Like "*Server*"

#Retrieve recent Windows Event Logs.
Write-Host "Retrieve recent Windows Event Logs"
$Events = invoke-Command -ComputerName $servers.name -ScriptBlock {
    Get-WinEvent -LogName System -MaxEvents 100
}
$Events | Format-Table -AutoSize

#Filter errors and warnings
Write-Host "Filter errors and warnings"
$Errors = $Events | Where-Object {
    $_.LevelDisplayName -ne "Information"
}
$Errors | Format-Table -AutoSize

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

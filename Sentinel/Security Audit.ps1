#Identify servers from Inventory
Write-Host "Import CSV from Inventory"
$Servers = import-csv -Path "C:\Users\Administrator.ADATUM\Desktop\Github\Inventory.csv" |
Where-Object { $_.OperatingSystem -like "*Server*" }

$Servers | Format-Table -AutoSize

#Windows Firewall
Write-host "Check Windows Firewall"
$Firewall = invoke-command -ComputerName $Servers.Hostname -Scriptblock {
    Get-netfirewallprofile  | select-object Name, Enabled
}
$Firewall | Format-Table -AutoSize

#Check AD security policy
Write-host "Check AD security policy"
$ADPolicies = Get-ADDefaultDomainPasswordPolicy -Server "LON-DC1"
$ADPolicies |
Select-Object minpasswordlength, complexityenabled, lockoutthreshold |
Format-Table -AutoSize

#Identify locked AD accounts
Write-host "Identify locked AD accounts"
$lockedAccounts = Search-ADAccount -LockedOut -UsersOnly -Server "LON-DC1"
$lockedAccounts | Format-Table -AutoSize

# Evaluate Security Compliance
Write-Host "Evaluate Security Compliance"

$FirewallResults = foreach ($Profilez in $Firewall) {
    [PSCustomObject]@{
        Server  = $Profilez.PSComputerName
        Profile = $Profilez.Name
        Status  = if ($Profilez.Enabled) { "Pass" } else { "Fail" }
    }
}
$FirewallResults | Format-Table -AutoSize
Write-Host "Domain Result"
$DomainResults = [PSCustomObject]@{
    PasswordLength = if ($ADPolicies.MinPasswordLength -ge 12) { "Pass" } else { "Fail" }
    Complexity     = if ($ADPolicies.ComplexityEnabled) { "Pass" } else { "Fail" }
    Lockout        = if ($ADPolicies.LockoutThreshold -ge 3) { "Pass" } else { "Fail" }
    LockedAccounts = @($LockedAccounts).Count
}
$DomainResults | Format-Table -AutoSize

#Export Security
Write-Host "Export Security"
$FirewallResults | Export-Csv -Path "C:\Users\Administrator.ADATUM\Desktop\Github\FirewallResults.csv" -NoTypeInformation
$DomainResults | Export-Csv -Path "C:\Users\Administrator.ADATUM\Desktop\Github\DomainResults.csv" -NoTypeInformation
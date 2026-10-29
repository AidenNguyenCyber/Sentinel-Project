$SourceFolder = Split-Path -Path $PSScriptRoot -Parent
$InventoryPath = Join-Path $SourceFolder "Inventory.csv"

# Identify servers from Inventory
Write-Host "Import CSV from Inventory"
$Servers = Import-Csv -Path $InventoryPath -ErrorAction Stop |
Where-Object { $_.OperatingSystem -like "*Server*" }

if (-not $Servers) {
    Write-Warning "No Windows servers found in Inventory.csv."
    return
}
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

$FirewallResults = foreach ($Profile in $Firewall) {
    [PSCustomObject]@{
        Server  = $Profile.PSComputerName
        Profile = $Profile.Name
        Status  = if ($Profile.Enabled) { "Pass" } else { "Fail" }
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
$FirewallResults | Export-Csv -Path (Join-Path $SourceFolder "FirewallResults.csv") -NoTypeInformation
$DomainResults | Export-Csv -Path (Join-Path $SourceFolder "DomainResults.csv") -NoTypeInformation
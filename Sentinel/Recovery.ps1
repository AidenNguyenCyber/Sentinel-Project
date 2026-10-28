#Identify Locked AD Accounts
Write-Host "Identify Locked AD Accounts"
$LockedAccounts = Search-ADAccount -LockedOut -UsersOnly -Server "LON-DC1"
$LockedAccounts | Format-Table -AutoSize
#Check Spooler on all inventoried computers
Write-Host "Check Spooler Across Computers"
$Computers = Import-Csv -Path "C:\Users\Administrator.ADATUM\Desktop\Github\Inventory.csv"
$ServiceName = "Spooler"
$Services = foreach ($Computer in $Computers) {
    if ($Computer.Hostname -eq $env:COMPUTERNAME) {
        Get-Service -Name $ServiceName |
        Select-Object @{Name = "PSComputerName"; Expression = { $env:COMPUTERNAME } }, Name, Status, StartType
    }
    else {
        Invoke-Command -ComputerName $Computer.Hostname -ScriptBlock {
            Get-Service -Name $using:ServiceName
        } | Select-Object PSComputerName, Name, Status, StartType
    }
}
$Services | Format-Table -AutoSize
#Identify computers where Spooler is stopped
Write-Host "Identify Stopped Spooler Services"
$StoppedServices = $Services | Where-Object {
    $_.Status -eq "Stopped"
}
$StoppedServices | Format-Table -AutoSize
#Select Stopped service for recovery
Write-host "Select Stopped service for recovery"
$TargetComputer = Read-Host "Enter computer"
#if targetService != null return true
$targetService = $StoppedServices | Where-object {
    $_.PSComputerName -eq $TargetComputer -and
    $_.StartType -ne "Disabled"
}

#Approval default is N
$Approval = "N"

if ($targetService) {
    $Approval = Read-Host "Start $ServiceName on ${TargetComputer}? (Y/N)"
}
else {
    Write-Host "No eligible stopped service found on $TargetComputer"
}
#Execute Approved service recovery
Write-Host "Execute Approved service recovery"
$RecoveryStatus = "Skipped"
if ($Approval -eq "Y" -and $targetService) {
    try {
        if ($TargetComputer -eq $env:TargetComputer) {
            Start-Service -Name $ServiceName -ErrorAction Stop
            $Result = Get-Service -Name $ServiceName
        }
        else {
            $Result = Invoke-Command -ComputerName $TargetComputer -ErrorAction Stop -ScriptBlock {
                Start-Service -Name $Using:ServiceName -ErrorAction Stop
                Get-Service -Name $Using:ServiceName
            }
        }
        if ($Result.Status -eq "Running") {
            $RecoveryStatus = "Success"
        }
        else {
            $RecoveryStatus = "Failed"
        }
    }
    catch {
        $RecoveryStatus = "Failed"
        Write-Host "Recovery Error: $_"
    }
}
Write-Host "Recover Result: $RecoveryStatus"

#Record and Export Recovery Results
Write-Host "Record Recovery Results"

$RecoveryRecord = [PSCustomObject]@{
    Computer = $TargetComputer
    Service  = $ServiceName
    Approval = $Approval
    Status   = $RecoveryStatus
    Time     = Get-Date
}
$RecoveryRecord | Format-Table -AutoSize
$RecoveryRecord | Export-Csv -Path "C:\Users\Administrator.ADATUM\Desktop\Github\RecoveryResults.csv" -NoTypeInformation

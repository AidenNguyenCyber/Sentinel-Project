
#Identify Server in Network
Write-Host"Identify Server in Network"
$Servers = Get-ADComputer -Filter * -Properties OperatingSystem |
    Where-Object OperatingSystem -Like "*Server*"



#Check Server CPU utilization
Write-Host"Check Server CPU utilization"
$CPUUtilization = @()
foreach ($Server in $Servers) {
    $CPUUtilization += Get-Counter -Counter "\Processor(_Total)\% Processor Time" -ComputerName $Server.Name -SampleInterval 1 -MaxSamples 1
}

$CPUUtilization.CounterSamples | Select-Object path, CookedValue | Format-Table -AutoSize 


#Check disk space.
Write-Host"Check disk space."
$DiskSpace = @()
foreach ($Server in $Servers) {
    $DiskSpace += Get-CimInstance Win32_LogicalDisk -ComputerName $Server.Name -Filter "DriveType=3"
}
$DiskSpace | Select-Object SystemName, DeviceID, @{Name="Size(GB)";Expression={"{0:N2}" -f ($_.Size / 1GB)}}, @{Name="FreeSpace(GB)";Expression={"{0:N2}" -f ($_.FreeSpace / 1GB)}} | Format-Table -AutoSize



#Check important Windows services.
Write-Host"Check important Windows services."
$WindowsServices = @()
foreach ($Server in $Servers) {
    $WindowsServices += invoke-command -ComputerName $Server.Name -scriptblock {
        Get-Service -Name WinRM, LanmanServer, W32Time | Select-Object Name, Status      
    }
}
$WindowsServices |select-object PSComputerName, Name, Status| Format-Table -AutoSize

#Flag unhealthy conditions using defined thresholds with Automation.
#This function only trigger when condition meet.

Write-Host"Flag unhealthy conditions using 3 defined thresholds (CPU,DISK,WINRM) with Automation"
#Warning when High CPU Usage
foreach ($CPU in $CPUUtilization.CounterSamples){
    if ($CPU.CookedValue -ge 80) {
        Write-Host "Warning!! High Usage on $($CPU.path)"
    }
}
#Warning Low Disk Space
foreach ($Disk in $Diskspace){
    if (($Disk.FreeSpace / $Disk.size) -lt 0.10){
        Write-Host "Warning!! Disk Space is less than 10% $($Disk.SystemName)"
    }
}
#Warning When WinRM stop
foreach ($service in $Windowservices){
    if ($service.name -eq "WinRM" -and $service.starus -ne "Running") {
        Write-Host "Warning!! WinRM stopped on $($service.name)"
    }
}



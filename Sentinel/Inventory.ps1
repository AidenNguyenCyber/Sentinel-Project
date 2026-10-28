#Identify computer & OS in network
Write-Host "Identify computer & OS in network"
$Computers = get-adcomputer -filter * -Properties OperatingSystem |
    select-object Name, OperatingSystem |
    sort-object Name

$Computers | Format-Table -AutoSize


#Identify if computer is online
Write-Host "Identify if computer is online"
$OnlineComputers = @()
foreach ($Computer in $Computers) {
    if (Test-Connection -ComputerName $Computer.Name -Count 1 -Quiet) {        
        $OnlineComputers += write-host "$($Computer.Name) is online."
    }
    else {
        $OnlineComputers += write-host "$($Computer.Name) is offline."}
}
$OnlineComputers | Format-Table -AutoSize



#Collect OS, hostname, IP address, and system information
Write-Host "Collect OS, hostname, IP address, and system information"
$Inventory = @()
foreach ($Computer in $Computers) {
    if($Computer.name -eq $env:COMPUTERNAME){
    $ComputerInfo = Get-CimInstance Win32_ComputerSystem 
    $OSInfo = Get-CimInstance Win32_OperatingSystem 
    $IPInfo = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" 
    }
    else {
    $ComputerInfo = Get-CimInstance Win32_ComputerSystem -ComputerName $Computer.Name
    $OSInfo = Get-CimInstance Win32_OperatingSystem -ComputerName $Computer.Name
    $IPInfo = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" -ComputerName $Computer.Name
    }
    $Inventory += [PSCustomObject]@{
        Hostname = $Computer.Name
        OperatingSystem = $OSInfo.Caption
        IPAddress = ($IPInfo | Select-Object -ExpandProperty IPAddress)[0]
        Manufacturer = $ComputerInfo.Manufacturer
        Model = $ComputerInfo.Model
        TotalPhysicalMemoryGB = [math]::Round($ComputerInfo.TotalPhysicalMemory / 1GB, 2)
    }
}
$Inventory | Format-Table -AutoSize


#Export inventory to CSV file
Write-Host "Export inventory to CSV file"
$Inventory | Export-Csv -Path "C:\Users\Administrator.ADATUM\Desktop\Github\Inventory.csv" -NoTypeInformation


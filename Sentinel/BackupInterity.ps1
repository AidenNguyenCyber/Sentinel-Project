# Identify CSV files for backup
write-host "Identify Sentinel Files for Backup"

$SourceFolder = Split-Path -Path $PSScriptRoot -Parent

$ImportFiles = @(
    "Inventory.csv"
    "DomainResults.csv"
    "EventLogs.csv"
    "FirewallResults.csv"
    "RecoveryResults.csv"
)
$Files = foreach ($FileName in $ImportFiles) {
    $Path = Join-Path $SourceFolder $FileName

    if (Test-Path $Path) {
        Get-Item $Path
    }
    else {
        Write-Warning "Missing file: $FileName"
    }
}
$Files | Format-Table -AutoSize
#Backup Folder
Write-host "Create Backup Folder"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
$BackupFolder = Join-Path $SourceFolder "SentinelBackups"
$BackupFolder = Join-Path $BackupFolder $Timestamp
New-Item -Path $BackupFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null

#Backup and Verify Files
#Set Default, Avoid Null
Write-Host "Back Up and Verify Files"
$BackupResults = foreach ($FileName in $ImportFiles) {
    $File = $Files | Where-Object Name -eq $FileName
    $Status = "Missing"
    $Note = "Source file not found"
    $OriginalHash = ""
    $BackupHash = ""
    $Destination = ""

    if ($File) {
        $Destination = Join-Path $BackupFolder $FileName
        try {
            $OriginalHash = (Get-FileHash $File.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
            Copy-Item $File.FullName $Destination -ErrorAction Stop
            $BackupHash = (Get-FileHash $Destination -Algorithm SHA256 -ErrorAction Stop).Hash

            $Status = if ($OriginalHash -eq $BackupHash) { "Verified" } else { "Mismatch" }
            $Note = ""
        }
        catch {
            $Status = "Error"
            $OriginalHash = ""
            $BackupHash = ""
            $Note = $_.Exception.Message
        }
    }
    [PSCustomObject]@{
        File         = $FileName
        Status       = $Status
        OriginalHash = $OriginalHash
        BackupHash   = $BackupHash
        BackupPath   = $Destination
        Note         = $Note
    }
}

#Export
$BackupResults | Export-csv (Join-Path $SourceFolder "BackupAudit.csv") -NoTypeInformation
$BackupResults | Format-table -AutoSize
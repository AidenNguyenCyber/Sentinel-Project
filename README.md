# Operation Sentinel

**Windows Server & Active Directory administration | PowerShell | MSSA lab**

<p align="center"><img src="assets/operation-sentinel-husky.webp" alt="Operation Sentinel — husky mascot" width="100%"></p>

During Microsoft Software & Systems Academy (MSSA), I built Operation Sentinel to practice Windows administration with PowerShell. The project has seven scripts covering computer inventory, server health, Windows events, security checks, service recovery, backup verification, and HTML reporting.

**Lab environment:** I used the Adatum Active Directory domain with Windows Server 2019 and Windows 10 in the MSSA lab.

## Project overview

I wanted a way to check several Windows computers without repeating the same steps on each one. With these scripts, I can find computers in Active Directory, check server resources, review recent Windows events, and look for security settings that need attention.

I also added a service recovery exercise that asks for approval before starting a stopped service, along with backup checks and an HTML report. I ran the scripts individually and saved their results for review.

## Workflow

![Operation Sentinel workflow](assets/operation-sentinel-workflow.svg)

### Scripts

All seven scripts are in the [Sentinel folder](Sentinel/).

| Step | Script | What it does |
| --- | --- | --- |
| 01 | [Inventory.ps1](Sentinel/Inventory.ps1) | Finds computers in Active Directory, collects system details with CIM, and saves [Inventory.csv](Inventory.csv). |
| 02 | [Health Check.ps1](Sentinel/Health%20Check.ps1) | Checks CPU usage, disk space, and key services. Shows warnings in the console instead of saving a CSV. |
| 03 | [EventAnalysis.ps1](Sentinel/EventAnalysis.ps1) | Reviews recent Windows System events, filters out informational entries, checks service events, and saves [EventLogs.csv](EventLogs.csv). |
| 04 | [Security Audit.ps1](Sentinel/Security%20Audit.ps1) | Checks Windows Firewall profiles, domain password settings, and locked accounts. Saves [FirewallResults.csv](FirewallResults.csv) and [DomainResults.csv](DomainResults.csv). |
| 05 | [Recovery.ps1](Sentinel/Recovery.ps1) | Finds stopped Spooler services, asks for approval before starting one, and saves [RecoveryResults.csv](RecoveryResults.csv). |
| 06 | [BackupInterity.ps1](Sentinel/BackupInterity.ps1) | Copies five CSV reports to a dated backup folder, compares SHA-256 hashes, and saves [BackupAudit.csv](BackupAudit.csv). |
| 07 | [Report.ps1](Sentinel/Report.ps1) | Combines five CSV reports into [SentinelReport.html](SentinelReport.html), with summary counts and tables. |

### How I used PowerShell

I used Active Directory cmdlets to find computers, CIM to collect system information, and PowerShell remoting to query servers. I also worked with Windows event logs, custom objects, CSV reports, and SHA-256 hashes.

To review recent Windows events on the servers, I used PowerShell remoting:

```powershell
$Events = Invoke-Command -ComputerName $Servers.Name -ScriptBlock {
    Get-WinEvent -LogName System -MaxEvents 100
}
```

To verify the backups, I compared the SHA-256 hashes of each original file and its copy:

```powershell
$OriginalHash = (Get-FileHash $File.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
Copy-Item $File.FullName $Destination -ErrorAction Stop
$BackupHash = (Get-FileHash $Destination -Algorithm SHA256 -ErrorAction Stop).Hash
$Status = if ($OriginalHash -eq $BackupHash) { "Verified" } else { "Mismatch" }
```

## Lab results

Here are the results I saved from the Adatum lab:

| Check | Result |
| --- | --- |
| [Infrastructure inventory](Inventory.csv) | Found **3 computers**: LON-CL1, LON-DC1, and LON-SVR1. |
| [Windows event review](EventLogs.csv) | Saved **26 Windows event records** for review. |
| [Firewall checks](FirewallResults.csv) | Recorded **6 Pass** results across the Domain, Private, and Public firewall profiles on two servers. |
| [Domain policy](DomainResults.csv) | Password length: **Fail**. Complexity: **Pass**. Lockout threshold: **Fail** against my lab checks. **0 locked accounts**. |
| [Controlled recovery](RecoveryResults.csv) | I entered **N** at the approval prompt, so the Spooler restart was **Skipped**. |
| [Backup integrity](BackupAudit.csv) | Verified **5 backup files** using matching SHA-256 hashes. The copies are in the [backup folder](SentinelBackups/20261028_144215_202/). |
| [HTML report](SentinelReport.html) | Combined **5 CSV reports** into an HTML report with a summary and detailed tables. |

The health check shows its results in the console. The HTML report uses the five CSV files from inventory, domain settings, events, firewall checks, and recovery; it doesn't include the backup audit.

Together, these scripts gave me practice collecting information from Windows servers, checking security settings, reviewing events, and turning results into reports. The saved recovery result shows the approval check working, not a completed service restart.

## Exploring the scripts

- **Start here:** Open the [Sentinel folder](Sentinel/) to see all seven scripts.
- **Inventory:** See how I used CIM queries and `[PSCustomObject]` in [Inventory.ps1](Sentinel/Inventory.ps1).
- **Health checks:** Review the CPU, disk, and WinRM checks in [Health Check.ps1](Sentinel/Health%20Check.ps1).
- **Security:** See the password and firewall checks in [Security Audit.ps1](Sentinel/Security%20Audit.ps1).
- **Recovery:** Look at the approval prompt and service verification in [Recovery.ps1](Sentinel/Recovery.ps1).
- **Reporting:** Review the input file lists in [BackupInterity.ps1](Sentinel/BackupInterity.ps1) and [Report.ps1](Sentinel/Report.ps1).

**Running the scripts:** They use the Adatum lab domain, Active Directory and remote management access, and an output folder on the lab administrator's desktop. Run them in a Windows lab, since the recovery script can start a service after approval.

The repository also includes the saved CSV files, backups, [HTML report](SentinelReport.html), and [project document](Sentinel%20project.docx).

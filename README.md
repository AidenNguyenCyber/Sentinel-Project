# Operation Sentinel

**Windows Server & Active Directory Administration | PowerShell | MSSA Lab**

<p align="center"><img src="assets/operation-sentinel-husky.webp" alt="Operation Sentinel — husky mascot" width="100%"></p>

Operation Sentinel is a PowerShell project I built during Microsoft Software & Systems Academy (MSSA). I designed seven scripts to help with common Windows administration tasks, including computer inventory, server health checks, Windows event analysis, security auditing, service recovery, backup verification, and HTML reporting.

**Lab environment:** Adatum Active Directory domain, Windows Server 2019, and Windows 10 in the MSSA Windows Server lab.

## Scenario & Purpose

An IT administrator supporting multiple Windows computers needs to know what is happening across the environment. Which computers are in the domain? Are server resources and important services healthy? Have any errors or warnings appeared in the Windows event logs? Are firewall settings and domain security policies configured correctly? If a service stops, what needs to happen before taking action?

Checking each computer manually takes time, especially when the same tasks need to be repeated. It also makes it harder to keep the results organized for troubleshooting.

I built Operation Sentinel to handle these checks with PowerShell. The scripts collect information from domain computers, highlight potential issues, and save results that I can review later. I also added an approval prompt for service recovery and a backup script that checks whether copied files match the originals.

My goal was to make routine checks more consistent, reduce repetitive manual steps, and keep a useful record of the results. The seven scripts run individually, and their saved reports connect the different parts of the project.

## Workflow

![Operation Sentinel technical workflow](assets/operation-sentinel-workflow.svg)

### Source Scripts

All seven scripts are in the [Sentinel folder](Sentinel/).

| Step | Script | Purpose and Output |
| --- | --- | --- |
| 01 | [Inventory.ps1](Sentinel/Inventory.ps1) | Finds computers in Active Directory, checks connectivity, collects system information through CIM, and exports [Inventory.csv](Inventory.csv). |
| 02 | [Health Check.ps1](Sentinel/Health%20Check.ps1) | Reviews server CPU usage, disk space, and important Windows services. Shows results and threshold warnings in the PowerShell console. |
| 03 | [EventAnalysis.ps1](Sentinel/EventAnalysis.ps1) | Collects recent Windows System events, filters out informational entries, checks for service issues, and exports [EventLogs.csv](EventLogs.csv). |
| 04 | [Security Audit.ps1](Sentinel/Security%20Audit.ps1) | Checks Windows Firewall profiles, domain password settings, and locked accounts. Exports [FirewallResults.csv](FirewallResults.csv) and [DomainResults.csv](DomainResults.csv). |
| 05 | [Recovery.ps1](Sentinel/Recovery.ps1) | Checks for stopped Print Spooler services, requires approval before starting one, and records the outcome in [RecoveryResults.csv](RecoveryResults.csv). |
| 06 | [BackupInterity.ps1](Sentinel/BackupInterity.ps1) | Copies five CSV reports into a timestamped folder, compares SHA-256 hashes, and exports [BackupAudit.csv](BackupAudit.csv). |
| 07 | [Report.ps1](Sentinel/Report.ps1) | Combines five CSV reports into [SentinelReport.html](SentinelReport.html), with a summary of record counts and detailed tables. |

### PowerShell Approach

I used Active Directory cmdlets to find computers in the domain, CIM to collect system information, and PowerShell remoting to query servers. I also worked with Windows event logs, custom objects, CSV files, and SHA-256 checksums.

For Windows event analysis, I used `Invoke-Command` to retrieve recent System events from the servers remotely. This let me collect the events without signing in to each server separately.

```powershell
$Events = Invoke-Command -ComputerName $Servers.Name -ScriptBlock {
    Get-WinEvent -LogName System -MaxEvents 100
}
```

For backup verification, I used `Get-FileHash` to compare each original CSV file with its copy. Matching SHA-256 hashes confirm that the copied file has the same contents.

```powershell
$OriginalHash = (Get-FileHash $File.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
Copy-Item $File.FullName $Destination -ErrorAction Stop
$BackupHash = (Get-FileHash $Destination -Algorithm SHA256 -ErrorAction Stop).Hash
$Status = if ($OriginalHash -eq $BackupHash) { "Verified" } else { "Mismatch" }
```

## Results & Evidence

I ran the scripts in the Adatum lab and saved the results in this repository.

| Area | Lab Result |
| --- | --- |
| [Infrastructure inventory](Inventory.csv) | Identified **3 computers**: LON-CL1, LON-DC1, and LON-SVR1. |
| [Windows event analysis](EventLogs.csv) | Saved **26 Windows event records** for review and troubleshooting. |
| [Firewall checks](FirewallResults.csv) | Recorded **6 Pass** results across the Domain, Private, and Public firewall profiles on two servers. |
| [Domain security](DomainResults.csv) | Password complexity **Pass**; password length and lockout threshold **Fail** against the lab checks. **0 locked accounts**. |
| [Service recovery](RecoveryResults.csv) | I entered **N** at the approval prompt, so the Spooler restart was **Skipped**. |
| [Backup verification](BackupAudit.csv) | Verified **5 files** using matching SHA-256 hashes. The copies are available in the [backup folder](SentinelBackups/20261028_144215_202/). |
| [HTML reporting](SentinelReport.html) | Generated an HTML report with a summary and tables from **5 CSV files**: inventory, domain security, events, firewall checks, and recovery. |

The health check displays its results in PowerShell rather than exporting a CSV. The HTML report combines five CSV files, while backup verification has its own report in `BackupAudit.csv`.

### Project Impact

The project gave me a more organized way to inspect a Windows domain. Instead of checking every server separately, I could use PowerShell to collect system information, review events, identify settings that needed attention, and save the results for later troubleshooting.

The security audit identified two domain policy checks that failed the lab criteria. The backup script also verified that all five copied files matched their originals. Together with the HTML report, these results made it easier to see what had been checked and what needed follow-up.

I also added an approval step to the recovery script so a stopped service would not be started automatically. In the saved test, I chose not to approve the restart, and the script recorded that decision.

## Exploring the Scripts

The full code is available in the [Sentinel folder](Sentinel/). Each script handles a different task, so you can review the logic without having to run the whole project.

- **Inventory:** [Inventory.ps1](Sentinel/Inventory.ps1) uses Active Directory discovery, CIM queries, and custom PowerShell objects.
- **Server health:** [Health Check.ps1](Sentinel/Health%20Check.ps1) checks CPU usage, disk space, and important services, including WinRM.
- **Event analysis:** [EventAnalysis.ps1](Sentinel/EventAnalysis.ps1) collects and filters Windows System events.
- **Security:** [Security Audit.ps1](Sentinel/Security%20Audit.ps1) checks firewall settings, domain password policies, and locked accounts.
- **Recovery:** [Recovery.ps1](Sentinel/Recovery.ps1) includes the approval prompt and checks the service after an approved action.
- **Backup and reporting:** [BackupInterity.ps1](Sentinel/BackupInterity.ps1) verifies copied CSV files, while [Report.ps1](Sentinel/Report.ps1) builds the HTML report.

### Running the Project

These scripts use the Adatum lab environment, including Active Directory access, PowerShell remoting, and an output folder on the lab administrator's desktop. File paths and environment settings would need to be adjusted before running them elsewhere.

Some scripts query remote computers, and the recovery script can start a service after approval, so they should be run in an appropriate Windows lab.

The repository also includes saved CSV results, backup files, the [HTML report](SentinelReport.html), and the original [project document](Sentinel%20project.docx).

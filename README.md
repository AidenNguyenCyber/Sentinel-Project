# Operation Sentinel

**Windows Server & Active Directory Administration | PowerShell | MSSA Lab**

<p align="center"><img src="assets/operation-sentinel-husky.webp" alt="Operation Sentinel — husky mascot" width="100%"></p>

Operation Sentinel is a PowerShell project I built to organize routine Windows administration and security checks. Its seven scripts cover Active Directory inventory, server health, Windows event analysis, security settings, controlled service recovery, backup verification, and HTML reporting.

**Environment:** The project was developed in the Microsoft Software & Systems Academy (MSSA) Adatum lab using Windows Server 2019, Windows 10, and Active Directory.

## Scenario & Purpose

An IT administrator responsible for several Windows computers needs reliable answers to a few important questions. Which computers are in the domain? Are the servers and essential services healthy? What Windows errors or warnings need attention? Do firewall and domain security settings meet the expected standards? If a service stops, can the issue be reviewed before taking action?

Checking these areas manually on individual computers can be repetitive, and the findings may end up scattered across different consoles or files.

Operation Sentinel addresses that problem by using PowerShell to collect information, check configurations, and record results for later review. Each script handles a specific task and runs independently. The reports provide a consistent record of what was checked, while the recovery script requires approval before starting a stopped service.

## Workflow

![Operation Sentinel technical workflow](assets/operation-sentinel-workflow.svg)

### Source Scripts

The seven scripts are available in the [Sentinel folder](Sentinel/).

| Step | Script | Purpose and Output |
| --- | --- | --- |
| 01 | [Inventory.ps1](Sentinel/Inventory.ps1) | Finds computers in Active Directory, tests connectivity, collects system details through CIM, and exports [Inventory.csv](Inventory.csv). |
| 02 | [Health Check.ps1](Sentinel/Health%20Check.ps1) | Reviews server CPU usage, available disk space, and important Windows services. Displays results and warning messages in the PowerShell console. |
| 03 | [EventAnalysis.ps1](Sentinel/EventAnalysis.ps1) | Reviews Critical, Error, and Warning System events from the past seven days, examines service events, and exports [EventLogs.csv](EventLogs.csv). |
| 04 | [Security Audit.ps1](Sentinel/Security%20Audit.ps1) | Reviews Windows Firewall profiles, domain password settings, and locked accounts. Exports [FirewallResults.csv](FirewallResults.csv) and [DomainResults.csv](DomainResults.csv). |
| 05 | [Recovery.ps1](Sentinel/Recovery.ps1) | Finds stopped Print Spooler services, requests approval before starting a selected service, and records the result in [RecoveryResults.csv](RecoveryResults.csv). |
| 06 | [BackupInterity.ps1](Sentinel/BackupInterity.ps1) | Backs up five CSV reports to a timestamped folder, compares SHA-256 hashes, and exports [BackupAudit.csv](BackupAudit.csv). |
| 07 | [Report.ps1](Sentinel/Report.ps1) | Combines five CSV reports into [SentinelReport.html](SentinelReport.html), with a record summary and detailed tables. |

### PowerShell Approach

Active Directory cmdlets provide computer discovery and domain policy information. CIM collects system and disk details, while PowerShell remoting retrieves events and service information from remote servers. Custom objects, CSV exports, and HTML reporting keep the results organized.

For example, `Invoke-Command` retrieves recent System events from the servers found in Active Directory:

```powershell
$Events = Invoke-Command -ComputerName $Servers.Name -ScriptBlock {
    Get-WinEvent -LogName System -MaxEvents 100
}
```

Backup verification uses `Get-FileHash` to compare the original files with their copies. A matching SHA-256 hash confirms that the file contents are the same:

```powershell
$OriginalHash = (Get-FileHash $File.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
Copy-Item $File.FullName $Destination -ErrorAction Stop
$BackupHash = (Get-FileHash $Destination -Algorithm SHA256 -ErrorAction Stop).Hash
$Status = if ($OriginalHash -eq $BackupHash) { "Verified" } else { "Mismatch" }
```

## Results & Evidence

The repository includes the CSV files and HTML report generated in the Adatum lab.

| Area | Recorded Result |
| --- | --- |
| [Infrastructure inventory](Inventory.csv) | **3 computers** identified: LON-CL1, LON-DC1, and LON-SVR1. |
| [Windows event analysis](EventLogs.csv) | **26 System event records** saved for further review. |
| [Firewall checks](FirewallResults.csv) | **6 Pass** results across the Domain, Private, and Public profiles on two servers. |
| [Domain security](DomainResults.csv) | Password complexity **Pass**; password length and lockout threshold **Fail** against the script's lab criteria. **0 locked accounts**. |
| [Service recovery](RecoveryResults.csv) | Approval was **N**, so the Print Spooler restart was **Skipped**. |
| [Backup verification](BackupAudit.csv) | **5 files Verified** with matching SHA-256 hashes. The copies are available in the [backup folder](SentinelBackups/20261028_144215_202/). |
| [HTML reporting](SentinelReport.html) | Generated a report with a summary and detailed tables from **5 CSV files**: inventory, domain security, events, firewall checks, and recovery. |

The health check displays results in PowerShell rather than exporting a CSV. The backup audit is kept in `BackupAudit.csv` and is not included in the HTML report.

### Operational Impact

In this scenario, the administrator can use the scripts to establish which systems are being managed, review their condition, and identify events or security settings that need investigation. This replaces several disconnected manual checks with a repeatable process and a record of the findings.

The CSV files preserve the details for troubleshooting, while the HTML report brings inventory, security, event, and recovery information into one view. The backup check verifies that copies of those reports match the originals, and the recovery approval step prevents a service start without an explicit decision.

Together, these features support more consistent system reviews, clearer follow-up on problems, and better control over administrative actions.

## Exploring the Scripts

The [Sentinel folder](Sentinel/) contains the PowerShell source for each part of the workflow.

- **Inventory:** [Inventory.ps1](Sentinel/Inventory.ps1) uses Active Directory discovery, CIM, and custom PowerShell objects.
- **Server health:** [Health Check.ps1](Sentinel/Health%20Check.ps1) reviews CPU, disk space, and key service status.
- **Event analysis:** [EventAnalysis.ps1](Sentinel/EventAnalysis.ps1) retrieves Windows System events and examines recurring service events.
- **Security:** [Security Audit.ps1](Sentinel/Security%20Audit.ps1) evaluates firewall profiles, password settings, and locked accounts.
- **Recovery:** [Recovery.ps1](Sentinel/Recovery.ps1) includes service selection, approval, and status verification after an approved action.
- **Backup and reporting:** [BackupInterity.ps1](Sentinel/BackupInterity.ps1) verifies CSV backups, and [Report.ps1](Sentinel/Report.ps1) generates the HTML report.

### Running the Project

The scripts use the Adatum domain and require Active Directory and PowerShell remoting access. CSV files and the HTML report are read from or saved to the project root folder, one level above the Sentinel scripts. File paths adjust when the project is moved, though domain settings may need changes in another environment. The recovery script can start a service when approved, so it should be used in a suitable Windows lab.

The repository also contains the original outputs, backup files, generated [HTML report](SentinelReport.html), and [project document](Sentinel%20project.docx).

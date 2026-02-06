# Automated Sysmon Lifecycle Manager

🛡️ Project Overview

This repository contains a robust, version-aware PowerShell framework designed to automate the deployment, configuration, and lifecycle management of Microsoft Sysmon across enterprise Windows environments.
Unlike standard installers, this script implements a state-management logic to ensure version consistency, handle service-level conflicts, and perform deep-registry hygiene during the update process.






🚀 Key Features

Version-Aware Logic: Automatically detects currently installed Sysmon versions and compares them against a remote repository to determine if an update is required.

Service & Driver Management: Gracefully handles the stopping and uninstallation of Sysmon64 and SysmonDrv services to prevent file-lock errors.

Deep Registry Hygiene: Targets and cleans specific HKLM registry paths (CurrentControlSet/Services) to ensure a "clean-slate" installation, preventing common configuration corruption.
Automated Logging: Utilizes Tee-Object to provide real-time console feedback while maintaining an audit trail in $env:TEMP\SysmonUpdate.log.

Environment Virtualization: Creates and destroys a temporary execution environment to ensure no residue files are left on the host system post-deployment.



🛠️ Technical Stack

Language: PowerShell 5.1+
Targets: Windows 10/11, Windows Server 2016/2019/2022
Security Focus: EDR/SIEM telemetry optimization (Sysmon)






📖 Usage

Place your Sysmon64.exe and .xml config in a network share or local repository.
Update the $ExternalSysmonPath and $SysmonXmlFilePath variables.
Run the script with Administrative privileges.



📝 Author's Note

This tool was developed to solve the "manual update" bottleneck in high-compliance environments where consistent telemetry is critical for SIEM ingestion and threat hunting.

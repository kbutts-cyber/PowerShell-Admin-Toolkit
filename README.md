# PowerShell Admin Toolkit

A growing collection of PowerShell scripts I am building to get more hands-on with Windows troubleshooting, system administration, and automation.

I got the idea for this toolkit while troubleshooting a customer's PC at work. I realized that a lot of the information I normally check during troubleshooting could be collected or tested automatically instead of running a bunch of individual commands.

The goal of this project is to keep improving my PowerShell skills by building tools that could actually be useful in IT support and system administration scenarios.

## Current Tools

### 1. System Health Report

`SystemHealthReport.ps1` collects system information from a Windows PC and generates both terminal output and a timestamped HTML health report.

The goal is to quickly gather useful troubleshooting information in one place and make the troubleshooting process faster and easier.

#### System Checks

The script currently checks:

- Computer name
- Windows version
- Windows build number
- System uptime
- CPU model
- CPU usage
- Total RAM
- Available RAM
- RAM usage percentage
- Disk capacity
- Disk free space
- Disk usage percentage
- Physical SSD model
- SSD health status
- SSD operational status
- IPv4 address
- Default gateway
- DNS servers
- Print Spooler service status
- Windows Update service status
- DHCP Client service status
- DNS Client service status
- Recent Critical and Error events from the Windows System log

#### Health Status

The generated HTML report evaluates several system metrics and displays simple health indicators.

##### CPU, RAM, and Disk

- Healthy: Below 80%
- Warning: 80% to 89%
- Critical: 90% or higher

##### Storage

The script checks the physical disk's reported health and operational status.

If the physical disk reports a healthy state and an operational status of OK, the storage section is marked as Healthy.

##### Event Logs

The script checks the Windows System event log for recent Critical and Error events.

If recent Critical or Error events are found, the Event Log section is marked as `Review` so those events can be investigated further.

##### Overall System Status

The report also generates an overall system status based on the individual health checks.

Possible statuses include:

- Healthy
- Review
- Critical

#### HTML Report

Each time the script runs, it creates a timestamped HTML report.

Example:

`SystemHealthReport-PCNAME-2026-08-31_13-40-19.html`

The report contains organized sections for:

- System information
- Resource usage
- Storage health
- Network information
- Windows service status
- Recent Critical and Error events

Generated HTML reports are excluded from GitHub through `.gitignore` because they may contain information specific to the computer being tested.

#### Running the System Health Report

Open PowerShell in the project folder and run:

```powershell
.\SystemHealthReport.ps1
```

After the script finishes, PowerShell displays the collected information in the terminal and shows the location of the generated HTML report.

The report can then be opened in a web browser.

#### Parameters

##### OutputPath

Use `-OutputPath` to choose where the generated HTML report will be saved.

Example:

```powershell
.\SystemHealthReport.ps1 -OutputPath "C:\Reports"
```

If no output path is provided, the report is saved in the same folder as the script.

##### SkipEventLogs

Use `-SkipEventLogs` to generate the report without checking recent Critical or Error events from the Windows System log.

Example:

```powershell
.\SystemHealthReport.ps1 -SkipEventLogs
```

Both parameters can also be used together:

```powershell
.\SystemHealthReport.ps1 -OutputPath "C:\Reports" -SkipEventLogs
```

#### Built-In Help

The System Health Report includes PowerShell comment-based help so users can quickly see what the script does, what parameters are available, and how to run it.

To view the general help:

```powershell
Get-Help .\SystemHealthReport.ps1
```

To view usage examples:

```powershell
Get-Help .\SystemHealthReport.ps1 -Examples
```

---

### 2. Network Troubleshooter

`NetworkTroubleshooter.ps1` is a Windows network diagnostic tool designed to collect network configuration information, test different stages of connectivity, and provide a likely diagnosis based on the results.

Instead of only showing network information, the script follows a basic troubleshooting path to help identify where a connection may be failing.

#### Network Information

The script collects:

- Active physical network adapter
- Adapter status
- Adapter description
- Link speed
- IPv4 address
- Subnet prefix length
- Default gateway
- DHCP status
- Windows network profile
- Configured IPv4 DNS servers

#### Network Tests

The script currently checks:

- Whether an active physical network adapter can be found
- Whether an IPv4 address is assigned
- Whether an APIPA `169.254.x.x` address is present
- Whether a default gateway is configured
- Default gateway connectivity
- Internet connectivity using `1.1.1.1`
- DNS name resolution
- TCP connectivity to port 443

#### Troubleshooting Logic

The script checks connectivity in stages:

```text
Active Network Adapter
        |
        v
IPv4 Configuration
        |
        v
Default Gateway
        |
        v
Internet Connectivity
        |
        v
DNS Resolution
        |
        v
TCP Port 443
        |
        v
Likely Diagnosis
```

This makes it easier to determine where a network problem may be occurring instead of only receiving a PASS or FAIL result.

#### IP Configuration Checks

The script can detect several common configuration problems.

##### No IPv4 Address

If no IPv4 address is detected, the IP configuration check fails.

##### APIPA Address

If the computer has an address beginning with:

`169.254.x.x`

the script identifies it as an APIPA address.

This can indicate that the computer was unable to receive an IPv4 address from DHCP.

##### Missing Default Gateway

If the computer has an IPv4 address but no default gateway, the script reports the configuration as failed.

#### Connectivity Tests

##### Gateway Test

The script uses `Test-Connection` to determine whether the computer can reach its configured default gateway.

##### Internet Test

The script tests connectivity to:

`1.1.1.1`

Using an IP address allows the script to test internet connectivity without depending on DNS resolution.

##### DNS Resolution Test

The script uses `Resolve-DnsName` to determine whether the computer can successfully resolve a domain name.

##### TCP Port Test

The script uses `Test-NetConnection` to test TCP connectivity to port 443.

This provides an additional test beyond basic ping connectivity.

#### Overall Network Status

The results are combined into an overall network status.

Possible statuses include:

- HEALTHY
- REVIEW
- CRITICAL

Example healthy result:

```text
========================================
        TROUBLESHOOTING SUMMARY
========================================

Overall Network Status: HEALTHY

IP Configuration: PASS
Gateway: PASS
Internet: PASS
DNS Resolution: PASS
TCP Port 443: PASS

--- LIKELY DIAGNOSIS ---
Network connectivity appears healthy.
```

#### Likely Diagnosis

The script also provides a likely troubleshooting direction based on where the tests fail.

Examples include:

- No active physical network adapter detected
- No IPv4 address detected
- APIPA address detected
- Missing default gateway
- Unable to reach the default gateway
- Gateway reachable but internet connectivity unavailable
- Internet connectivity working but DNS resolution failing
- TCP port 443 connectivity failure
- Network connectivity appears healthy

#### Running the Network Troubleshooter

Open PowerShell in the project folder and run:

```powershell
.\NetworkTroubleshooter.ps1
```

The results are displayed directly in the PowerShell terminal.

---

## PowerShell Concepts Practiced

Building these tools has given me hands-on experience with:

- PowerShell variables
- PowerShell objects and properties
- PowerShell pipelines
- Conditional logic with `if`, `elseif`, and `else`
- Boolean values
- `$null` checks
- Wildcard comparisons with `-like`
- Filtering objects with `Where-Object`
- Selecting objects with `Select-Object`
- Sorting objects with `Sort-Object`
- Working with multiple returned objects
- Accessing object properties
- Creating and reusing stored values
- Working with Windows services
- Working with Windows event logs
- Working with Windows networking
- TCP connectivity testing
- DNS resolution testing
- IP configuration troubleshooting
- DHCP information
- Network adapter information
- Disk and storage health checks
- Usage percentage calculations
- Basic health thresholds
- Combining multiple checks into an overall status
- Creating timestamped files
- Generating HTML reports with PowerShell
- Script parameters
- PowerShell comment-based help

## PowerShell Cmdlets Used

Some of the PowerShell cmdlets used throughout the toolkit include:

- `Get-CimInstance`
- `Get-NetIPAddress`
- `Get-NetIPConfiguration`
- `Get-NetAdapter`
- `Get-NetRoute`
- `Get-NetIPInterface`
- `Get-NetConnectionProfile`
- `Get-DnsClientServerAddress`
- `Resolve-DnsName`
- `Test-Connection`
- `Test-NetConnection`
- `Get-Service`
- `Get-WinEvent`
- `Get-PhysicalDisk`
- `Where-Object`
- `Select-Object`
- `Sort-Object`
- `ForEach-Object`

## Current Limitations

These scripts are still being developed and improved.

Some areas I plan to improve include:

- Better error handling
- Support for more networking configurations
- Better handling of systems with multiple active adapters
- VPN and virtual adapter handling
- More reliable memory usage calculations
- Support for systems with multiple physical drives
- Improved CPU usage sampling
- Better service health interpretation
- More advanced event log analysis
- Additional script parameters
- Logging
- Network Troubleshooter built-in help
- Network Troubleshooter customizable test targets
- Additional diagnostic logic

## Planned Toolkit Scripts

The toolkit will continue growing as I learn more PowerShell and Windows administration.

Future scripts may include:

- Windows repair and integrity checks
- SFC and DISM utilities
- Service troubleshooting tools
- Active Directory administration scripts
- Microsoft Entra ID administration scripts
- Microsoft 365 administration scripts
- Microsoft Graph PowerShell automation
- General Windows support automation

## Why I Built This

The original idea came from troubleshooting a customer's PC at work.

During troubleshooting, I noticed that I was checking several different areas of the system individually, including hardware information, network settings, Windows services, disk health, and event logs.

I wanted to see if I could use PowerShell to collect that information in one place and make the troubleshooting process simpler and faster.

After completing the first version of the System Health Report, I started building additional tools around the same idea.

The Network Troubleshooter takes that a step further by testing different stages of network connectivity and using the results to provide a likely troubleshooting direction.

This project is part of my goal to improve my PowerShell skills by building tools that are useful for real IT support and system administration scenarios.

## Project Status

**SystemHealthReport.ps1: V1.1 Complete**

**NetworkTroubleshooter.ps1: V1 Complete**

Development and improvements are ongoing.

## Screenshots

### System Health Overview

![System Health Overview](screenshots/system-health-top.png)

### Event Log and Service Checks

![Event Log and Service Checks](screenshots/system-health-events.png)
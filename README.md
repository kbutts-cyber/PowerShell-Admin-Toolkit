# PowerShell Admin Toolkit

A growing collection of PowerShell scripts I am building to get more hands-on with Windows troubleshooting, system administration, and automation.

I got the idea for this toolkit while troubleshooting a customer's PC at work. I realized that a lot of the information I normally check during troubleshooting could be collected automatically instead of running a bunch of individual commands.

## Current Tool

### System Health Report

`SystemHealthReport.ps1` collects system information from a Windows PC and generates both terminal output and a timestamped HTML health report.

The goal is to quickly gather useful troubleshooting information in one place and make the troubleshooting process faster and easier.

## Current Checks

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

## Health Status

The generated HTML report evaluates several system metrics and displays simple health indicators.

### CPU, RAM, and Disk

- Healthy: Below 80%
- Warning: 80% to 89%
- Critical: 90% or higher

### Storage

The script checks the physical disk's reported health and operational status.

If the physical disk reports a healthy state and an operational status of OK, the SSD is marked as Healthy.

### Event Logs

The script checks the Windows System event log for recent Critical and Error events.

If recent Critical or Error events are found, the Event Log section is marked as `Review` so those events can be investigated further.

### Overall System Status

The report also generates an overall system status based on the individual health checks.

Possible statuses include:

- Healthy
- Review
- Critical

## HTML Report

Each time the script runs, it creates a timestamped HTML report in the same folder as the script.

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

## Running the Script

Open PowerShell in the project folder and run:

```powershell
.\SystemHealthReport.ps1

After the script finishes, PowerShell will display the collected information in the terminal and show the location of the generated HTML report.

The report can then be opened in a web browser.

## Parameters

### OutputPath

Use `-OutputPath` to choose where the generated HTML report will be saved.

Example:

```powershell
.\SystemHealthReport.ps1 -OutputPath "C:\Reports"

If no output path is provided, the report is saved in the same folder as the script.

### SkipEventLogs

Use `-SkipEventLogs` to generate the report without checking recent Critical or Error events from the Windows System log.

## Built-In Help

The script includes PowerShell comment-based help so users can quickly see what the script does, what parameters are available, and how to run it.

To view the general help:

    Get-Help .\SystemHealthReport.ps1

To view usage examples:

    Get-Help .\SystemHealthReport.ps1 -Examples

This makes the script easier to use without needing to read through the code first.

## What I Practiced

Building this project gave me hands-on experience with:

- PowerShell variables
- PowerShell objects and properties
- `Get-CimInstance`
- `Get-NetIPAddress`
- `Get-NetIPConfiguration`
- `Get-DnsClientServerAddress`
- `Get-Service`
- `Get-WinEvent`
- `Get-PhysicalDisk`
- `Where-Object`
- `ForEach-Object`
- PowerShell pipelines
- Conditional logic with `if`, `elseif`, and `else`
- Working with Windows services
- Working with Windows event logs
- Working with networking information
- Disk and storage health checks
- Usage percentage calculations
- Basic health thresholds
- Creating timestamped files
- Generating HTML reports with PowerShell

## Current Limitations

This is V1 of the project, and there are still areas I want to improve.

Some planned improvements include:

- Better error handling
- More reliable active network adapter detection
- Improved memory usage calculations
- Support for systems with multiple physical drives
- Additional script parameters
- Logging
- Comment-based PowerShell help
- Better service health interpretation
- More advanced event log analysis
- Improved CPU usage sampling

## Planned Toolkit Scripts

The System Health Report is the first script in a larger PowerShell Admin Toolkit.

Future scripts may include:

- Network troubleshooting tools
- Windows repair and integrity checks
- SFC and DISM utilities
- Service troubleshooting tools
- Active Directory administration scripts
- Microsoft 365 administration scripts
- General Windows support automation

## Why I Built This

The idea came from troubleshooting a customer's PC at work.

During troubleshooting, I noticed that I was checking several different areas of the system individually, including hardware information, network settings, Windows services, disk health, and event logs.

I wanted to see if I could use PowerShell to collect that information in one place and make the troubleshooting process simpler and faster.

This project is also part of my goal to improve my PowerShell skills by building tools that are useful for real IT support and system administration scenarios.

## Project Status

**SystemHealthReport.ps1: V1 Complete**

Development and improvements are ongoing.

## Screenshots

### System Health Overview

![System Health Overview](screenshots/system-health-top.png)

### Event Log and Service Checks

![Event Log and Service Checks](screenshots/system-health-events.png)
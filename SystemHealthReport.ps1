<#
.SYNOPSIS
    Generates a Windows system health report.

.DESCRIPTION
    Collects system information including CPU, memory, disk usage,
    storage health, network configuration, Windows service status,
    and recent Critical/Error events.

    The script displays the results in PowerShell and generates
    a timestamped HTML report.

.PARAMETER OutputPath
    Specifies the folder where the HTML report will be saved.

    If no OutputPath is provided, the report is saved in the same
    folder as the script.

.EXAMPLE
    .\SystemHealthReport.ps1

    Runs the report and saves the HTML file in the script folder.

.EXAMPLE
    .\SystemHealthReport.ps1 -OutputPath "C:\Reports"

    Runs the report and saves the HTML file in C:\Reports.
.PARAMETER SkipEventLogs
    Skips the Windows System event log check.

.EXAMPLE
    .\SystemHealthReport.ps1 -SkipEventLogs

    Generates the report without checking recent Critical or Error events.

.NOTES
    Version: 1.1
#>

param(
    [string]$OutputPath,
    [switch]$SkipEventLogs
)

if (-not $OutputPath) {
    $OutputPath = $PSScriptRoot
}
if (-not (Test-Path $OutputPath)) {
    Write-Host "Error: Output Path does not exist: $OutputPath"
    exit 
}


Write-Host ""
Write-Host "========================================"
Write-Host "          SYSTEM HEALTH REPORT"
Write-Host "========================================"
Write-Host ""

$ComputerName = $env:COMPUTERNAME

Write-Host "--- SYSTEM INFORMATION ---"
Write-Host "Computer Name: $ComputerName"

$OS = Get-CimInstance Win32_OperatingSystem

Write-Host "Windows Version: $($OS.Caption)"
Write-Host "Build Number: $($OS.BuildNumber)"

$LastBootTime = $OS.LastBootUpTime
$CurrentTime = Get-Date
$Uptime = $CurrentTime - $LastBootTime

Write-Host "Uptime: $($Uptime.Days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) minutes"


Write-Host ""
Write-Host "--- RESOURCE USAGE ---"

$ComputerSystem = Get-CimInstance Win32_ComputerSystem

$TotalRAMGB = [math]::Round(
    $ComputerSystem.TotalPhysicalMemory / 1GB,
    2
)

$AvailableRAMGB = [math]::Round(
    $OS.FreePhysicalMemory / 1MB,
    2
)

$UsedRAMGB = [math]::Round(
    $TotalRAMGB - $AvailableRAMGB,
    2
)

$RAMUsagePercent = [math]::Round(
    ($UsedRAMGB / $TotalRAMGB) * 100,
    2
)

Write-Host "Total RAM: $TotalRAMGB GB"
Write-Host "Available RAM: $AvailableRAMGB GB"
Write-Host "RAM Usage: $RAMUsagePercent%"


$Disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

$TotalDiskGB = [math]::Round(
    $Disk.Size / 1GB,
    2
)

$FreeDiskGB = [math]::Round(
    $Disk.FreeSpace / 1GB,
    2
)

$UsedDiskGB = [math]::Round(
    $TotalDiskGB - $FreeDiskGB,
    2
)

$DiskUsagePercent = [math]::Round(
    ($UsedDiskGB / $TotalDiskGB) * 100,
    2
)

Write-Host "Disk Total: $TotalDiskGB GB"
Write-Host "Disk Free: $FreeDiskGB GB"
Write-Host "Disk Usage: $DiskUsagePercent%"


$CPU = Get-CimInstance Win32_Processor
$CPUName = $CPU.Name

Write-Host "CPU: $CPUName"
Write-Host "CPU Usage: $($CPU.LoadPercentage)%"


Write-Host ""
Write-Host "--- NETWORK INFORMATION ---"

$IPAddress = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
        $_.InterfaceAlias -eq "Ethernet" -or
        $_.InterfaceAlias -eq "Wi-Fi"
    } |
    Select-Object -First 1

Write-Host "IP Address: $($IPAddress.IPAddress)"


$NetConfig = Get-NetIPConfiguration `
    -InterfaceIndex $IPAddress.InterfaceIndex

$DefaultGateway = $NetConfig.IPv4DefaultGateway.NextHop

Write-Host "Default Gateway: $DefaultGateway"


$DNS = (
    Get-DnsClientServerAddress `
        -InterfaceIndex $IPAddress.InterfaceIndex `
        -AddressFamily IPv4
).ServerAddresses

Write-Host "DNS Servers: $($DNS -join ', ')"


Write-Host ""
Write-Host "--- SERVICE STATUS ---"

$Spooler = Get-Service Spooler
$WinUpdate = Get-Service wuauserv
$DHCP = Get-Service Dhcp
$DNSClient = Get-Service dnscache

Write-Host "Print Spooler: $($Spooler.Status)"
Write-Host "Windows Update: $($WinUpdate.Status)"
Write-Host "DHCP Client: $($DHCP.Status)"
Write-Host "DNS Client: $($DNSClient.Status)"


Write-Host ""
Write-Host "--- RECENT SYSTEM EVENTS ---"

if (-not $SkipEventLogs) {

    $RecentEvents = Get-WinEvent -FilterHashtable @{
        LogName   = 'System'
        Level     = 1,2
        StartTime = (Get-Date).AddDays(-7)
    } -MaxEvents 5 -ErrorAction SilentlyContinue

    Write-Host "Recent Critical/Error Events:"

    if ($RecentEvents) {

        $RecentEvents | ForEach-Object {

            Write-Host "$($_.TimeCreated) | $($_.LevelDisplayName) | Event ID: $($_.Id) | $($_.ProviderName)"
        }
    }
    else {

        Write-Host "No Critical or Error events found in the last 7 days."
    }
}
else {

    $RecentEvents = $null
    Write-Host "Event log check skipped."
}

Write-Host ""
Write-Host "--- STORAGE HEALTH ---"

$PhysicalDisk = Get-PhysicalDisk

Write-Host "SSD Model: $($PhysicalDisk.FriendlyName)"
Write-Host "Media Type: $($PhysicalDisk.MediaType)"
Write-Host "SSD Health: $($PhysicalDisk.HealthStatus)"
Write-Host "SSD Status: $($PhysicalDisk.OperationalStatus)"


# -------------------------------
# HEALTH STATUS CALCULATIONS
# -------------------------------

if ($RAMUsagePercent -ge 90) {

    $RAMStatus = "Critical"
}
elseif ($RAMUsagePercent -ge 80) {

    $RAMStatus = "Warning"
}
else {

    $RAMStatus = "Healthy"
}


if ($DiskUsagePercent -ge 90) {

    $DiskStatus = "Critical"
}
elseif ($DiskUsagePercent -ge 80) {

    $DiskStatus = "Warning"
}
else {

    $DiskStatus = "Healthy"
}


if ($CPU.LoadPercentage -ge 90) {

    $CPUStatus = "Critical"
}
elseif ($CPU.LoadPercentage -ge 80) {

    $CPUStatus = "Warning"
}
else {

    $CPUStatus = "Healthy"
}


if (
    $PhysicalDisk.HealthStatus -eq "Healthy" -and
    $PhysicalDisk.OperationalStatus -eq "OK"
) {

    $SSDStatus = "Healthy"
}
else {

    $SSDStatus = "Critical"
}


if ($SkipEventLogs) {

    $EventStatus = "Skipped"
}
else {

    $CriticalEventCount = @(
        $RecentEvents |
            Where-Object {
                $_.LevelDisplayName -eq "Critical"
            }
    ).Count

    $ErrorEventCount = @(
        $RecentEvents |
            Where-Object {
                $_.LevelDisplayName -eq "Error"
            }
    ).Count

    if (
        $CriticalEventCount -gt 0 -or
        $ErrorEventCount -gt 0
    ) {

        $EventStatus = "Review"
    }
    else {

        $EventStatus = "Healthy"
    }
}


# -------------------------------
# OVERALL SYSTEM STATUS
# -------------------------------

if (
    $CPUStatus -eq "Critical" -or
    $RAMStatus -eq "Critical" -or
    $DiskStatus -eq "Critical" -or
    $SSDStatus -eq "Critical"
) {

    $OverallStatus = "Critical"
}
elseif (
    $CPUStatus -eq "Warning" -or
    $RAMStatus -eq "Warning" -or
    $DiskStatus -eq "Warning" -or
    $EventStatus -eq "Review"
) {

    $OverallStatus = "Review"
}
else {

    $OverallStatus = "Healthy"
}


# -------------------------------
# HTML REPORT
# -------------------------------

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$ReportPath = Join-Path `
    $OutputPath `
    "SystemHealthReport-$ComputerName-$Timestamp.html"


if ($SkipEventLogs) {

    $EventRows = "<tr><td colspan='4'>Event log check was skipped.</td></tr>"
}
elseif ($RecentEvents) {

    $EventRows = (
        $RecentEvents |
            ForEach-Object {

                "<tr><td>$($_.TimeCreated)</td><td>$($_.LevelDisplayName)</td><td>$($_.Id)</td><td>$($_.ProviderName)</td></tr>"
            }
    ) -join "`n"
}
else {

    $EventRows = "<tr><td colspan='4'>No Critical or Error events found in the last 7 days.</td></tr>"
}


$HTML = @"
<!DOCTYPE html>
<html>

<head>

<meta charset="UTF-8">

<title>
System Health Report - $ComputerName
</title>

<style>

body {
    font-family: Arial, sans-serif;
    margin: 40px;
    background-color: #f4f4f4;
}

.container {
    max-width: 1000px;
    margin: auto;
    background-color: white;
    padding: 30px;
    border-radius: 10px;
}

h1 {
    margin-bottom: 5px;
}

h2 {
    margin-top: 30px;
    border-bottom: 2px solid #ddd;
    padding-bottom: 5px;
}

.overall-status {
    margin-top: 18px;
    margin-bottom: 25px;
    padding: 15px;
    background-color: #f8f8f8;
    border-radius: 8px;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 20px;
}

td,
th {
    padding: 10px;
    border-bottom: 1px solid #ddd;
    text-align: left;
}

th {
    background-color: #eeeeee;
}

.status {
    font-weight: bold;
    padding: 4px 10px;
    border-radius: 12px;
    margin-left: 8px;
    display: inline-block;
}

.healthy {
    background-color: #d4edda;
    color: #155724;
}

.warning {
    background-color: #fff3cd;
    color: #856404;
}

.critical {
    background-color: #f8d7da;
    color: #721c24;
}

.review {
    background-color: #d1ecf1;
    color: #0c5460;
}

</style>

</head>


<body>

<div class="container">


<h1>
System Health Report
</h1>

<p>
<strong>Computer:</strong>
$ComputerName
</p>

<p>
<strong>Generated:</strong>
$(Get-Date)
</p>


<div class="overall-status">

<strong>
Overall System Status:
</strong>

<span class="status $($OverallStatus.ToLower())">
$OverallStatus
</span>

</div>


<h2>
System Information
</h2>

<table>

<tr>
<td>Computer Name</td>
<td>$ComputerName</td>
</tr>

<tr>
<td>Windows Version</td>
<td>$($OS.Caption)</td>
</tr>

<tr>
<td>Build Number</td>
<td>$($OS.BuildNumber)</td>
</tr>

<tr>
<td>Uptime</td>
<td>
$($Uptime.Days) days,
$($Uptime.Hours) hours,
$($Uptime.Minutes) minutes
</td>
</tr>

</table>


<h2>
Resource Usage
</h2>

<table>

<tr>
<td>CPU</td>
<td>$CPUName</td>
</tr>


<tr>
<td>CPU Usage</td>

<td>

$($CPU.LoadPercentage)%

<span class="status $($CPUStatus.ToLower())">
$CPUStatus
</span>

</td>

</tr>


<tr>
<td>Total RAM</td>
<td>$TotalRAMGB GB</td>
</tr>


<tr>
<td>Available RAM</td>
<td>$AvailableRAMGB GB</td>
</tr>


<tr>

<td>RAM Usage</td>

<td>

$RAMUsagePercent%

<span class="status $($RAMStatus.ToLower())">
$RAMStatus
</span>

</td>

</tr>


<tr>
<td>Disk Total</td>
<td>$TotalDiskGB GB</td>
</tr>


<tr>
<td>Disk Free</td>
<td>$FreeDiskGB GB</td>
</tr>


<tr>

<td>Disk Usage</td>

<td>

$DiskUsagePercent%

<span class="status $($DiskStatus.ToLower())">
$DiskStatus
</span>

</td>

</tr>

</table>


<h2>
Storage Health
</h2>

<table>

<tr>
<td>SSD Model</td>
<td>$($PhysicalDisk.FriendlyName)</td>
</tr>

<tr>
<td>Media Type</td>
<td>$($PhysicalDisk.MediaType)</td>
</tr>


<tr>

<td>SSD Health</td>

<td>

<span class="status $($SSDStatus.ToLower())">
$SSDStatus
</span>

</td>

</tr>


<tr>
<td>Operational Status</td>
<td>$($PhysicalDisk.OperationalStatus)</td>
</tr>

</table>


<h2>
Network Information
</h2>

<table>

<tr>
<td>IP Address</td>
<td>$($IPAddress.IPAddress)</td>
</tr>

<tr>
<td>Default Gateway</td>
<td>$DefaultGateway</td>
</tr>

<tr>
<td>DNS Servers</td>
<td>$($DNS -join ', ')</td>
</tr>

</table>


<h2>
Service Status
</h2>

<table>

<tr>
<td>Print Spooler</td>
<td>$($Spooler.Status)</td>
</tr>

<tr>
<td>Windows Update</td>
<td>$($WinUpdate.Status)</td>
</tr>

<tr>
<td>DHCP Client</td>
<td>$($DHCP.Status)</td>
</tr>

<tr>
<td>DNS Client</td>
<td>$($DNSClient.Status)</td>
</tr>

</table>


<h2>
Recent Critical / Error Events
</h2>


<p>

Event Log Status:

<span class="status $($EventStatus.ToLower())">
$EventStatus
</span>

</p>


<table>

<tr>

<th>
Time
</th>

<th>
Level
</th>

<th>
Event ID
</th>

<th>
Provider
</th>

</tr>


$EventRows


</table>


</div>

</body>

</html>
"@


Set-Content `
    -Path $ReportPath `
    -Value $HTML `
    -Encoding UTF8


Write-Host ""
Write-Host "Overall System Status: $OverallStatus"
Write-Host "HTML Report Created: $ReportPath"
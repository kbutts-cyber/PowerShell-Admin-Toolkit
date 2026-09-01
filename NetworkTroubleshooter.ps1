Write-Host ""
Write-Host "========================================"
Write-Host "        NETWORK TROUBLESHOOTER"
Write-Host "========================================"
Write-Host ""


# --------------------------------
# ACTIVE NETWORK CONNECTION
# --------------------------------

Write-Host "--- ACTIVE NETWORK CONNECTION ---"

# First try to find the adapter Windows is using for its default IPv4 route
$DefaultRoute = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
    Sort-Object RouteMetric |
    Select-Object -First 1

if ($DefaultRoute) {

    $ActiveAdapter = Get-NetAdapter -InterfaceIndex $DefaultRoute.InterfaceIndex -ErrorAction SilentlyContinue
}

# If no default route exists, fall back to any physical adapter that is Up
if (-not $ActiveAdapter) {

    $ActiveAdapter = Get-NetAdapter |
        Where-Object {
            $_.Status -eq "Up" -and
            $_.HardwareInterface -eq $true
        } |
        Select-Object -First 1
}


# If there is no active physical adapter at all, stop here
if (-not $ActiveAdapter) {

    Write-Host "Active Adapter: NONE" -ForegroundColor Red
    Write-Host ""
    Write-Host "Diagnosis: No active physical network adapter was detected." -ForegroundColor Red
    Write-Host "Check Ethernet connection, Wi-Fi status, adapter state, or device drivers."

    exit
}


# Pull IP configuration for the selected adapter
$ActiveNetwork = Get-NetIPConfiguration -InterfaceIndex $ActiveAdapter.ifIndex

$IPv4Object = $ActiveNetwork.IPv4Address | Select-Object -First 1

if ($IPv4Object) {

    $IPv4Address = $IPv4Object.IPAddress
    $PrefixLength = $IPv4Object.PrefixLength
}
else {

    $IPv4Address = $null
    $PrefixLength = $null
}


$DefaultGateway = $ActiveNetwork.IPv4DefaultGateway.NextHop


# Check whether DHCP is enabled
$IPInterface = Get-NetIPInterface `
    -InterfaceIndex $ActiveAdapter.ifIndex `
    -AddressFamily IPv4 `
    -ErrorAction SilentlyContinue

$DHCPStatus = $IPInterface.Dhcp


# Get the Windows network profile
$NetworkProfile = Get-NetConnectionProfile `
    -InterfaceIndex $ActiveAdapter.ifIndex `
    -ErrorAction SilentlyContinue

if ($NetworkProfile) {

    $NetworkCategory = $NetworkProfile.NetworkCategory
}
else {

    $NetworkCategory = "Unknown"
}


Write-Host "Active Adapter: $($ActiveAdapter.Name)"
Write-Host "Adapter Status: $($ActiveAdapter.Status)"
Write-Host "Link Speed: $($ActiveAdapter.LinkSpeed)"
Write-Host "Adapter: $($ActiveAdapter.InterfaceDescription)"

if ($IPv4Address) {

    Write-Host "IPv4 Address: $IPv4Address/$PrefixLength"
}
else {

    Write-Host "IPv4 Address: NONE" -ForegroundColor Red
}

if ($DefaultGateway) {

    Write-Host "Default Gateway: $DefaultGateway"
}
else {

    Write-Host "Default Gateway: NONE" -ForegroundColor Red
}

Write-Host "DHCP: $DHCPStatus"
Write-Host "Network Profile: $NetworkCategory"


# --------------------------------
# IP CONFIGURATION CHECK
# --------------------------------

Write-Host ""
Write-Host "--- IP CONFIGURATION CHECK ---"


if (-not $IPv4Address) {

    $IPConfigStatus = "FAIL"
    $IPDiagnosis = "No IPv4 address was detected on the active adapter."

    Write-Host "IPv4 Assignment: FAIL - No IPv4 address detected." -ForegroundColor Red
}

elseif ($IPv4Address -like "169.254.*") {

    $IPConfigStatus = "FAIL"
    $IPDiagnosis = "An APIPA address was detected. The computer may not be receiving an IPv4 address from DHCP."

    Write-Host "IPv4 Assignment: FAIL - APIPA address detected." -ForegroundColor Red
}

elseif (-not $DefaultGateway) {

    $IPConfigStatus = "FAIL"
    $IPDiagnosis = "The computer has an IPv4 address but no default gateway."

    Write-Host "IPv4 Assignment: FAIL - No default gateway." -ForegroundColor Red
}

else {

    $IPConfigStatus = "PASS"
    $IPDiagnosis = "IPv4 configuration appears valid."

    Write-Host "IPv4 Assignment: PASS" -ForegroundColor Green
}


# --------------------------------
# GATEWAY CONNECTIVITY TEST
# --------------------------------

Write-Host ""
Write-Host "--- GATEWAY CONNECTIVITY TEST ---"


if ($DefaultGateway) {

    $GatewayTest = Test-Connection `
        -ComputerName $DefaultGateway `
        -Count 2 `
        -Quiet `
        -ErrorAction SilentlyContinue
}
else {

    $GatewayTest = $false
}


if ($GatewayTest -eq $true) {

    Write-Host "Gateway Connectivity: PASS" -ForegroundColor Green
}
else {

    Write-Host "Gateway Connectivity: FAIL" -ForegroundColor Red
}


# --------------------------------
# INTERNET CONNECTIVITY TEST
# --------------------------------

Write-Host ""
Write-Host "--- INTERNET CONNECTIVITY TEST ---"


$InternetTest = Test-Connection `
    -ComputerName "1.1.1.1" `
    -Count 2 `
    -Quiet `
    -ErrorAction SilentlyContinue


if ($InternetTest -eq $true) {

    Write-Host "Internet Connectivity: PASS" -ForegroundColor Green
}
else {

    Write-Host "Internet Connectivity: FAIL" -ForegroundColor Red
}


# --------------------------------
# DNS SERVER INFORMATION
# --------------------------------

Write-Host ""
Write-Host "--- DNS SERVER INFORMATION ---"


$DNSServers = (
    Get-DnsClientServerAddress `
        -InterfaceIndex $ActiveAdapter.ifIndex `
        -AddressFamily IPv4 `
        -ErrorAction SilentlyContinue
).ServerAddresses


if ($DNSServers) {

    Write-Host "DNS Servers: $($DNSServers -join ', ')"
}
else {

    Write-Host "DNS Servers: NONE" -ForegroundColor Red
}


# --------------------------------
# DNS RESOLUTION TEST
# --------------------------------

Write-Host ""
Write-Host "--- DNS RESOLUTION TEST ---"


$DNSTest = Resolve-DnsName google.com -ErrorAction SilentlyContinue


if ($DNSTest -ne $null) {

    Write-Host "DNS Resolution: PASS" -ForegroundColor Green
}
else {

    Write-Host "DNS Resolution: FAIL" -ForegroundColor Red
}


# --------------------------------
# TCP PORT TEST
# --------------------------------

Write-Host ""
Write-Host "--- TCP PORT TEST ---"


$TCPPortTest = Test-NetConnection `
    google.com `
    -Port 443 `
    -WarningAction SilentlyContinue


if ($TCPPortTest.TcpTestSucceeded -eq $true) {

    Write-Host "TCP Port 443 Test: PASS" -ForegroundColor Green
}
else {

    Write-Host "TCP Port 443 Test: FAIL" -ForegroundColor Red
}


# --------------------------------
# OVERALL NETWORK STATUS
# --------------------------------

if (
    $IPConfigStatus -eq "FAIL" -or
    $GatewayTest -ne $true
) {

    $OverallNetworkStatus = "CRITICAL"
}

elseif (
    $InternetTest -ne $true -or
    $DNSTest -eq $null -or
    $TCPPortTest.TcpTestSucceeded -ne $true
) {

    $OverallNetworkStatus = "REVIEW"
}

else {

    $OverallNetworkStatus = "HEALTHY"
}


# --------------------------------
# TROUBLESHOOTING SUMMARY
# --------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host "        TROUBLESHOOTING SUMMARY"
Write-Host "========================================"


if ($OverallNetworkStatus -eq "HEALTHY") {

    Write-Host "Overall Network Status: HEALTHY" -ForegroundColor Green
}

elseif ($OverallNetworkStatus -eq "REVIEW") {

    Write-Host "Overall Network Status: REVIEW" -ForegroundColor Yellow
}

else {

    Write-Host "Overall Network Status: CRITICAL" -ForegroundColor Red
}


Write-Host ""

if ($IPConfigStatus -eq "PASS") {

    Write-Host "IP Configuration: PASS" -ForegroundColor Green
}
else {

    Write-Host "IP Configuration: FAIL" -ForegroundColor Red
}


if ($GatewayTest -eq $true) {

    Write-Host "Gateway: PASS" -ForegroundColor Green
}
else {

    Write-Host "Gateway: FAIL" -ForegroundColor Red
}


if ($InternetTest -eq $true) {

    Write-Host "Internet: PASS" -ForegroundColor Green
}
else {

    Write-Host "Internet: FAIL" -ForegroundColor Red
}


if ($DNSTest -ne $null) {

    Write-Host "DNS Resolution: PASS" -ForegroundColor Green
}
else {

    Write-Host "DNS Resolution: FAIL" -ForegroundColor Red
}


if ($TCPPortTest.TcpTestSucceeded -eq $true) {

    Write-Host "TCP Port 443: PASS" -ForegroundColor Green
}
else {

    Write-Host "TCP Port 443: FAIL" -ForegroundColor Red
}


# --------------------------------
# LIKELY DIAGNOSIS
# --------------------------------

Write-Host ""
Write-Host "--- LIKELY DIAGNOSIS ---"


if ($IPConfigStatus -eq "FAIL") {

    Write-Host $IPDiagnosis -ForegroundColor Red
}

elseif ($GatewayTest -ne $true) {

    Write-Host "Unable to reach the default gateway." -ForegroundColor Red
    Write-Host "Check the local connection, network adapter, Ethernet cable/Wi-Fi connection, or router."
}

elseif ($InternetTest -ne $true) {

    Write-Host "The local gateway is reachable, but the internet connectivity test failed." -ForegroundColor Yellow
    Write-Host "Check the router's upstream connection or ISP connectivity."
}

elseif ($DNSTest -eq $null) {

    Write-Host "Internet connectivity works, but DNS resolution failed." -ForegroundColor Yellow
    Write-Host "Check the configured DNS servers or DNS client configuration."
}

elseif ($TCPPortTest.TcpTestSucceeded -ne $true) {

    Write-Host "General connectivity and DNS are working, but TCP port 443 failed." -ForegroundColor Yellow
    Write-Host "Check firewall rules, filtering, proxy settings, or service availability."
}

else {

    Write-Host "Network connectivity appears healthy." -ForegroundColor Green
}

Write-Host ""
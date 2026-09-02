Write-Host ""
Write-Host "========================================"
Write-Host "        WINDOWS REPAIR TOOL"
Write-Host "========================================"
Write-Host ""

# --------------------------------
# ADMINISTRATOR CHECK
# --------------------------------
# SFC and DISM repair operations require an elevated PowerShell session.
# This section checks whether the current session is running as Administrator.

Write-Host "--- ADMINISTRATOR CHECK ---"

$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()

# WindowsPrincipal allows us to check which Windows roles
# the current user/session belongs to.
$Role = [Security.Principal.WindowsPrincipal]::new($CurrentUser)

# Store the result as True or False.
$IsAdmin = $Role.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($IsAdmin -eq $true) {

    Write-Host "You are running this script as an Administrator." -ForegroundColor Green

}
else {

    Write-Host "You are NOT running this script as an Administrator." -ForegroundColor Red
    Write-Host "Please run this script as an Administrator to perform repairs." -ForegroundColor Yellow

    # Stop the script so SFC/DISM are not attempted without elevation.
    exit

}


# --------------------------------
# SYSTEM FILE CHECKER
# --------------------------------
# SFC /scannow checks protected Windows system files for corruption
# and attempts to replace corrupted files with healthy copies.

Write-Host ""
Write-Host "--- SYSTEM FILE CHECKER ---"

# Create a temporary file path.
# We will use this file to capture the output from THIS SFC scan only.
$SFCOutputPath = Join-Path $env:TEMP "SFCOutput-$PID.txt"

# Run SFC.
#
# -Wait:
# PowerShell waits for SFC to finish before continuing.
#
# -PassThru:
# Returns the process object so we can inspect the ExitCode.
#
# -RedirectStandardOutput:
# Sends SFC's terminal output into our temporary file
# so the script can analyze what SFC actually reported.
$SFCProcess = Start-Process `
    -FilePath "sfc.exe" `
    -ArgumentList "/scannow" `
    -Wait `
    -PassThru `
    -RedirectStandardOutput $SFCOutputPath

# Exit code 0 means the SFC process itself completed successfully.
# This does NOT automatically mean there was no corruption.
if ($SFCProcess.ExitCode -eq 0) {

    Write-Host "System File Checker completed successfully." -ForegroundColor Green

}
else {

    Write-Host "System File Checker did not complete successfully. Review may be required." -ForegroundColor Red

}


# --------------------------------
# SFC RESULT CHECK
# --------------------------------
# Search the output from THIS SFC scan for specific result messages.
# Select-String -SimpleMatch treats the phrases as normal text instead of regex.
# -Quiet returns only True or False, which makes the result easy to use in if statements.

Write-Host ""
Write-Host "--- SFC RESULT CHECK ---"

$SFCUnrepaired = Select-String `
    -Path $SFCOutputPath `
    -SimpleMatch "unable to fix some of them" `
    -Quiet

$SFCRepaired = Select-String `
    -Path $SFCOutputPath `
    -SimpleMatch "successfully repaired them" `
    -Quiet

$SFCHealthy = Select-String `
    -Path $SFCOutputPath `
    -SimpleMatch "did not find any integrity violations" `
    -Quiet


# If the SFC process itself failed, do not interpret the result as healthy.
if ($SFCProcess.ExitCode -ne 0) {

    $SFCStatus = "Failed"

    Write-Host "SFC did not complete successfully." -ForegroundColor Red

}

# SFC found corruption but could not repair everything.
elseif ($SFCUnrepaired -eq $true) {

    $SFCStatus = "Unrepaired"

    Write-Host "SFC found corrupted files that could not all be repaired." -ForegroundColor Red

}

# SFC found corruption and repaired it successfully.
elseif ($SFCRepaired -eq $true) {

    $SFCStatus = "Repaired"

    Write-Host "SFC found and repaired corrupted files." -ForegroundColor Green

}

# SFC completed and found no integrity violations.
elseif ($SFCHealthy -eq $true) {

    $SFCStatus = "Healthy"

    Write-Host "SFC did not find any integrity violations." -ForegroundColor Green

}

# SFC ran successfully, but none of the expected result messages were found.
else {

    $SFCStatus = "Unknown"

    Write-Host "SFC completed, but the result could not be automatically determined." -ForegroundColor Yellow

}


# Remove the temporary SFC output file after we finish analyzing it.
Remove-Item -Path $SFCOutputPath -ErrorAction SilentlyContinue

# --------------------------------
# DISM HEALTH CHECK
# --------------------------------
# DISM checks the Windows component store.
# SFC relies on healthy Windows components when repairing system files.

Write-Host ""
Write-Host "--- DISM HEALTH CHECK ---"


# --------------------------------
# DISM CHECKHEALTH
# --------------------------------
# /CheckHealth is a quick check.
# It determines whether Windows has already marked the image as corrupted.

Write-Host "Running DISM CheckHealth..." -ForegroundColor Yellow

$DISMProcess = Start-Process `
    -FilePath "dism.exe" `
    -ArgumentList "/Online", "/Cleanup-Image", "/CheckHealth" `
    -Wait `
    -PassThru

if ($DISMProcess.ExitCode -eq 0) {

    Write-Host "DISM CheckHealth completed successfully." -ForegroundColor Green

}
else {

    Write-Host "DISM CheckHealth did not complete successfully. Review may be required." -ForegroundColor Red

}


# --------------------------------
# DISM SCANHEALTH
# --------------------------------
# /ScanHealth performs a deeper scan of the Windows component store.
# This normally takes longer than CheckHealth.

Write-Host ""
Write-Host "Running DISM ScanHealth..." -ForegroundColor Yellow

$DISMScan = Start-Process `
    -FilePath "dism.exe" `
    -ArgumentList "/Online", "/Cleanup-Image", "/ScanHealth" `
    -Wait `
    -PassThru

if ($DISMScan.ExitCode -eq 0) {

    Write-Host "DISM ScanHealth completed successfully." -ForegroundColor Green

}
else {

    Write-Host "DISM ScanHealth did not complete successfully. Review may be required." -ForegroundColor Red

}


# --------------------------------
# OPTIONAL DISM RESTOREHEALTH
# --------------------------------
# RestoreHealth can make changes to the Windows image.
# Instead of running it automatically every time,
# let the user decide whether they want to perform the repair.

Write-Host ""

$RunRepair = Read-Host "Do you want to run DISM RestoreHealth? (Y/N)"

# Initialize the variable first.
# If the user skips RestoreHealth, it will remain $null.
$DISMRepair = $null

if ($RunRepair -eq "Y" -or $RunRepair -eq "y") {

    Write-Host "Running DISM RestoreHealth..." -ForegroundColor Yellow

    # /RestoreHealth scans the component store and attempts to repair corruption.
    $DISMRepair = Start-Process `
        -FilePath "dism.exe" `
        -ArgumentList "/Online", "/Cleanup-Image", "/RestoreHealth" `
        -Wait `
        -PassThru

    if ($DISMRepair.ExitCode -eq 0) {

        Write-Host "DISM RestoreHealth completed successfully." -ForegroundColor Green

    }
    else {

        Write-Host "DISM RestoreHealth did not complete successfully. Review may be required." -ForegroundColor Red

    }

}
else {

    Write-Host "Skipping DISM RestoreHealth." -ForegroundColor Yellow

}


# --------------------------------
# REPAIR SUMMARY
# --------------------------------
# Display the results of each repair/check operation in one place.

Write-Host ""
Write-Host "========================================"
Write-Host "        REPAIR SUMMARY"
Write-Host "========================================"


# Display the SFC result based on the status we stored earlier.
if ($SFCStatus -eq "Healthy") {

    Write-Host "SFC Result: HEALTHY" -ForegroundColor Green

}
elseif ($SFCStatus -eq "Repaired") {

    Write-Host "SFC Result: CORRUPTION REPAIRED" -ForegroundColor Green

}
elseif ($SFCStatus -eq "Unrepaired") {

    Write-Host "SFC Result: UNREPAIRED CORRUPTION" -ForegroundColor Red

}
else {

    Write-Host "SFC Result: REVIEW" -ForegroundColor Yellow

}


# Display DISM CheckHealth process result.
if ($DISMProcess.ExitCode -eq 0) {

    Write-Host "DISM CheckHealth: COMPLETED" -ForegroundColor Green

}
else {

    Write-Host "DISM CheckHealth: REVIEW" -ForegroundColor Red

}


# Display DISM ScanHealth process result.
if ($DISMScan.ExitCode -eq 0) {

    Write-Host "DISM ScanHealth: COMPLETED" -ForegroundColor Green

}
else {

    Write-Host "DISM ScanHealth: REVIEW" -ForegroundColor Red

}


# Only evaluate RestoreHealth if the user chose to run it.
if ($RunRepair -eq "Y" -or $RunRepair -eq "y") {

    if ($DISMRepair.ExitCode -eq 0) {

        Write-Host "DISM RestoreHealth: COMPLETED" -ForegroundColor Green

    }
    else {

        Write-Host "DISM RestoreHealth: REVIEW" -ForegroundColor Red

    }

}
else {

    Write-Host "DISM RestoreHealth: SKIPPED" -ForegroundColor Yellow

}


Write-Host ""

# --------------------------------
# OVERALL RESULT
# --------------------------------
# Break the final logic into smaller Boolean variables.
# This is easier to read than putting every condition into one huge if statement.

# SFC is considered successful if:
# 1. The SFC process completed successfully
# AND
# 2. The result was Healthy or corruption was successfully Repaired.
$SFCPassed = (
    $SFCProcess.ExitCode -eq 0 -and
    ($SFCStatus -eq "Healthy" -or $SFCStatus -eq "Repaired")
)

# Both DISM diagnostic commands must complete successfully.
$DISMChecksPassed = (
    $DISMProcess.ExitCode -eq 0 -and
    $DISMScan.ExitCode -eq 0
)

# RestoreHealth is considered successful if:
# the user skipped it
# OR
# the user ran it and it completed successfully.
$RestoreHealthPassed = (
    ($RunRepair -ne "Y" -and $RunRepair -ne "y") -or
    ($DISMRepair.ExitCode -eq 0)
)

# All three groups must pass for the overall result to be successful.
if ($SFCPassed -eq $true -and $DISMChecksPassed -eq $true -and $RestoreHealthPassed -eq $true) {

    Write-Host "All selected repair operations completed successfully." -ForegroundColor Green

}
else {

    Write-Host "Some repair operations require review." -ForegroundColor Red

}

Write-Host ""
Write-Host "Windows Repair Tool completed."
# Windows Hardening & Maintenance Script

$banner = @"
 __          ___        _____ _     _      _     _ 
 \ \        / (_)      / ____| |   (_)    | |   | |
  \ \  /\  / / _ _ __ | (___ | |__  _  ___| | __| |
   \ \/  \/ / | | '_ \ \___ \| '_ \| |/ _ \ |/ _` |
    \  /\  /  | | | | |____) | | | | |  __/ | (_| |
     \/  \/   |_|_| |_|_____/|_| |_|_|\___|_|\__,_|
        Windows Hardening & Maintenance Script
                Version: 1.0
"@

# Display Banner
Write-Host $banner -ForegroundColor Cyan

# Ensure script is run as administrator
Write-Host "`n`n`nChecking for Administrator privileges..." -NoNewline -ForegroundColor Yellow

# Get current user identity and check if in Administrators group
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "  Administrator privileges required! You need to run this script as an Administrator!" -ForegroundColor DarkRed
    Exit
}
else {
    Write-Host " Administrator privileges confirmed." -ForegroundColor DarkGreen
}

# Import necessary modules
Import-Module -Name ScheduledTasks -ErrorAction SilentlyContinue


Write-Host "`n`nStarting Windows Hardening..." -ForegroundColor Green

# Disable SMBv1
Write-Host "`n[+] Checking SMBv1 Protocol..." -ForegroundColor Cyan
$SMB1Feature = Get-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol"
if ($SMB1Feature.State -eq "Enabled") {
    Write-Host "[!] SMBv1 is enabled. Disabling..." -ForegroundColor Yellow
    Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart -ErrorAction SilentlyContinue
    if ($?) {
        Write-Host "[✓] SMBv1 has been disabled." -ForegroundColor DarkGreen
    } else {
        Write-Host "[X] Failed to disable SMBv1." -ForegroundColor DarkRed
    }
} else {
    Write-Host "[=] SMBv1 is already disabled." -ForegroundColor DarkGreen
}


# Disable Remote Desktop
Write-Host "`n[+] Disabling Remote Desktop..." -NoNewline -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1 -Force
if ($?) {
    Write-Host "[✓] Remote Desktop has been disabled." -ForegroundColor DarkGreen
} else {
    Write-Host "[X] Failed to disable Remote Desktop." -ForegroundColor DarkRed
}

# Enable Windows Defender
Write-Host "`n[+] Enabling Windows Defender..." -NoNewline -ForegroundColor Yellow
Set-MpPreference -DisableRealtimeMonitoring $false
if ($?) {
    Write-Host "[✓] Windows Defender has been enabled." -ForegroundColor DarkGreen
} else {
    Write-Host "[X] Failed to enable Windows Defender." -ForegroundColor DarkRed
}

# Disable Guest Account
Write-Host "`n[+] Disabling Guest Account..." -NoNewline -ForegroundColor Yellow
$guestAccount = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
if ($guestAccount) {
    if ($guestAccount.Enabled) {
        Disable-LocalUser -Name "Guest"
        Write-Host "[✓] Guest account has been disabled." -ForegroundColor DarkGreen
    } else {
        Write-Host "[=] Guest account is already disabled." -ForegroundColor DarkYellow
    }
} else {
    Write-Host "[=] Guest account does not exist." -ForegroundColor DarkYellow
}

# Enable Windows Firewall
Write-Host "`n[+] Enabling Windows Firewall..." -NoNewline -ForegroundColor Yellow

# Get all firewall profiles and filter the ones that are disabled
$disabledProfiles = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $false }

if ($disabledProfiles.Count -gt 0) {
    # Enable all profiles
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Write-Host "[✓] Disabled profiles were enabled." -ForegroundColor DarkGreen
} else {
    Write-Host "[=] Already enabled on all profiles." -ForegroundColor DarkYellow
}

# Disable Autorun for Removable Media
Write-Host "`n[+] Disabling AutoRun..." -ForegroundColor Yellow
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255 -PropertyType DWord -Force | Out-Null
Write-Host "[✓] AutoRun has been disabled." -ForegroundColor DarkGreen

# Disable Windows Script Host
Write-Host "`n[+] Disabling Windows Script Host..." -NoNewline -ForegroundColor Yellow
$wshKey = "HKLM:\Software\Microsoft\Windows Script Host\Settings"

# Create the key if it doesn't exist
if (-not (Test-Path $wshKey)) {
    New-Item -Path $wshKey -Force | Out-Null
}

# Set the "Enabled" value to 0 (disable WSH)
try {
    Set-ItemProperty -Path $wshKey -Name "Enabled" -Value 0 -Force
    Write-Host "[✓] Windows Script Host has been disabled." -ForegroundColor DarkGreen
}
catch {
    Write-Host "[X] Failed to disable Windows Script Host." -ForegroundColor DarkRed
}


# Script to check/install winget and schedule weekly updates
Write-Host "`n[+] Checking for winget installation..." -ForegroundColor Cyan

# Check if winget is installed
$wingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue
if ($wingetCmd) {
    $wingetPath = $wingetCmd.Source
} else {
    $wingetPath = $null
}
if (-not $wingetPath) {
    Write-Host "[!] winget is not installed. Attempting installation..." -ForegroundColor Yellow

    # Download App Installer from Microsoft Store via PowerShell (requires Windows 10 1809+ and Store access)
    try {
        $wingetInstallerUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        Invoke-WebRequest -Uri $wingetInstallerUrl -OutFile "$env:TEMP\AppInstaller.msixbundle"
        Add-AppxPackage -Path "$env:TEMP\AppInstaller.msixbundle"
        Start-Sleep -Seconds 5
        if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
            Write-Host "[+] winget installed successfully." -ForegroundColor Green
        } else {
            Write-Host "[X] winget installation failed. Please install manually." -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "[X] Error downloading or installing winget: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[+] winget is already installed at $wingetPath" -ForegroundColor Green
}

# Check if the scheduled task already exists
$taskName = "WeeklyWingetUpdates"
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($taskExists) {
    Write-Host "`n[=] Scheduled task '$taskName' already exists. Skipping creation." -ForegroundColor Yellow
} else {
    Write-Host "`n[+] Creating a scheduled task to run weekly winget updates..." -ForegroundColor Cyan

    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command `"winget upgrade --all --silent`""
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3am
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal

    Write-Host "[+] Scheduled task '$taskName' created to run every Sunday at 3 AM." -ForegroundColor Green
}

# Run once now
Write-Host "`nRunning winget upgrade now..."
winget upgrade --all --silent

Write-Host "`n[✓] Windows Hardening & Maintenance complete." -ForegroundColor Green


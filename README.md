# WinShield – Windows Hardening & Maintenance Script

## Overview

**WinShield** is an open-source PowerShell utility that enhances the security and performance of Windows systems. It automates key hardening steps and maintenance tasks by disabling legacy or insecure features, enabling essential security services, and updating installed applications — all in a single run.

This project is designed for individual users, system administrators, small businesses, and startups that need a quick, reliable, and repeatable way to secure Windows machines without relying on costly enterprise solutions.

> **Note:** This script must be run with **Administrator** privileges.



## Inspiration

In the early stages, many organizations lack access to hardened system images or dedicated cybersecurity expertise. WinShield was created to bridge this gap — making security best practices more accessible to those who need them most. It aims to be simple enough for non-experts, while still valuable to seasoned IT professionals.



##  Features

- **Disable Insecure Features**
  - SMBv1 Protocol
  - Remote Desktop (RDP)
  - Guest Account
  - AutoRun for Removable Media
  - Windows Script Host

- **Enable/Verify Security Services**
  - Windows Defender Real-Time Protection
  - Windows Firewall (All Profiles)

- **System Maintenance**
  - Update installed applications via [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
  - *(Future Feature)* Schedule recurring updates



##  Requirements

- PowerShell 5.1 or higher  
- Windows 10 or Windows 11  
- Administrator privileges  
- Internet connectivity (for updates via `winget`)

---

##  Getting Started

### 1. Clone or Download the Repository

```bash
git clone https://github.com/yourusername/winshield.git
cd winshield
```
### 2. Run the Script
Open PowerShell as Administrator, then run:

```powershell
Set-ExecutionPolicy RemoteSigned
.\WinShield.ps1
```
Follow the on-screen prompts to complete the hardening and maintenance steps.

## Customization

The script is modular and can be easily adapted to your specific organizational security policies or compliance frameworks.
Feel free to fork the project or submit a pull request with improvements.

## Project Structure

```plaintext
WinShield/
│
├── WinShield.ps1          # Main script file
├── README.md               # Project documentation
└──LICENSE                 # License file
```

## Changelog
- **V 1.0** - Initial release with core hardening features
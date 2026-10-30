<div align="right">
  
  ### Check out my other 
  
  [![Repositories](https://img.shields.io/badge/Repositories-Murdervan-blue?style=for-the-badge&logo=github)](https://github.com/Murdervan?tab=repositories)
</div>

</div>

# WinToolKit - WORK FOLDER

### Your Portable Windows Tool kit
**Made by Murdervan**

**One toolkit. One menu. Ready when you need it.**

WinToolKit is a portable PowerShell toolkit designed to make Windows setup and maintenance easier. Keep your essential tools together, carry them on a USB stick, and access useful Windows utilities from one simple menu.

Whether you're setting up a new PC, installing your favourite applications, or removing unwanted built-in apps, WinToolKit helps keep the process organised and straightforward.

No complicated interface. No unnecessary menus. Just practical tools in one place.

![Platform](https://img.shields.io/badge/Platform-Windows-0078D4?style=flat-square&logo=windows)
![Shell](https://img.shields.io/badge/Shell-PowerShell-5391FE?style=flat-square&logo=powershell)
![Version](https://img.shields.io/badge/Version-v1.0.1-2ea44f?style=flat-square)
![USB Friendly](https://img.shields.io/badge/USB-Portable-8957e5?style=flat-square)

---

### Quick Start — WinToolKit CMD Version

Prefer an easier way to get started? Use **[WinToolKit CMD Version](https://github.com/Murdervan/WinToolKit-cmd-version)** to download the latest release and launch WinToolKit with administrator privileges.

---

## 📑 Table of Contents

- [Features](#-features)
- [Download](#-download-wintoolkit)
- [Installation and Setup](#-installation-and-setup)
- [Install Custom Apps](#-install-custom-apps)
- [Windows and Office Activation](#-windows-and-office-activation)
- [Remove Apps](#-remove-apps)
- [System Information and Logs](#-system-information-and-logs)
- [Requirements](#-requirements)
- [Credits](#-credits)
- [WinToolKit — Menu Preview](#wintoolkit--menu-preview)

## ✨ Features

- **Install Custom Apps** — Launch application installers from your own collection.
- **Windows & Office Activation** — Access Microsoft Activation Scripts (Massgrave).
- **Remove Apps** — Remove selected built-in Windows apps.
- **System Information** — View useful information about the computer.
- **Logs** — Access WinToolKit logs.
- **About WinToolKit** — View toolkit information.

## 📥 Download WinToolKit

**[⬇️ Download the Latest Release](../../releases/latest)**

1. Open the latest release on GitHub.
2. Download the WinToolKit ZIP file.
3. Save it to your computer or USB stick.
4. Extract the ZIP before launching the toolkit.

Keep the extracted files together in their original folder structure.

## 🚀 Installation and Setup

### Option 1 — Run from Your Computer

1. Download and extract the ZIP file.
2. Open the extracted WinToolKit folder.
3. Run `RunAsAdmin.bat`.
4. Approve the Windows administrator prompt if requested.
5. Choose a tool from the menu.

### Option 2 — Run from a USB Stick

WinToolKit is designed to be convenient to carry between compatible Windows PCs.

1. Download and extract the ZIP file.
2. Copy the extracted WinToolKit files to your USB stick.
3. Connect the USB stick to the target PC.
4. Open the WinToolKit folder on the USB stick.
5. Run `RunAsAdmin.bat`.
6. Select the feature you want to use.

**Tip:** Keep `RunAsAdmin.bat`, `WinToolKit.ps1`, and the supporting files together. Do not move individual files out of the toolkit folder.

## 📦 Install Custom Apps

The custom app installer lets you keep your own collection of application installers with WinToolKit. This is useful when setting up a PC and installing the software you regularly use.

### How It Works

1. Open the WinToolKit folder.
2. Find the `Apps` folder.
3. Place your supported application installer files or required app folders inside it.
4. Start WinToolKit using `RunAsAdmin.bat`.
5. Open **Install Custom Apps** from the menu.
6. Select the application you want.
7. The selected application's installer starts.

You can then follow the installation instructions displayed by that application.

### Why Keep Installers in the `Apps` Folder?

The `Apps` folder lets you store application installers alongside WinToolKit so they are available when you need them offline.

- **Offline installation** — Install applications without downloading the installer again, as long as the installer includes all required files.
- **USB portability** — Carry WinToolKit and your installers on a USB stick and use them on another compatible Windows PC offline.
- **Faster setup** — Reuse the same installer files when setting up or reinstalling a PC.
- **Your own app collection** — Choose which installers and versions you want to keep available.

WinToolKit does not include third-party installers by default, so you add the installers you want to use yourself.

**Important:** Not every installer works offline. Some installers are only small downloaders and still need an internet connection to download the application files. For the best offline experience, use complete offline installers from the application's official website.

Keep the installers in the folder structure supported by WinToolKit so the toolkit can detect and launch them.

### Important Notes

- WinToolKit does not automatically include every third-party application.
- You are responsible for adding the installers you want to use.
- Use installers from trusted sources.
- The installer must be in a format and folder structure supported by WinToolKit.

This makes it possible to keep your own application collection on a USB stick and use it when preparing another PC.

## 🔑 Windows and Office Activation

WinToolKit provides access to **Microsoft Activation Scripts (Massgrave)**, a separate project that offers Windows and Office activation options.

### How to Use It

1. Start WinToolKit.
2. Select the Windows and Office activation option.
3. Follow the instructions provided by Microsoft Activation Scripts.

An internet connection may be required.

Use activation methods appropriate for your licence and software entitlement.

**Official project:** [Microsoft Activation Scripts on GitHub](https://github.com/massgravel/Microsoft-Activation-Scripts)

## 🧹 Remove Apps

This feature helps you remove selected built-in Microsoft apps that you do not need.

### How to Use It

1. Start WinToolKit.
2. Select **Remove Apps**.
3. Review the available apps.
4. Choose the app or apps you want to remove.
5. Follow any prompts shown by WinToolKit.

Removing certain apps may affect Windows features or other software that depends on them. Review your selections before proceeding.

## 💻 System Information and Logs

### System Information

Use this option to view useful information about the Windows computer you are working on. It can be helpful when checking a system or troubleshooting an issue.

### Logs

Use the log option to access available WinToolKit logs. Logs can help you review activity and investigate problems when a supported feature does not behave as expected.

## ⚙️ Requirements

- Windows 10 or Windows 11
- Windows PowerShell
- Administrator permissions for certain features
- Internet connection for online activation scripts

## 🙏 Credits

Windows and Office activation is powered by [Microsoft Activation Scripts](https://github.com/massgravel/Microsoft-Activation-Scripts).

WinToolKit is a separate project and is not affiliated with the Microsoft Activation Scripts project.

## 📌 Created by

Created by **Murdervan**.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# WinToolKit — Menu Preview

**Made by Murdervan**

Explore the menus and features of WinToolKit before downloading it.

This page provides a text-based preview of the toolkit's main menu and its available features. Dynamic content, such as installed apps, system information, installer files and logs, will vary depending on the computer.

---

## 1. Main Menu

```text
██╗    ██╗██╗███╗   ██╗    ████████╗ ██████╗  ██████╗ ██╗         ██╗  ██╗██╗████████╗
██║    ██║██║████╗  ██║    ╚══██╔══╝██╔═══██╗██╔═══██╗██║         ██║ ██╔╝██║╚══██╔══╝
██║ █╗ ██║██║██╔██╗ ██║       ██║   ██║   ██║██║   ██║██║         █████╔╝ ██║   ██║
██║███╗██║██║██║╚██╗██║       ██║   ██║   ██║██║   ██║██║         ██╔═██╗ ██║   ██║
╚███╔███╔╝██║██║ ╚████║       ██║   ╚██████╔╝╚██████╔╝███████╗    ██║  ██╗██║   ██║
 ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝    ╚═╝  ╚═╝╚═╝   ╚═╝

                                 by Murdervan
                                 Version 1.0.1

MAIN MENU
----------------------------------------------
[1] Install Custom Apps
[2] Massgrave - Activate Windows & Office
[3] Remove Apps (Standard MS Apps)
[4] System Info
[5] Log Info
[6] Update WinToolKit
[7] About WinToolKit v1.0.1
[Q] Quit
----------------------------------------------
```

The main menu gives quick access to the toolkit's primary features.

---

## 2. Install Custom Apps

Browse your own application installers, scripts and other files.

```text
INSTALL CUSTOM APPS
Browse folders, open them in Explorer, or choose a file to run/open.

Current folder: ...\WinToolKit\Apps

[ 1] [FOLDER] Gaming apps
[ 2] [FOLDER] Other
[ 3] ChromeSetup.exe  (.EXE)
[ 4] VLC-Installer.exe (.EXE)

[O] Open current folder in Explorer    [R] Refresh   [B] Back

Choose a number or action:
```

The displayed folders and files are examples. Your actual list depends on the contents of your `Apps` folder.

Supported actions include:

- Browse folders and subfolders.
- Open the current folder in Windows Explorer.
- Refresh the file list.
- Launch supported installers.
- Run BAT, CMD and PowerShell scripts.
- Open other supported file types with their default Windows application.

Before launching a selected file, WinToolKit asks for confirmation.

```text
Selected: ChromeSetup.exe
Location: ...\WinToolKit\Apps\ChromeSetup.exe

Only run installers you trust; they may make system-wide changes.

Type RUN to start, or press Enter to cancel:
```

The `Apps` folder can contain installers you want to keep available without downloading them again. Offline installation still depends on whether the particular installer/apps want internet or not.

---

## 3. Windows & Office Activation 

WinToolKit provides access to Microsoft Activation Scripts (Massgrave).

```text
Starting Massgrave...

This runs the external Massgrave script, as requested.
```

<b>An internet connection is required to retrieve the external script.</b>


Official project:

https://github.com/massgravel/Microsoft-Activation-Scripts

Use activation methods appropriate for your Windows or Office licence and software entitlement.

---

## 4. Remove Apps

Open the Remove Apps menu to access individual removal, mass removal, app scanning and logs.

```text
REMOVE APPS

[1] Remove one app
[2] Mass removal of all listed apps
[3] Force removal: OneDrive and Xbox
[4] Scan app list
[5] View log
[6] Clear log
[B] Back to main menu

Select an option:
```

### 4.1 Remove One App

Choose an individual app from the categorised list.

```text
REMOVE ONE APP

The existing removal logic is retained.
A confirmation is required for each app.

--- SYSTEM ---
[1] Calculator
[2] Paint
[3] Clock
[4] Windows Store
[5] Store Core
[6] OneDrive
[7] Quick Assist

--- MEDIA ---
[8] Media Player
[9] Music
[10] Camera
[11] Voice Recorder
[12] Clipchamp
[13] Films & TV

--- XBOX ---
[14] Xbox App
[15] Xbox Game Bar
[16] Xbox Identity Provider
[17] Xbox Speech To Text
[18] Xbox TCUI

--- COMMUNICATION ---
[19] Teams Personal
[20] Skype
[21] Mail & Calendar
[22] Outlook New
[23] LinkedIn

--- PRODUCTIVITY ---
[24] To Do
[25] Sticky Notes
[26] OneNote
[27] Office Hub
[28] Microsoft 365 / Office 365 (Store & Click-to-Run)
[29] Maps
[30] Get Help
[31] People / Contacts
[32] Dev Home

--- BLOAT ---
[33] Copilot
[34] Cortana
[35] Feedback Hub
[36] Get Started
[37] News
[38] Weather
[39] Solitaire

--- EDGE / WEB ---
[40] Edge WebView2
[41] Web Experience Pack
[42] Bing Search

--- 3D / LEGACY ---
[43] 3D Viewer
[44] Mixed Reality Portal
[45] Print 3D
[46] Paint 3D

--- OTHER ---
[47] Phone Link
[48] Mobile Devices (Cross Device Experience Host)
[49] Family Safety
[50] Windows Backup
[51] Store Ads
[52] Power Automate

[B] Back

Enter an app number:
```

The list above represents the current removal targets defined in the script. The displayed numbering is generated from the configured list.

**Important:** Removing Windows components may affect other features or applications. Review each selection before proceeding.

### 4.2 Mass Removal

Mass removal attempts to remove all apps in the configured target list.

```text
WARNING: This attempts to remove every app in the built-in target list,
for all users and from new profiles.

It also runs the existing special OneDrive/Xbox removal routine afterward.

This may remove features you use. Review the target list first if unsure.

Type NUKE to continue, or press Enter to cancel:
```

This operation is intended for users who understand the potential consequences of removing multiple Windows apps.

### 4.3 Force Removal: OneDrive and Xbox

This separate operation attempts to remove OneDrive and Xbox components, including certain packages and files.

```text
WARNING: This attempts to remove OneDrive and Xbox components,
including some files and packages.

This can affect sync, Xbox features, and other Windows functionality.

Type REMOVE to continue, or press Enter to cancel:
```

### 4.4 App Scanner

The scanner checks configured targets against available Windows app packages, provisioned packages, desktop application registrations and Microsoft Office installation information.

```text
APP SCAN

Checking installed Store apps, provisioned apps,
desktop apps and Microsoft Office.

A provisioned app is prepared for new user profiles;
it is not necessarily installed for the current user.

--- SYSTEM ---
  [INSTALLED] Mircosoft Store
  [NOT FOUND] Xbox

--- PRODUCTIVITY ---
  [INSTALLED] Microsoft 365 / Office 365 (Office Click-to-Run/MSI)
  [NOT FOUND] Outlook New

Installed: 2    Provisioned only: 0    Not found: 2    Unknown: 0
```

The results above are illustrative examples, not a report from an actual computer.

The scanner uses these status types:

- `INSTALLED` — the application was detected.
- `PROVISIONED ONLY` — the package is prepared for new user profiles.
- `NOT FOUND` — the application was not detected by the available checks.
- `UNKNOWN` — the scanner could not verify the state reliably.

### 4.5 View Log

The log displays activity recorded by WinToolKit.

```text
ACTIVITY LOG

[2026-10-28 12:00:00] WinToolKit v1.0.0 started.
[2026-10-28 12:00:01] App scan completed.
[2026-10-28 12:00:02] WinToolKit closed by user.

Current log: ...\WinToolKit\Logs\WinToolKit_2026-10-28_12-00-00.log

Press Enter to return to the menu:
```

The entries and path shown here are examples. Actual log entries depend on your session.

### 4.6 Clear Log

Clearing the log requires explicit confirmation.

```text
This clears the current log file only.

Type CLEAR to continue, or press Enter to cancel:
```

---

## 5. System Information

View information about the current Windows computer.

```text
SYSTEM INFORMATION
============================================================================

SYSTEM

ComputerName : DESKTOP-PC
Windows      : Microsoft Windows 11 Pro
Version      : 10.0.xxxxx
Build        : xxxxx
Architecture : 64-bit
Manufacturer : Example Manufacturer
Model        : Example Model
Processor    : Example Processor
InstalledRAM_GB : 16
PowerShell   : 5.1
Administrator : True

GRAPHICS
Name:   Example Graphics Adapter
Driver: Example Driver Version
VRAM:   8 GB

PHYSICAL DISKS
\\.\PHYSICALDRIVE0 | Example SSD | 1000 GB

VOLUMES / DRIVE LETTERS
C:    Total:  930 GB   Free:  500 GB

Press Enter to return to the menu:
```

All hardware and operating-system values are illustrative. WinToolKit reads the information from the computer on which it is running.

---

## 6. Activity Logs

WinToolKit keeps a log of supported actions, such as application scans, installation launches and removal attempts.

Logs are normally stored inside the toolkit's `Logs` folder.

If the toolkit is running from a location where it cannot write logs, it attempts to use a local fallback folder.

---

## 7. About WinToolKit

```text
ABOUT WINTOOLKIT

WinToolKit by Murdervan
Version: 1.0.0

Purpose: Manage selected built-in Windows apps,
launch personal installers, and view system information.

Platform: Windows 10 and Windows 11
Designed for portable use from a USB drive
where Windows permissions allow it.

[1] Open WinToolKit GitHub Issues
[2] Open README.md
[B] Back to main menu

Select an option:
```

---

## 8. Exit

Selecting `Q` from the main menu closes WinToolKit.

---

## Notes

- This preview is provided for documentation purposes.
- Dynamic lists and system details vary between computers.
- WinToolKit requires administrator permissions for certain operations.
- Review removal confirmations carefully before proceeding.
- Use trusted application installers and official download sources.

**WinToolKit by Murdervan — One toolkit. One menu. Ready when you need it.**


# Thank you for using WinToolKit - <3


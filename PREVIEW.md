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
                                  Version 1.0.0

MAIN MENU
----------------------------------------------
[1] Install Custom Apps
[2] Massgrave - Activate Windows & Office
[3] Remove Apps (Standard MS Apps)
[4] System Info
[5] Log
[6] About WinToolKit v1.0.0
[Q] Quit
----------------------------------------------

Choose (1-6, Q):
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

[O] Open current folder in Explorer   [U] Up   [R] Refresh   [B] Back

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

An internet connection is normally required to retrieve the external script.

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

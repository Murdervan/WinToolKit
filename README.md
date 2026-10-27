# WinToolKit v1.0.0

**A compact Windows maintenance toolkit by Murdervan**

WinToolKit is a menu-driven PowerShell utility for launching personal software installers, managing a defined list of built-in Windows apps, viewing system information, and keeping a local activity log. It is designed for Windows 10 and Windows 11 and can be stored in a regular folder or on a USB drive.

> **Important:** WinToolKit requests administrator privileges when it starts. App removal and installers can make system-wide changes. Read each confirmation prompt carefully and only run software you trust.

## Quick start

1. Download and extract the entire ZIP into one folder. Keep the included files together.
2. Double-click **`RunAsAdmin.bat`**.
3. Approve the Windows User Account Control (UAC) prompt if you want to continue.
4. Use the numbered main menu. Choose **`Q`** to quit.

Start with `RunAsAdmin.bat`, not by double-clicking `WinToolKit.ps1`. The launcher locates the PowerShell script in its own folder and requests elevation. It does not permanently change the machine's PowerShell execution policy.

## Main menu

| Option | What it does |
|---|---|
| **1 — Install Custom Apps** | Browse the `Apps` folder and its subfolders, then launch a supported installer. |
| **2 — Massgrave — Activate Windows & Office** | Connects to the external Microsoft Activation Scripts (MAS) endpoint and runs the script it returns. See the security note below before using it. |
| **3 — Remove Apps (Standard MS Apps)** | Open the removal tools for selecting one listed app, scanning the app list, viewing or clearing logs, or running the broader removal actions. |
| **4 — System Info** | Displays Windows and hardware details, including CPU, RAM, graphics adapters and driver versions, physical disks, and fixed drive letters with total and free space. |
| **5 — Log** | Displays the current WinToolKit activity log. |
| **6 — About WinToolKit v1.0.0** | Shows project information, opens the project issue page, or opens this README. |
| **Q — Quit** | Closes WinToolKit. |

## Installing your own apps

WinToolKit creates an `Apps` folder beside `WinToolKit.ps1` when needed. Put your installers there. You can arrange them into folders to make large collections easier to browse; subfolders are supported.

Example layout:

```text
WinToolKit/
├── RunAsAdmin.bat
├── WinToolKit.ps1
├── README.md
├── Apps/
│   ├── Browsers/
│   │   ├── BrowserSetup.exe
│   │   └── AnotherBrowser.msi
│   ├── Utilities/
│   │   └── UtilitySetup.exe
│   └── Drivers/
│       └── ExamplePackage.msix
└── Logs/
```

Supported installer formats:

- `.exe`
- `.msi`
- `.msix`
- `.appx`
- `.msixbundle`
- `.appxbundle`

In the installer browser, enter a folder number to open it. Use **`U`** to move up, **`B`** to go back to the parent folder (or return to the main menu from the `Apps` root), **`O`** to open the current folder in File Explorer, and **`R`** to refresh the listing. Select an installer and type **`RUN`** when prompted to start it; pressing Enter cancels.

WinToolKit does not install `.zip` archives or arbitrary files as installers. Extract archives yourself and place a supported installer inside `Apps`. The installer may have its own requirements or prompts, and some packages may not be compatible with your Windows edition or device.

## App removal: read before proceeding

The removal menu offers several different actions, including:

- Removing one app from WinToolKit's predefined target list, with confirmation.
- Scanning installed app packages.
- Running a mass-removal sequence across the predefined target list.
- Running the special OneDrive/Xbox removal routine.
- Viewing or clearing the current log.

**Mass removal is the high-impact option.** It can remove listed apps for current users and from Windows' provisioned apps for new profiles. It also runs the special OneDrive/Xbox removal routine. WinToolKit requires you to type **`NUKE`** to confirm this action. Review the target list and make sure you have backups or a recovery plan before proceeding. Do not use it simply to experiment.

Removing a built-in app can affect Windows features or workflows that depend on it. Results vary by Windows version, installed packages, policy, and permissions. WinToolKit cannot guarantee that every removal will succeed or be reversible.

## Massgrave and external scripts

Menu option **2** retrieves code from `https://get.activated.win` and executes the returned content. This requires an internet connection and means code from outside this ZIP is run with the permissions of the elevated PowerShell process.

Only proceed if you have independently checked the source and understand the implications. The upstream project is **Microsoft Activation Scripts (MAS)**:

- Official source repository: <https://github.com/massgravel/Microsoft-Activation-Scripts>
- Project website and documentation: <https://massgrave.dev/>

Always verify the URL and review the upstream documentation before running activation tools. WinToolKit does not provide a Windows or Office licence; users are responsible for complying with applicable licence terms.

## Logs

WinToolKit creates timestamped log files in the `Logs` folder beside the script. The log records selected actions and errors to help with troubleshooting.

If the program cannot write to that location—for example, when the toolkit is on a write-protected USB drive—it attempts to use:

```text
%LOCALAPPDATA%\WinToolKit\Logs
```

If neither location is writable, logging may be unavailable. Log files are local text files; review them before sharing because they may contain file paths, device details, or action history.

## Requirements

- Windows 10 or Windows 11.
- Windows PowerShell 5.1 (included with supported Windows installations).
- Administrator approval to start WinToolKit.
- Internet access for the Massgrave option and for any installer that needs to download files.
- Sufficient free space and write permissions for log files and any installer you run.

Use an up-to-date Windows installation where possible. WinToolKit is designed for Windows, and it has not been validated on Linux, macOS, or non-standard PowerShell hosts.

## Troubleshooting

**The window closes or WinToolKit does not start**

- Extract the ZIP completely; do not run the files from inside the ZIP viewer.
- Confirm that `RunAsAdmin.bat` and `WinToolKit.ps1` are in the same folder.
- Launch `RunAsAdmin.bat` and approve the UAC prompt.
- If the problem persists, open Command Prompt in the extracted folder and run `RunAsAdmin.bat` there so any displayed error remains visible.

**An installer is missing from the list**

- Confirm that it is inside `Apps` or one of its subfolders.
- Confirm that its extension is one of the supported formats listed above.
- Press `R` to refresh the list.

**An installer fails**

Check the installer's own requirements and error message. WinToolKit starts the installer or Windows package installation command; it cannot fix a broken installer, missing prerequisite, incompatible architecture, or Windows policy restriction.

**Massgrave does not start**

Check the internet connection and consult the official MAS documentation and troubleshooting guidance. Do not replace the endpoint with a URL from an unknown source.

**Logs are missing**

Check both the local `Logs` folder and `%LOCALAPPDATA%\WinToolKit\Logs`. Logging can fail if both locations are unavailable or not writable.

## Project and version

- **Project:** WinToolKit
- **Author:** Murdervan
- **Version:** 1.0.0
- **Issue tracker:** <https://github.com/murdervan/WinToolKit/issues>

The version remains **1.0.0** while this build is being developed. Inspect scripts before running them with administrator privileges. A successful ZIP integrity check does not replace testing on the Windows system where you intend to use the toolkit.

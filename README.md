# WinToolKit

### Your Portable Windows Toolkit
**Made by Murdervan**

**One toolkit. One menu. Ready when you need it.**

WinToolKit is a portable PowerShell toolkit designed to make Windows setup and maintenance easier. Keep your essential tools together, carry them on a USB stick, and access useful Windows utilities from one simple menu.

Whether you're setting up a new PC, installing your favourite applications, or removing unwanted built-in apps, WinToolKit helps keep the process organised and straightforward.

No complicated interface. No unnecessary menus. Just practical tools in one place.

![Platform](https://img.shields.io/badge/Platform-Windows-0078D4?style=flat-square&logo=windows)
![Shell](https://img.shields.io/badge/Shell-PowerShell-5391FE?style=flat-square&logo=powershell)
![Version](https://img.shields.io/badge/Version-v1.0.0-2ea44f?style=flat-square)
![USB Friendly](https://img.shields.io/badge/USB-Portable-8957e5?style=flat-square)

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

## 📌 Version

**WinToolKit v1.0.0**

Created by **Murdervan**.

:: WinToolKit by Murdervan
:: Version: 1.0.0
:: Windows 10 / Windows 11

@echo off
setlocal EnableExtensions
title WinToolKit by Murdervan v1.0.0
set "WTK_SCRIPT=%~dp0WinToolKit.ps1"
if not exist "%WTK_SCRIPT%" (
  echo [ERROR] WinToolKit.ps1 was not found beside this launcher.
  echo Extract all files from the ZIP into the same folder.
  pause
  exit /b 1
)
set "WTK_SCRIPT=%WTK_SCRIPT%"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$p=$env:WTK_SCRIPT; $argsLine='-NoLogo -NoProfile -ExecutionPolicy Bypass -File "'+$p+'"'; try { Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argsLine -ErrorAction Stop } catch { Write-Host ('Could not start WinToolKit: '+$_.Exception.Message) -ForegroundColor Red; Read-Host 'Press Enter to close' }"
endlocal


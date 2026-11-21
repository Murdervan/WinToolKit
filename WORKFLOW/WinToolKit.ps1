# WinToolKit by Murdervan
# Version: 1.1.0
# Windows 10 / Windows 11
# PowerShell 5.1 compatible

$ErrorActionPreference = 'Continue'
$script:ToolVersion = '1.1.0'

# Detect the script location. When launched from WORKFLOW, the parent folder
# remains the toolkit root so Apps, Logs, Backups and README stay in place.
$script:ScriptPath = $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($script:ScriptPath)) {
    $script:ScriptPath = $PSCommandPath
}
if ([string]::IsNullOrWhiteSpace($script:ScriptPath)) {
    $script:ToolScriptDirectory = (Get-Location).Path
} else {
    $script:ToolScriptDirectory = Split-Path -Parent $script:ScriptPath
}

if ((Split-Path -Leaf $script:ToolScriptDirectory) -ieq 'WORKFLOW') {
    $script:ToolRoot = Split-Path -Parent $script:ToolScriptDirectory
} else {
    $script:ToolRoot = $script:ToolScriptDirectory
}
if ([string]::IsNullOrWhiteSpace($script:ToolRoot)) {
    $script:ToolRoot = (Get-Location).Path
}

$script:AppsPath = Join-Path $script:ToolRoot 'Apps'
$script:LogsPath = Join-Path $script:ToolRoot 'Logs'
$script:LogFile = $null                 # WinToolKit-wide activity log
$script:RemovalLogFile = $null          # Separate Remove Apps log
$script:LogContext = $null
$script:IssuesUrl = 'https://github.com/murdervan/WinToolKit/issues'
$script:GitHubRepoUrl = 'https://github.com/murdervan/WinToolKit'
$script:GitHubLatestReleaseApi = 'https://api.github.com/repos/murdervan/WinToolKit/releases/latest'

# Keep the classic console compact; ignore hosts that do not expose RawUI sizing.
try {
    $raw = $Host.UI.RawUI
    $raw.WindowTitle = "WinToolKit by Murdervan v$script:ToolVersion"
    $raw.WindowSize = New-Object Management.Automation.Host.Size(88, 30)
    $raw.BufferSize = New-Object Management.Automation.Host.Size(88, 3000)
} catch {}

$Host.UI.RawUI.WindowTitle = "WinToolKit by Murdervan v$script:ToolVersion"
try {
    $Host.UI.RawUI.BackgroundColor = 'Black'
    $Host.UI.RawUI.ForegroundColor = 'Green'
    Clear-Host
} catch {}

# Best-effort console appearance tweaks:
# - Slightly reduce the font in the classic Windows Console Host.
# - Center the visible console window on the primary display.
# Windows Terminal manages its own font and window placement, so these
# legacy console APIs may be ignored when WinToolKit runs inside Terminal.
try {
    if (-not ('WinToolKit.NativeConsole' -as [type])) {
        $nativeConsoleCode = @'
using System;
using System.Runtime.InteropServices;
namespace WinToolKit {
    public static class NativeConsole {
        [StructLayout(LayoutKind.Sequential)]
        public struct COORD {
            public short X;
            public short Y;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct CONSOLE_FONT_INFOEX {
            public uint cbSize;
            public uint nFont;
            public COORD dwFontSize;
            public int FontFamily;
            public int FontWeight;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
            public string FaceName;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct RECT {
            public int Left;
            public int Top;
            public int Right;
            public int Bottom;
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr GetStdHandle(int nStdHandle);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFOEX lpConsoleCurrentFontEx);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFOEX lpConsoleCurrentFontEx);

        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool IsWindowVisible(IntPtr hWnd);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool BringWindowToTop(IntPtr hWnd);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern int GetSystemMetrics(int nIndex);
    }
}
'@
        Add-Type -TypeDefinition $nativeConsoleCode -ErrorAction Stop
    }

    # Shrink the font slightly where the classic console exposes font controls.
    $stdoutHandle = [WinToolKit.NativeConsole]::GetStdHandle(-11)
    if ($stdoutHandle -ne [IntPtr]::Zero) {
        $font = New-Object 'WinToolKit.NativeConsole+CONSOLE_FONT_INFOEX'
        $font.cbSize = [uint32][Runtime.InteropServices.Marshal]::SizeOf([type]'WinToolKit.NativeConsole+CONSOLE_FONT_INFOEX')
        $font.FaceName = ''
        if ([WinToolKit.NativeConsole]::GetCurrentConsoleFontEx($stdoutHandle, $false, [ref]$font)) {
            if ($font.dwFontSize.Y -gt 14) {
                $fontSize = $font.dwFontSize
                $fontSize.Y = [int16]14
                $font.dwFontSize = $fontSize
                [void][WinToolKit.NativeConsole]::SetCurrentConsoleFontEx($stdoutHandle, $false, [ref]$font)
            }
        }
    }

    # Center only a visible classic console window; do nothing in hosts such as Windows Terminal.
    $consoleWindow = [WinToolKit.NativeConsole]::GetConsoleWindow()
    if ($consoleWindow -ne [IntPtr]::Zero -and [WinToolKit.NativeConsole]::IsWindowVisible($consoleWindow)) {
        $rect = New-Object 'WinToolKit.NativeConsole+RECT'
        if ([WinToolKit.NativeConsole]::GetWindowRect($consoleWindow, [ref]$rect)) {
            $windowWidth = $rect.Right - $rect.Left
            $windowHeight = $rect.Bottom - $rect.Top
            $screenWidth = [WinToolKit.NativeConsole]::GetSystemMetrics(0)
            $screenHeight = [WinToolKit.NativeConsole]::GetSystemMetrics(1)
            if ($windowWidth -gt 0 -and $windowHeight -gt 0 -and $screenWidth -ge $windowWidth -and $screenHeight -ge $windowHeight) {
                $left = [int][Math]::Max(0, [Math]::Floor(($screenWidth - $windowWidth) / 2.0))
                $top = [int][Math]::Max(0, [Math]::Floor(($screenHeight - $windowHeight) / 2.0))
                # Move the console to the top and allow it to become active.
                # NOSIZE keeps the dimensions established above.
                $flags = [uint32]0x0001
                [void][WinToolKit.NativeConsole]::SetWindowPos($consoleWindow, [IntPtr]::Zero, $left, $top, 0, 0, $flags)
            }

            # Restore and activate the console so the main menu is ready for keyboard input.
            [void][WinToolKit.NativeConsole]::ShowWindow($consoleWindow, 9) # SW_RESTORE
            [void][WinToolKit.NativeConsole]::BringWindowToTop($consoleWindow)
            [void][WinToolKit.NativeConsole]::SetForegroundWindow($consoleWindow)
        }
    }
} catch {
    # Appearance changes must never prevent WinToolKit from starting.
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Initialize-Log {
    $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    try {
        if (-not (Test-Path -LiteralPath $script:LogsPath)) {
            New-Item -ItemType Directory -Path $script:LogsPath -Force -ErrorAction Stop | Out-Null
        }
        $script:LogFile = Join-Path $script:LogsPath "WinToolKit_$stamp.log"
        $script:RemovalLogFile = Join-Path $script:LogsPath "RemoveApps_$stamp.log"
        New-Item -ItemType File -Path $script:LogFile -Force -ErrorAction Stop | Out-Null
        New-Item -ItemType File -Path $script:RemovalLogFile -Force -ErrorAction Stop | Out-Null
    } catch {
        # USB may be write-protected. Fall back to a user-local log location.
        try {
            $fallback = Join-Path $env:LOCALAPPDATA 'WinToolKit\Logs'
            New-Item -ItemType Directory -Path $fallback -Force -ErrorAction Stop | Out-Null
            $script:LogFile = Join-Path $fallback "WinToolKit_$stamp.log"
            $script:RemovalLogFile = Join-Path $fallback "RemoveApps_$stamp.log"
            New-Item -ItemType File -Path $script:LogFile -Force -ErrorAction Stop | Out-Null
            New-Item -ItemType File -Path $script:RemovalLogFile -Force -ErrorAction Stop | Out-Null
            Write-Host '[NOTICE] USB logging is unavailable. Logs will be saved locally:' -ForegroundColor Yellow
            Write-Host "         $fallback" -ForegroundColor Yellow
        } catch {
            $script:LogFile = $null
            $script:RemovalLogFile = $null
            Write-Host '[WARNING] Logging is unavailable because no writable log location was found.' -ForegroundColor Yellow
        }
    }
}

function Write-Log {
    param([Parameter(Mandatory=$true)][string]$Message)
    $entry = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message

    # The main log always records WinToolKit-wide activity.
    if ($script:LogFile) {
        try { Add-Content -LiteralPath $script:LogFile -Value $entry -Encoding UTF8 -ErrorAction Stop }
        catch { Write-Host '[WARNING] Could not write to the WinToolKit activity log.' -ForegroundColor Yellow }
    }

    # While a Remove Apps action is running, mirror its entries to a separate log.
    if ($script:LogContext -eq 'RemoveApps' -and $script:RemovalLogFile) {
        try { Add-Content -LiteralPath $script:RemovalLogFile -Value $entry -Encoding UTF8 -ErrorAction Stop }
        catch {
            $script:RemovalLogFile = $null
            Write-Host '[WARNING] Could not write to the Remove Apps log.' -ForegroundColor Yellow
        }
    }
}

function Show-Banner {
    Clear-Host
    try { $Host.UI.RawUI.WindowTitle = "WinToolKit by Murdervan v$script:ToolVersion" } catch {}

    # Leave one blank console row above the full logo so its top is not clipped.
    Write-Host ''

    # ANSI Shadow-style "Win Tool Kit" logo provided by Murdervan.
    # Keep each line literal: this preserves Unicode box characters and spacing.
    $logo = @(
        '██╗    ██╗██╗███╗   ██╗    ████████╗ ██████╗  ██████╗ ██╗         ██╗  ██╗██╗████████╗'
        '██║    ██║██║████╗  ██║    ╚══██╔══╝██╔═══██╗██╔═══██╗██║         ██║ ██╔╝██║╚══██╔══╝'
        '██║ █╗ ██║██║██╔██╗ ██║       ██║   ██║   ██║██║   ██║██║         █████╔╝ ██║   ██║   '
        '██║███╗██║██║██║╚██╗██║       ██║   ██║   ██║██║   ██║██║         ██╔═██╗ ██║   ██║   '
        '╚███╔███╔╝██║██║ ╚████║       ██║   ╚██████╔╝╚██████╔╝███████╗    ██║  ██╗██║   ██║   '
        ' ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝    ╚═╝  ╚═╝╚═╝   ╚═╝   '
    )
    $consoleWidth = 88
    $logoWidth = ($logo | ForEach-Object { $_.TrimEnd().Length } | Measure-Object -Maximum).Maximum
    $logoPad = [int][Math]::Floor(($consoleWidth - $logoWidth) / 2.0)

    foreach ($line in $logo) {
        Write-Host ((' ' * [Math]::Max(0, $logoPad)) + $line.TrimEnd()) -ForegroundColor Cyan
    }

    $byLine = 'by Murdervan'
    $versionLine = "Version $script:ToolVersion"
    $byIndent = [int][Math]::Floor(($consoleWidth - $byLine.Length) / 2.0)
    $versionIndent = [int][Math]::Floor(($consoleWidth - $versionLine.Length) / 2.0)
    Write-Host ((' ' * [Math]::Max(0, $byIndent)) + $byLine) -ForegroundColor Green
    Write-Host ((' ' * [Math]::Max(0, $versionIndent)) + $versionLine) -ForegroundColor Green
    Write-Host ''
}

function Pause-Return {
    Write-Host ''
    [void](Read-Host 'Press Enter to return to the menu')
}

# Original APP KILLER category targets retained.
$script:Categories = [ordered]@{
    'SYSTEM' = @(
        @{N='Calculator'; P='Calculator'},
        @{N='Paint'; P='Paint'},
        @{N='Clock'; P='WindowsAlarms'},
        @{N='Windows Store'; P='WindowsStore'},
        @{N='Store Core'; P='Store'},
        @{N='OneDrive'; P='OneDrive'},
        @{N='Quick Assist'; P='QuickAssist'}
    )
    'MEDIA' = @(
        @{N='Media Player'; P='MediaPlayer'},
        @{N='Music'; P='ZuneMusic'},
        @{N='Camera'; P='WindowsCamera'},
        @{N='Voice Recorder'; P='SoundRecorder'},
        @{N='Clipchamp'; P='Clipchamp'},
        @{N='Films & TV'; P='ZuneVideo'}
    )
    'XBOX' = @(
        @{N='Xbox App'; P='XboxApp'},
        @{N='Xbox Game Bar'; P='XboxGamingOverlay'},
        @{N='Xbox Identity Provider'; P='XboxIdentityProvider'},
        @{N='Xbox Speech To Text'; P='XboxSpeechToTextOverlay'},
        @{N='Xbox TCUI'; P='Xbox.TCUI'}
    )
    'COMMUNICATION' = @(
        @{N='Teams Personal'; P='Teams'},
        @{N='Skype'; P='SkypeApp'},
        @{N='Mail & Calendar'; P='windowscommunicationsapps'},
        @{N='Outlook New'; P='OutlookForWindows'},
        @{N='LinkedIn'; P='LinkedIn'}
    )
    'PRODUCTIVITY' = @(
        @{N='To Do'; P='Todos'},
        @{N='Sticky Notes'; P='StickyNotes'},
        @{N='OneNote'; P='OneNote'},
        @{N='Office Hub'; P='MicrosoftOfficeHub'},
        @{N='Microsoft 365 / Office 365 (Store & Click-to-Run)'; P='OfficeClickToRun'},
        @{N='Maps'; P='WindowsMaps'},
        @{N='Get Help'; P='GetHelp'},
        @{N='People / Contacts'; P='People'},
        @{N='Dev Home'; P='DevHome'}
    )
    'BLOAT' = @(
        @{N='Copilot'; P='Copilot'},
        @{N='Cortana'; P='Cortana'},
        @{N='Feedback Hub'; P='FeedbackHub'},
        @{N='Get Started'; P='Getstarted'},
        @{N='News'; P='News'},
        @{N='Weather'; P='BingWeather'},
        @{N='Solitaire'; P='MicrosoftSolitaireCollection'}
    )
    'EDGE / WEB' = @(
        @{N='Edge WebView2'; P='WebView2'},
        @{N='Web Experience Pack'; P='WebExperience'},
        @{N='Bing Search'; P='Bing'}
    )
    '3D / LEGACY' = @(
        @{N='3D Viewer'; P='3DViewer'},
        @{N='Mixed Reality Portal'; P='HolographicFirstRun'},
        @{N='Print 3D'; P='Print3D'},
        @{N='Paint 3D'; P='MSPaint'}
    )
    # EXTENSIONS category intentionally empty: Web Media Extensions is excluded from removal.
    'OTHER' = @(
        @{N='Phone Link'; P='YourPhone'},
        @{N='Mobile Devices (Cross Device Experience Host)'; P='CrossDevice'},
        @{N='Family Safety'; P='MicrosoftFamily'},
        @{N='Windows Backup'; P='WindowsBackup'},
        @{N='Store Ads'; P='StorePurchaseApp'},
        @{N='Power Automate'; P='Microsoft.PowerAutomateDesktop'}
    )
}


function Invoke-Microsoft365Removal {
    # Microsoft Store editions are Appx packages; traditional Microsoft 365/Office
    # editions use Click-to-Run and expose an uninstall command in the registry.
    $removed = $false
    $failed = $false

    try {
        $storePackages = @(Get-AppxPackage -AllUsers -Name 'Microsoft.Office.Desktop' -ErrorAction Stop)
        foreach ($app in $storePackages) {
            try {
                Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop
                $removed = $true
                Write-Log "Removed Microsoft 365 Store package: $($app.PackageFullName)"
            } catch {
                $failed = $true
                Write-Log "ERROR removing Microsoft 365 Store package $($app.PackageFullName): $($_.Exception.Message)"
                Write-Host "Could not remove Store package $($app.PackageFullName): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    } catch {
        $failed = $true
        Write-Log "ERROR checking Microsoft 365 Store package: $($_.Exception.Message)"
    }

    try {
        $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction Stop | Where-Object {
            $_.DisplayName -like '*Microsoft.Office.Desktop*' -or $_.PackageName -like '*Microsoft.Office.Desktop*'
        })
        foreach ($app in $provisioned) {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $app.PackageName -ErrorAction Stop | Out-Null
                $removed = $true
                Write-Log "Removed provisioned Microsoft 365 Store package: $($app.PackageName)"
            } catch {
                $failed = $true
                Write-Log "ERROR removing provisioned Microsoft 365 package $($app.PackageName): $($_.Exception.Message)"
                Write-Host "Could not remove provisioned package $($app.PackageName): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    } catch {
        $failed = $true
        Write-Log "ERROR checking provisioned Microsoft 365 package: $($_.Exception.Message)"
    }

    $registryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $officeEntries = @()
    foreach ($path in $registryPaths) {
        try {
            $officeEntries += @(Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {
                $_.DisplayName -match '(?i)(Microsoft 365|Office 365|Microsoft Office)' -and
                $_.UninstallString -match '(?i)OfficeClickToRun\.exe' -and
                $_.UninstallString -match '(?i)productstoremove='
            })
        } catch {
            Write-Log "Could not read Office uninstall entries from $path : $($_.Exception.Message)"
        }
    }

    $uniqueCommands = @($officeEntries | Where-Object { $_.UninstallString } | Group-Object -Property UninstallString | ForEach-Object { $_.Group[0] })
    foreach ($entry in $uniqueCommands) {
        $uninstall = [string]$entry.UninstallString
        $match = [regex]::Match($uninstall, '(?i)^\s*"?(.+?OfficeClickToRun\.exe)"?\s*(.*)$')
        if (-not $match.Success) {
            $failed = $true
            Write-Log "Could not parse Office Click-to-Run uninstall command for $($entry.DisplayName)"
            continue
        }
        $exe = $match.Groups[1].Value.Trim([char[]]@('"', ' '))
        $arguments = $match.Groups[2].Value
        if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
            $failed = $true
            Write-Log "Office Click-to-Run executable was not found: $exe"
            Write-Host "Office uninstall executable was not found: $exe" -ForegroundColor Yellow
            continue
        }
        try {
            Write-Host "Starting the registered Office removal for: $($entry.DisplayName)" -ForegroundColor Yellow
            Write-Log "Starting Office Click-to-Run removal: $($entry.DisplayName)"
            $proc = Start-Process -FilePath $exe -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop
            Write-Host "Office removal process ended with exit code $($proc.ExitCode)." -ForegroundColor Cyan
            Write-Log "Office removal process ended with exit code $($proc.ExitCode): $($entry.DisplayName)"
            $removed = $true
        } catch {
            $failed = $true
            Write-Log "ERROR running Office Click-to-Run removal for $($entry.DisplayName): $($_.Exception.Message)"
            Write-Host "Could not start Office removal: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    if ($removed) {
        Write-Host 'Microsoft 365 / Office removal command(s) have been run. Check Windows and the log for the final result.' -ForegroundColor Green
        Write-Log 'Microsoft 365 / Office removal sequence completed or attempted.'
    } elseif ($failed) {
        Write-Host 'The Office check/removal encountered an issue. Check the log; this can also mean Office uses another installation type.' -ForegroundColor Yellow
    } else {
        Write-Host 'No Microsoft 365 / Office Store or Click-to-Run installation was found.' -ForegroundColor DarkYellow
        Write-Log 'Microsoft 365 / Office not found.'
    }
}

function Test-ProtectedRemovalTarget {
    param(
        [string]$Name,
        [string]$Package,
        [string[]]$DetectedIdentifiers = @()
    )

    # These apps must not be offered for removal or removed as a side effect of a broad match.
    $protectedDisplayNames = @(
        'Photos', 'Photos / Billeder', 'Billeder',
        'HEIF Image Extensions', 'Raw Image Extension',
        'Snipping Tool', 'Notepad', 'Notepad / Notesblok', 'Notesblok'
    )
    if ($Name -and ($protectedDisplayNames -contains $Name.Trim())) { return $true }

    # Appx package identifiers appear as either the short package name, family name or full name.
    $protectedPatterns = @(
        '(?i)^Microsoft\.Windows\.Photos(?:_|$)',
        '(?i)^(?:Microsoft\.)?HEIFImageExtension(?:_|$)',
        '(?i)^(?:Microsoft\.)?RawImageExtension(?:_|$)',
        '(?i)^(?:Microsoft\.)?ScreenSketch(?:_|$)',
        '(?i)^(?:Microsoft\.)?WindowsNotepad(?:_|$)'
    )
    foreach ($identifier in (@($Package) + @($DetectedIdentifiers))) {
        if ([string]::IsNullOrWhiteSpace([string]$identifier)) { continue }
        foreach ($pattern in $protectedPatterns) {
            if ([string]$identifier -match $pattern) { return $true }
        }
    }
    return $false
}

function Remove-App {
    param(
        [string]$Name,
        [string]$Package,
        [switch]$SkipConfirmation
    )

    if (Test-ProtectedRemovalTarget -Name $Name -Package $Package) {
        Write-Host "Blocked: $Name is protected and is not removable through WinToolKit." -ForegroundColor Cyan
        Write-Log "BLOCKED protected removal target: $Name ($Package)"
        return
    }

    if (-not $SkipConfirmation) {
        Write-Host ''
        Write-Host "App: $Name" -ForegroundColor Yellow
        Write-Host 'This action attempts to remove matching app packages for all users and remove matching provisioned packages.' -ForegroundColor Yellow
        $confirm = Read-Host 'Type YES to continue, or press Enter to cancel'
        if ($confirm -cne 'YES') {
            Write-Log "CANCELLED removal: $Name"
            Write-Host 'Removal cancelled.' -ForegroundColor Cyan
            return
        }
    }

    if ($Package -eq 'OfficeClickToRun') {
        Invoke-Microsoft365Removal
        return
    }

    $removed = $false
    $failed = $false
    try {
        $installed = @(Get-AppxPackage -AllUsers -ErrorAction Stop)
    } catch {
        $installed = @()
        $failed = $true
        Write-Log "ERROR listing installed packages for $Name : $($_.Exception.Message)"
    }
    try {
        $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction Stop)
    } catch {
        $provisioned = @()
        $failed = $true
        Write-Log "ERROR listing provisioned packages for $Name : $($_.Exception.Message)"
    }

    foreach ($app in $installed | Where-Object {
        $_.Name -like "*$Package*" -or
        $_.PackageFamilyName -like "*$Package*" -or
        $_.PackageFullName -like "*$Package*"
    }) {
        if (Test-ProtectedRemovalTarget -Name $app.Name -Package $Package -DetectedIdentifiers @($app.Name, $app.PackageFamilyName, $app.PackageFullName)) {
            Write-Log "SKIPPED protected installed package: $($app.PackageFullName)"
            Write-Host "Protected package skipped: $($app.Name)" -ForegroundColor Cyan
            continue
        }
        try {
            Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop
            $removed = $true
            Write-Log "Removed installed package for $Name : $($app.PackageFullName)"
        } catch {
            $failed = $true
            Write-Log "ERROR removing installed package for $Name : $($_.Exception.Message)"
            Write-Host "Could not remove $($app.PackageFullName): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    foreach ($app in $provisioned | Where-Object {
        $_.DisplayName -like "*$Package*" -or $_.PackageName -like "*$Package*"
    }) {
        if (Test-ProtectedRemovalTarget -Name $app.DisplayName -Package $Package -DetectedIdentifiers @($app.DisplayName, $app.PackageName)) {
            Write-Log "SKIPPED protected provisioned package: $($app.PackageName)"
            Write-Host "Protected provisioned package skipped: $($app.DisplayName)" -ForegroundColor Cyan
            continue
        }
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $app.PackageName -ErrorAction Stop | Out-Null
            $removed = $true
            Write-Log "Removed provisioned package for $Name : $($app.PackageName)"
        } catch {
            $failed = $true
            Write-Log "ERROR removing provisioned package for $Name : $($_.Exception.Message)"
            Write-Host "Could not remove provisioned package $($app.PackageName): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    if ($removed) {
        Write-Host 'Removal command completed for one or more matching packages.' -ForegroundColor Green
        Write-Log "REMOVAL COMPLETED: $Name"
    } elseif ($failed) {
        Write-Host 'The operation encountered errors. Check the log for details.' -ForegroundColor Yellow
    } else {
        Write-Host 'No matching installed or provisioned packages were found.' -ForegroundColor DarkYellow
        Write-Log "NOT FOUND: $Name"
    }
}

function Force-Remove-SpecialApps {
    Write-Host ''
    Write-Host 'WARNING: This attempts to remove OneDrive and Xbox components, including some files and packages.' -ForegroundColor Red
    Write-Host 'This can affect sync, Xbox features, and other Windows functionality.' -ForegroundColor Yellow
    $confirm = Read-Host 'Type REMOVE to continue, or press Enter to cancel'
    if ($confirm -cne 'REMOVE') {
        Write-Log 'Cancelled special removal of OneDrive and Xbox.'
        Write-Host 'Action cancelled.' -ForegroundColor Cyan
        return
    }

    Write-Host '[1/2] Attempting to remove OneDrive...' -ForegroundColor Yellow
    try { Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch {}

    $oneDriveSystem = Join-Path $env:SystemRoot 'SysWOW64\OneDriveSetup.exe'
    $oneDriveSystem32 = Join-Path $env:SystemRoot 'System32\OneDriveSetup.exe'
    foreach ($setup in @($oneDriveSystem, $oneDriveSystem32)) {
        if (Test-Path -LiteralPath $setup) {
            try {
                $proc = Start-Process -FilePath $setup -ArgumentList '/uninstall' -Wait -PassThru -ErrorAction Stop
                Write-Log "OneDrive uninstaller exited with code $($proc.ExitCode): $setup"
            } catch {
                Write-Log "ERROR running OneDrive uninstaller $setup : $($_.Exception.Message)"
                Write-Host "OneDrive uninstaller error: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }

    foreach ($path in @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\OneDrive'),
        (Join-Path $env:PROGRAMDATA 'Microsoft OneDrive')
    )) {
        try {
            if (Test-Path -LiteralPath $path) {
                Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
                Write-Log "Removed OneDrive leftover path: $path"
            }
        } catch {
            Write-Log "ERROR removing OneDrive path $path : $($_.Exception.Message)"
            Write-Host "Could not remove $path : $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    Write-Host '[2/2] Attempting to remove Xbox packages...' -ForegroundColor Yellow
    $xboxPackages = @(
        'Microsoft.GamingApp',
        'Microsoft.XboxApp',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.XboxIdentityProvider',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.Xbox.TCUI'
    )
    foreach ($pkg in $xboxPackages) {
        try {
            Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like "*$pkg*" -or $_.PackageFamilyName -like "*$pkg*" } |
                ForEach-Object {
                    try {
                        Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop
                        Write-Log "Force removed Xbox installed package: $($_.PackageFullName)"
                    } catch {
                        Write-Log "ERROR removing Xbox package $($_.PackageFullName): $($_.Exception.Message)"
                    }
                }
        } catch {}
        try {
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like "*$pkg*" -or $_.PackageName -like "*$pkg*" } |
                ForEach-Object {
                    try {
                        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop | Out-Null
                        Write-Log "Force removed Xbox provisioned package: $($_.PackageName)"
                    } catch {
                        Write-Log "ERROR removing Xbox provisioned package $($_.PackageName): $($_.Exception.Message)"
                    }
                }
        } catch {}
    }
    Write-Log 'Completed OneDrive/Xbox special removal attempt.'
    Write-Host 'Special removal attempt finished. Review the log for individual results.' -ForegroundColor Green
}

function Get-FlatAppList {
    $list = @()
    foreach ($catName in $script:Categories.Keys) {
        foreach ($app in $script:Categories[$catName]) {
            $list += [pscustomobject]@{
                Category = $catName
                Name = $app.N
                Package = $app.P
            }
        }
    }
    return $list
}

function Show-AppSelection {
    $items = @(Get-FlatAppList)
    while ($true) {
        Clear-Host
        Write-Host 'REMOVE ONE APP' -ForegroundColor Green
        Write-Host 'The existing removal logic is retained. A confirmation is required for each app.' -ForegroundColor Gray
        Write-Host ''
        $indexMap = @{}
        for ($i = 0; $i -lt $items.Count; $i++) {
            $number = $i + 1
            if ($i -eq 0 -or $items[$i].Category -ne $items[$i-1].Category) {
                Write-Host "`n--- $($items[$i].Category) ---" -ForegroundColor Cyan
            }
            Write-Host ('[{0}] {1}' -f $number, $items[$i].Name)
            $indexMap[$number] = $items[$i]
        }
        Write-Host ''
        Write-Host '[B] Back' -ForegroundColor Yellow
        $sel = Read-Host 'Enter an app number'
        if ($sel -match '^[bB]$') {
            # This is a fixed app list, not a folder browser: always return to the removal menu.
            return
        }
        $number = 0
        if ([int]::TryParse($sel, [ref]$number) -and $indexMap.ContainsKey($number)) {
            $app = $indexMap[$number]
            Remove-App -Name $app.Name -Package $app.Package
            # Return directly to the list so another app can be selected without an extra Enter.
        } else {
            Write-Host 'Invalid selection.' -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}

function Invoke-MassRemoval {
    Write-Host ''
    Write-Host 'WARNING: This attempts to remove every app in the built-in target list, for all users and from new profiles.' -ForegroundColor Red
    Write-Host 'It also runs the existing special OneDrive/Xbox removal routine afterward.' -ForegroundColor Yellow
    Write-Host 'This may remove features you use. Review the target list first if unsure.' -ForegroundColor Yellow
    $confirm = Read-Host 'Type NUKE to continue, or press Enter to cancel'
    if ($confirm -cne 'NUKE') {
        Write-Log 'Cancelled mass app removal.'
        Write-Host 'Mass removal cancelled.' -ForegroundColor Cyan
        return
    }
    foreach ($cat in $script:Categories.Keys) {
        foreach ($app in $script:Categories[$cat]) {
            Remove-App -Name $app.N -Package $app.P -SkipConfirmation
        }
    }
    Force-Remove-SpecialApps
    Write-Log 'Mass removal sequence finished.'
    Pause-Return
}

function Show-RemovalMenu {
    while ($true) {
        Clear-Host
        Write-Host 'REMOVE APPS' -ForegroundColor Green
        Write-Host 'Existing removal features are retained.' -ForegroundColor Gray
        Write-Host ''
        Write-Host '[1] Remove one app'
        Write-Host '[2] Mass removal of all listed apps'
        Write-Host '[3] Force removal: OneDrive and Xbox'
        Write-Host '[4] Scan app list'
        Write-Host '[5] View Remove Apps log'
        Write-Host '[6] Clear Remove Apps log'
        Write-Host '[B] Back to main menu' -ForegroundColor Yellow
        Write-Host ''
        $choice = (Read-Host 'Select an option').Trim()
        $previousLogContext = $script:LogContext
        $script:LogContext = 'RemoveApps'
        try {
            Write-Log "Remove Apps menu selection: $choice"
            switch ($choice.ToUpperInvariant()) {
                '1' { Show-AppSelection }
                '2' { Invoke-MassRemoval }
                '3' { Force-Remove-SpecialApps; Pause-Return }
                '4' { Show-AppScan }
                '5' { Show-Log -ReturnToRemovalMenu }
                '6' { Clear-Log }
                'B' { return }
                default { Write-Host 'Invalid selection.' -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
            }
        } finally {
            $script:LogContext = $previousLogContext
        }
    }
}

function Get-AppScanPackagePatterns {
    # Exact package-name aliases for targets whose package identity does not
    # contain the short label as a separate token (e.g. WindowsCalculator).
    return @{
        'Calculator' = @('(?i)^Microsoft\.WindowsCalculator(?:_|$)')
        'Paint' = @('(?i)^Microsoft\.Paint(?:_|$)')
        'Clock' = @('(?i)^Microsoft\.WindowsAlarms(?:_|$)', '(?i)^Microsoft\.WindowsClock(?:_|$)')
        'Windows Store' = @('(?i)^Microsoft\.WindowsStore(?:_|$)')
        'Store Core' = @('(?i)^Microsoft\.StorePurchaseApp(?:_|$)')
        'OneDrive' = @('(?i)^Microsoft\.OneDrive(?:_|$)', '(?i)^Microsoft\.OneDriveSync(?:_|$)')
        'Quick Assist' = @('(?i)^MicrosoftCorporationII\.QuickAssist(?:_|$)', '(?i)^Microsoft\.QuickAssist(?:_|$)')
        'Media Player' = @('(?i)^Microsoft\.Media\.Player(?:_|$)', '(?i)^Microsoft\.ZuneMusic(?:_|$)')
        'Music' = @('(?i)^Microsoft\.ZuneMusic(?:_|$)')
        'Camera' = @('(?i)^Microsoft\.WindowsCamera(?:_|$)')
        'Voice Recorder' = @('(?i)^Microsoft\.WindowsSoundRecorder(?:_|$)', '(?i)^Microsoft\.SoundRecorder(?:_|$)')
        'Clipchamp' = @('(?i)^Clipchamp\.Clipchamp(?:_|$)', '(?i)^Microsoft\.Clipchamp(?:_|$)')
        'Films & TV' = @('(?i)^Microsoft\.ZuneVideo(?:_|$)')
        'Xbox App' = @('(?i)^Microsoft\.GamingApp(?:_|$)', '(?i)^Microsoft\.XboxApp(?:_|$)')
        'Xbox Game Bar' = @('(?i)^Microsoft\.XboxGamingOverlay(?:_|$)')
        'Xbox Identity Provider' = @('(?i)^Microsoft\.XboxIdentityProvider(?:_|$)')
        'Xbox Speech To Text' = @('(?i)^Microsoft\.XboxSpeechToTextOverlay(?:_|$)')
        'Xbox TCUI' = @('(?i)^Microsoft\.Xbox\.TCUI(?:_|$)')
        'Teams Personal' = @('(?i)^(?:MSTeams|MicrosoftTeams)(?:_|$)')
        'Skype' = @('(?i)^Microsoft\.SkypeApp(?:_|$)', '(?i)^Microsoft\.Skype(?:_|$)')
        'Mail & Calendar' = @('(?i)^microsoft\.windowscommunicationsapps(?:_|$)')
        'Outlook New' = @('(?i)^Microsoft\.OutlookForWindows(?:_|$)', '(?i)^Microsoft\.Outlook(?:_|$)')
        'LinkedIn' = @('(?i)^LinkedInforWindows(?:_|$)', '(?i)^Microsoft\.LinkedIn(?:_|$)')
        'To Do' = @('(?i)^Microsoft\.Todos(?:_|$)')
        'Sticky Notes' = @('(?i)^Microsoft\.MicrosoftStickyNotes(?:_|$)')
        'OneNote' = @('(?i)^Microsoft\.Office\.OneNote(?:_|$)', '(?i)^Microsoft\.OneNote(?:_|$)')
        'Office Hub' = @('(?i)^Microsoft\.MicrosoftOfficeHub(?:_|$)')
        'Microsoft 365 / Office 365 (Store & Click-to-Run)' = @('(?i)^Microsoft\.Office\.Desktop(?:_|$)')
        'Maps' = @('(?i)^Microsoft\.WindowsMaps(?:_|$)')
        'Get Help' = @('(?i)^Microsoft\.GetHelp(?:_|$)')
        'People / Contacts' = @('(?i)^Microsoft\.People(?:_|$)')
        'Dev Home' = @('(?i)^Microsoft\.DevHome(?:_|$)')
        'Copilot' = @('(?i)^Microsoft\.Copilot(?:_|$)', '(?i)^MicrosoftWindows\.Client\.Copilot(?:_|$)')
        'Cortana' = @('(?i)^Microsoft\.549981C3F5F10(?:_|$)', '(?i)^Microsoft\.Windows\.Cortana(?:_|$)')
        'Feedback Hub' = @('(?i)^Microsoft\.WindowsFeedbackHub(?:_|$)')
        'Get Started' = @('(?i)^Microsoft\.Getstarted(?:_|$)')
        'News' = @('(?i)^Microsoft\.BingNews(?:_|$)')
        'Weather' = @('(?i)^Microsoft\.BingWeather(?:_|$)')
        'Solitaire' = @('(?i)^Microsoft\.MicrosoftSolitaireCollection(?:_|$)')
        'Web Experience Pack' = @('(?i)^MicrosoftWindows\.Client\.WebExperience(?:_|$)')
        'Bing Search' = @('(?i)^Microsoft\.BingSearch(?:_|$)')
        '3D Viewer' = @('(?i)^Microsoft\.Microsoft3DViewer(?:_|$)')
        'Mixed Reality Portal' = @('(?i)^Microsoft\.MixedReality\.Portal(?:_|$)')
        'Print 3D' = @('(?i)^Microsoft\.Print3D(?:_|$)')
        'Paint 3D' = @('(?i)^Microsoft\.MSPaint(?:_|$)')
        'Phone Link' = @('(?i)^Microsoft\.YourPhone(?:_|$)')
        'Mobile Devices (Cross Device Experience Host)' = @('(?i)^MicrosoftWindows\.CrossDevice(?:_|$)', '(?i)^Microsoft\.Windows\.CrossDevice(?:_|$)')
        'Family Safety' = @('(?i)^MicrosoftCorporationII\.MicrosoftFamily(?:_|$)', '(?i)^Microsoft\.MicrosoftFamily(?:_|$)')
        'Windows Backup' = @('(?i)^Microsoft\.WindowsBackup(?:_|$)')
        'Store Ads' = @('(?i)^Microsoft\.StorePurchaseApp(?:_|$)')
        'Power Automate' = @('(?i)^Microsoft\.PowerAutomateDesktop(?:_|$)')
    }
}

function Test-AppScanIdentifier {
    param(
        [Parameter(Mandatory=$true)]$App,
        [AllowNull()][string]$Identifier,
        [hashtable]$PackagePatterns
    )
    if ([string]::IsNullOrWhiteSpace($Identifier)) { return $false }

    if ($PackagePatterns.ContainsKey([string]$App.N)) {
        foreach ($pattern in $PackagePatterns[[string]$App.N]) {
            if ($Identifier -match $pattern) { return $true }
        }
    }

    # Avoid a generic "Store" substring hit: it would make Windows Store,
    # Store Core and Store Ads all appear installed for the same unrelated match.
    if ([string]$App.P -eq 'Store' -or [string]$App.P -eq 'OfficeClickToRun') { return $false }

    $token = [regex]::Escape([string]$App.P)
    if ($Identifier -match ("(?i)(?:^|[._]){0}(?:[._]|$)" -f $token)) { return $true }
    return $false
}

function Get-AppScanRegistryEntries {
    $entries = @()
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($path in $paths) {
        try {
            $entries += @(Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {
                -not [string]::IsNullOrWhiteSpace([string]$_.DisplayName)
            })
        } catch {
            Write-Log "Could not read installed-program registry entries at $path : $($_.Exception.Message)"
        }
    }
    return $entries
}

function Get-AppScanOfficeState {
    param([object[]]$RegistryEntries)

    $details = @()
    $inventoryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Inventory\Office\16.0',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Inventory\Office\16.0',
        'HKCU:\SOFTWARE\Microsoft\Office\ClickToRun\Inventory\Office\16.0'
    )
    foreach ($path in $inventoryPaths) {
        try {
            if (Test-Path -LiteralPath $path) {
                $item = Get-ItemProperty -LiteralPath $path -ErrorAction Stop
                $ids = [string]$item.OfficeProductReleaseIds
                $version = [string]$item.OfficePackageVersion
                # Microsoft's Click-to-Run inventory values are the primary detection source.
                if (-not [string]::IsNullOrWhiteSpace($ids) -and -not [string]::IsNullOrWhiteSpace($version)) {
                    $details += "Click-to-Run inventory: $ids, version $version"
                } elseif (-not [string]::IsNullOrWhiteSpace($ids)) {
                    $details += "Click-to-Run inventory: $ids"
                }
            }
        } catch {
            Write-Log "Could not read Office inventory at $path : $($_.Exception.Message)"
        }
    }

    # Use Configuration only as a fallback; do not trust VersionToReport by itself.
    foreach ($path in @(
        'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration',
        'HKCU:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'
    )) {
        if ($details.Count -gt 0) { break }
        try {
            if (Test-Path -LiteralPath $path) {
                $item = Get-ItemProperty -LiteralPath $path -ErrorAction Stop
                $ids = [string]$item.ProductReleaseIds
                $installPath = [string]$item.InstallationPath
                if (-not [string]::IsNullOrWhiteSpace($ids) -and
                    ((-not [string]::IsNullOrWhiteSpace($installPath) -and (Test-Path -LiteralPath $installPath)) -or
                     -not [string]::IsNullOrWhiteSpace([string]$item.CDNBaseUrl))) {
                    $details += "Click-to-Run configuration: $ids"
                }
            }
        } catch {
            Write-Log "Could not read Office configuration at $path : $($_.Exception.Message)"
        }
    }

    if ($details.Count -eq 0) {
        $officeNamePattern = '(?i)^(Microsoft 365(?: Apps?.*)?|Office 365(?:.*)?|Microsoft Office (?:Professional|Standard|Home|Personal|Home and Student|Home and Business|LTSC|Enterprise|365|Mondo|Professional Plus).*)'
        foreach ($entry in $RegistryEntries) {
            if ([string]$entry.DisplayName -match $officeNamePattern) {
                # Do not treat the lightweight Office Hub/Office app or language tools alone as the suite.
                if ([string]$entry.DisplayName -match '(?i)(Office Hub|Office Desktop Apps|Proofing Tools|Language Pack|Shared MUI)') { continue }
                $details += "Installed-program registry: $($entry.DisplayName)"
            }
        }
    }

    if ($details.Count -eq 0) {
        $programFiles = [Environment]::GetEnvironmentVariable('ProgramFiles')
        $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
        $officeExePaths = @()
        foreach ($root in @($programFiles, $programFilesX86)) {
            if ([string]::IsNullOrWhiteSpace($root)) { continue }
            foreach ($relative in @(
                'Microsoft Office\root\Office16\WINWORD.EXE',
                'Microsoft Office\Office16\WINWORD.EXE',
                'Microsoft Office\root\Office16\EXCEL.EXE',
                'Microsoft Office\Office16\EXCEL.EXE',
                'Microsoft Office\root\Office16\POWERPNT.EXE',
                'Microsoft Office\Office16\POWERPNT.EXE'
            )) { $officeExePaths += (Join-Path $root $relative) }
        }
        $foundExe = @($officeExePaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1)
        if ($foundExe.Count -gt 0) { $details += "Office executable: $($foundExe[0])" }
    }

    return [pscustomobject]@{
        Installed = ($details.Count -gt 0)
        Details = @($details | Select-Object -Unique)
    }
}

function Test-AppScanRegistryEntry {
    param([Parameter(Mandatory=$true)]$App, [object[]]$RegistryEntries)

    $patterns = @{
        'OneDrive' = '(?i)^Microsoft OneDrive(?:\s|$|\()'
        'Quick Assist' = '(?i)^Microsoft Quick Assist(?:\s|$|\()'
        'Skype' = '(?i)^Skype(?:\s|$|\()'
        'OneNote' = '(?i)^(?:Microsoft )?OneNote(?:\s|$|\()'
        'Edge WebView2' = '(?i)^Microsoft Edge WebView2 Runtime(?:\s|$|\()'
        'Power Automate' = '(?i)^(?:Microsoft )?Power Automate(?: for desktop| Desktop)?(?:\s|$|\()'
        # Outlook (new) deliberately has no Uninstall-registry fallback. Stale
        # uninstall entries can remain after the AppX app has been removed.
    }
    if (-not $patterns.ContainsKey([string]$App.N)) { return $false }
    $pattern = $patterns[[string]$App.N]
    foreach ($entry in $RegistryEntries) {
        if ([string]$entry.DisplayName -match $pattern) { return $true }
    }
    return $false
}

function Show-AppScan {
    Clear-Host
    Write-Host 'APP SCAN' -ForegroundColor Green
    Write-Host 'Checking installed Store apps, provisioned apps, desktop apps and Microsoft Office.' -ForegroundColor Gray
    Write-Host 'A provisioned app is prepared for new user profiles; it is not necessarily installed for the current user.' -ForegroundColor DarkGray

    $installed = @()
    $appxCheckComplete = $false
    $appxScope = 'all users'
    try {
        $installed = @(Get-AppxPackage -AllUsers -ErrorAction Stop)
        $appxCheckComplete = $true
    } catch {
        Write-Log "APP SCAN: Get-AppxPackage -AllUsers failed: $($_.Exception.Message)"
        try {
            $installed = @(Get-AppxPackage -ErrorAction Stop)
            $appxCheckComplete = $true
            $appxScope = 'current user only (run as administrator for all users)'
        } catch {
            Write-Log "APP SCAN: current-user package check failed: $($_.Exception.Message)"
        }
    }

    $provisioned = @()
    $provisionedCheckComplete = $false
    try {
        $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction Stop)
        $provisionedCheckComplete = $true
    } catch {
        Write-Log "APP SCAN: provisioned package check failed: $($_.Exception.Message)"
    }

    $registryEntries = @(Get-AppScanRegistryEntries)
    $officeState = Get-AppScanOfficeState -RegistryEntries $registryEntries
    $packagePatterns = Get-AppScanPackagePatterns

    # Keep a separate current-account inventory. Get-AppxPackage -AllUsers may
    # still return a package registered for another Windows account (or package
    # metadata left behind), which must not make Outlook New appear installed
    # for the account running this scanner.
    $currentUserInstalled = @()
    $currentUserAppxCheckComplete = $false
    try {
        $currentUserInstalled = @(Get-AppxPackage -ErrorAction Stop)
        $currentUserAppxCheckComplete = $true
    } catch {
        Write-Log "APP SCAN: current-account Get-AppxPackage check failed: $($_.Exception.Message)"
    }

    if ($appxScope -ne 'all users') {
        Write-Host "NOTE: AppX results cover $appxScope." -ForegroundColor Yellow
    }
    if (-not $currentUserAppxCheckComplete) {
        Write-Host 'NOTE: Could not verify AppX packages for the current Windows account; Outlook New may show UNKNOWN.' -ForegroundColor Yellow
    }
    if (-not $provisionedCheckComplete) {
        Write-Host 'NOTE: Windows could not read provisioned package state; some Store results may be incomplete.' -ForegroundColor Yellow
    }

    $present = 0
    $missing = 0
    $provisionedOnlyCount = 0
    $unknown = 0
    foreach ($cat in $script:Categories.Keys) {
        Write-Host "`n--- $cat ---" -ForegroundColor Cyan
        foreach ($app in $script:Categories[$cat]) {
            $appxMatches = @()
            $outlookPackageExistsOutsideCurrentAccount = $false
            foreach ($pkg in $installed) {
                $identifiers = @($pkg.Name, $pkg.PackageFamilyName, $pkg.PackageFullName)
                $matched = $false
                foreach ($identifier in $identifiers) {
                    if (Test-AppScanIdentifier -App $app -Identifier ([string]$identifier) -PackagePatterns $packagePatterns) {
                        $matched = $true; break
                    }
                }
                if ($matched) { $appxMatches += $pkg }
            }

            if ($app.N -eq 'Outlook New') {
                # Outlook New is an AppX/MSIX app. Trust the current account's
                # package registration, not a broad all-users result or a stale
                # Add/Remove Programs registry entry.
                $allUserOutlookMatches = @($appxMatches)
                $currentUserOutlookMatches = @()
                if ($currentUserAppxCheckComplete) {
                    foreach ($pkg in $currentUserInstalled) {
                        $identifiers = @($pkg.Name, $pkg.PackageFamilyName, $pkg.PackageFullName)
                        $matched = $false
                        foreach ($identifier in $identifiers) {
                            if (Test-AppScanIdentifier -App $app -Identifier ([string]$identifier) -PackagePatterns $packagePatterns) {
                                $matched = $true
                                break
                            }
                        }
                        if ($matched) { $currentUserOutlookMatches += $pkg }
                    }
                    if ($currentUserOutlookMatches.Count -gt 0) {
                        $appxMatches = @($currentUserOutlookMatches)
                    } else {
                        $appxMatches = @()
                        $outlookPackageExistsOutsideCurrentAccount = ($allUserOutlookMatches.Count -gt 0)
                    }
                } else {
                    # The current-account check failed, so don't guess from the
                    # all-users query whether the app is installed for this user.
                    $appxMatches = @()
                }
            }

            $provisionedMatches = @()
            foreach ($pkg in $provisioned) {
                $identifiers = @($pkg.DisplayName, $pkg.PackageName)
                $matched = $false
                foreach ($identifier in $identifiers) {
                    if (Test-AppScanIdentifier -App $app -Identifier ([string]$identifier) -PackagePatterns $packagePatterns) {
                        $matched = $true; break
                    }
                }
                if ($matched) { $provisionedMatches += $pkg }
            }

            $isInstalled = ($appxMatches.Count -gt 0)
            $sources = @()
            if ($isInstalled) { $sources += 'Store/AppX' }
            if ($provisionedMatches.Count -gt 0) { $sources += 'provisioned for new profiles' }

            if ($app.P -eq 'OfficeClickToRun') {
                if ($officeState.Installed) {
                    $isInstalled = $true
                    $sources += 'Office Click-to-Run/MSI'
                    foreach ($detail in $officeState.Details) { Write-Host "      Detected: $detail" -ForegroundColor DarkGray }
                }
            } elseif (-not $isInstalled -and (Test-AppScanRegistryEntry -App $app -RegistryEntries $registryEntries)) {
                $isInstalled = $true
                $sources += 'desktop-app registry'
            } elseif (-not $isInstalled -and $app.N -eq 'OneNote') {
                # OneNote can be installed as a desktop app inside Microsoft 365 instead of a Store package.
                $officeRoots = @([Environment]::GetEnvironmentVariable('ProgramFiles'), [Environment]::GetEnvironmentVariable('ProgramFiles(x86)'))
                foreach ($root in $officeRoots) {
                    if ([string]::IsNullOrWhiteSpace($root)) { continue }
                    foreach ($relative in @('Microsoft Office\root\Office16\ONENOTE.EXE', 'Microsoft Office\Office16\ONENOTE.EXE')) {
                        if (Test-Path -LiteralPath (Join-Path $root $relative)) {
                            $isInstalled = $true
                            $sources += 'OneNote desktop executable'
                            break
                        }
                    }
                    if ($isInstalled) { break }
                }
            }

            if ($isInstalled) {
                $present++
                $uniqueSources = @($sources | Select-Object -Unique)
                Write-Host "  [INSTALLED] $($app.N) ($($uniqueSources -join '; '))" -ForegroundColor Green
                Write-Log "APP SCAN: INSTALLED: $($app.N) - $($uniqueSources -join '; ')"
            } elseif ($app.N -eq 'Outlook New' -and -not $currentUserAppxCheckComplete) {
                $unknown++
                Write-Host '  [UNKNOWN] Outlook New (could not verify current Windows account)' -ForegroundColor Yellow
                Write-Log 'APP SCAN: UNKNOWN: Outlook New - current-account AppX check failed'
            } elseif ($app.N -eq 'Outlook New' -and $outlookPackageExistsOutsideCurrentAccount) {
                $missing++
                Write-Host "  [NOT FOUND] $($app.N)" -ForegroundColor DarkGray
                Write-Log 'APP SCAN: NOT INSTALLED FOR CURRENT USER: Outlook New - all-users package entry only; current-user registration not found'
            } elseif ($provisionedMatches.Count -gt 0) {
                $provisionedOnlyCount++
                Write-Host "  [PROVISIONED ONLY] $($app.N) (new user profiles)" -ForegroundColor Yellow
                Write-Log "APP SCAN: PROVISIONED ONLY: $($app.N)"
            } elseif (-not $appxCheckComplete -or -not $provisionedCheckComplete -or $appxScope -ne 'all users') {
                $unknown++
                Write-Host "  [UNKNOWN] $($app.N) (package checks failed)" -ForegroundColor Yellow
                Write-Log "APP SCAN: UNKNOWN: $($app.N)"
            } else {
                $missing++
                Write-Host "  [NOT FOUND] $($app.N)" -ForegroundColor DarkGray
                Write-Log "APP SCAN: NOT FOUND: $($app.N)"
            }
        }
    }
    Write-Host "`nInstalled: $present    Provisioned only: $provisionedOnlyCount    Not found: $missing    Unknown: $unknown" -ForegroundColor Green
    Write-Log "App scan completed. Installed=$present; ProvisionedOnly=$provisionedOnlyCount; NotFound=$missing; Unknown=$unknown; AppxScope=$appxScope"
    Pause-Return
}

function Read-LogMenuChoice {
    # Match the About menu: type a choice and press Enter to confirm it.
    return (Read-Host 'Select an option').Trim()
}

function Wait-ForLogMenuKey {
    param([string]$Message = 'Press Enter to return to the log menu')
    Write-Host ''
    [void](Read-Host $Message)
}

function Show-Log {
    param([switch]$ReturnToRemovalMenu)

    while ($true) {
        if ($ReturnToRemovalMenu) {
            $logPath = $script:RemovalLogFile
            $logTitle = 'REMOVE APPS LOG'
            $backLabel = '[B] Back to Remove Apps menu'
        } else {
            $logPath = $script:LogFile
            $logTitle = 'WINTOOLKIT ACTIVITY LOG'
            $backLabel = '[B] Back to main menu'
        }

        Clear-Host
        Write-Host $logTitle -ForegroundColor Green
        Write-Host ''
        if ($logPath -and (Test-Path -LiteralPath $logPath)) {
            Write-Host "Current log: $logPath" -ForegroundColor DarkGray
        } else {
            Write-Host 'No current log file is available yet.' -ForegroundColor Yellow
        }
        Write-Host ''
        Write-Host '[1] View log in this window'
        Write-Host '[2] Open log in a separate PowerShell window'
        Write-Host '[3] Open log folder in Explorer'
        Write-Host $backLabel -ForegroundColor Yellow
        Write-Host ''
        # Same input style as About: type the choice and press Enter.
        $choice = Read-LogMenuChoice
        if ([string]::IsNullOrWhiteSpace($choice)) { continue }
        if ($ReturnToRemovalMenu) {
            Write-Log "Remove Apps log menu selection: $choice"
        } else {
            Write-Log "WinToolKit activity log menu selection: $choice"
        }

        switch ($choice) {
            '1' {
                Clear-Host
                Write-Host $logTitle -ForegroundColor Green
                Write-Host ''
                if ($logPath -and (Test-Path -LiteralPath $logPath)) {
                    try {
                        Get-Content -LiteralPath $logPath -ErrorAction Stop
                        Write-Host "`nCurrent log: $logPath" -ForegroundColor DarkGray
                    } catch {
                        Write-Host "Could not read the log: $($_.Exception.Message)" -ForegroundColor Red
                    }
                } else {
                    Write-Host 'No log entries are available.' -ForegroundColor Yellow
                }
                Wait-ForLogMenuKey -Message 'Press Enter to return to Log Info'
            }
            '2' {
                if (-not ($logPath -and (Test-Path -LiteralPath $logPath))) {
                    Write-Host 'No current log file is available to open.' -ForegroundColor Yellow
                    Wait-ForLogMenuKey -Message 'Press Enter to return to Log Info'
                    continue
                }
                try {
                    # Encode the command to avoid quoting issues with spaces or special characters in paths.
                    $safeLogPath = $logPath.Replace("'", "''")
                    $psCommand = "Get-Content -LiteralPath '$safeLogPath' | Out-Host; Write-Host ''; Write-Host 'Log view finished. Press Enter to continue in PowerShell.'; [void](Read-Host)"
                    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($psCommand))
                    Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -NoExit -EncodedCommand $encodedCommand" -ErrorAction Stop
                    Write-Log "Opened log in a separate PowerShell window: $logPath"
                    Write-Host 'Opened the selected log in a separate PowerShell window.' -ForegroundColor Green
                } catch {
                    Write-Host "Could not open the log in PowerShell: $($_.Exception.Message)" -ForegroundColor Red
                    Wait-ForLogMenuKey -Message 'Press Enter to return to Log Info'
                }
            }
            '3' {
                try {
                    if ($logPath -and (Test-Path -LiteralPath $logPath)) {
                        $logFolder = Split-Path -Parent $logPath
                    } else {
                        $logFolder = $script:LogsPath
                        if (-not (Test-Path -LiteralPath $logFolder)) {
                            New-Item -ItemType Directory -Path $logFolder -Force -ErrorAction Stop | Out-Null
                        }
                    }
                    Start-Process -FilePath 'explorer.exe' -ArgumentList ('"{0}"' -f $logFolder) -ErrorAction Stop
                    Write-Log "Opened log folder in Explorer: $logFolder"
                    Write-Host "Opened log folder: $logFolder" -ForegroundColor Green
                } catch {
                    Write-Host "Could not open the log folder: $($_.Exception.Message)" -ForegroundColor Red
                    Wait-ForLogMenuKey -Message 'Press Enter to return to Log Info'
                }
            }
            'B' { return }
            default { Write-Host 'Invalid selection. Enter 1, 2, 3, or B.' -ForegroundColor Yellow; Start-Sleep -Milliseconds 800 }
        }
    }
}

function Clear-Log {
    Write-Host ''
    Write-Host 'This clears the Remove Apps log only. The WinToolKit activity log is not changed.' -ForegroundColor Yellow
    $confirm = Read-Host 'Type CLEAR to continue, or press Enter to cancel'
    if ($confirm -cne 'CLEAR') {
        Write-Log 'Cancelled Remove Apps log clearing.'
        Write-Host 'Log clearing cancelled.' -ForegroundColor Cyan
        return
    }
    if ($script:RemovalLogFile -and (Test-Path -LiteralPath $script:RemovalLogFile)) {
        try {
            Clear-Content -LiteralPath $script:RemovalLogFile -ErrorAction Stop
            # Record the clear operation in the general log only, so the cleared
            # Remove Apps log remains empty instead of immediately gaining a new entry.
            $previousLogContext = $script:LogContext
            $script:LogContext = $null
            try { Write-Log 'Remove Apps log cleared by user.' }
            finally { $script:LogContext = $previousLogContext }
            Write-Host 'Remove Apps log cleared. The WinToolKit activity log was preserved.' -ForegroundColor Green
        } catch {
            Write-Host "Could not clear the Remove Apps log: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host 'No Remove Apps log file exists.' -ForegroundColor Yellow
    }
    Pause-Return
}

function Get-CustomInstallerList {
    param([string]$Folder = $script:AppsPath)
    if (-not (Test-Path -LiteralPath $script:AppsPath)) {
        New-Item -ItemType Directory -Path $script:AppsPath -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $Folder -PathType Container)) { $Folder = $script:AppsPath }
    # Show all local files so BAT, CMD, PowerShell scripts, and other file types can be opened too.
    $dirs = @(Get-ChildItem -LiteralPath $Folder -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
    $files = @(Get-ChildItem -LiteralPath $Folder -File -ErrorAction SilentlyContinue | Sort-Object Name)
    return @{ Folders = $dirs; Files = $files; Current = $Folder }
}

function Get-GitHubAppsDirectory {
    param([string]$RelativeFolder = '')

    # Use the GitHub Contents API for the current directory. This returns every
    # immediate file and subfolder, and lets the browser navigate each level
    # independently instead of relying on path-prefix parsing of one large tree.
    $folder = ([string]$RelativeFolder).Replace('\', '/').Trim('/')
    if ($folder -match '(^|/)(\.|\.\.)(/|$)' -or
        $folder.StartsWith('/') -or
        $folder.Contains(':')) {
        throw 'Invalid GitHub Apps folder path.'
    }

    if ($null -eq $script:GitHubAppsDirectoryCache) {
        $script:GitHubAppsDirectoryCache = @{}
    }

    $cacheKey = $folder.ToLowerInvariant()
    if ($script:GitHubAppsDirectoryCache.ContainsKey($cacheKey)) {
        return $script:GitHubAppsDirectoryCache[$cacheKey]
    }

    try {
        [Net.ServicePointManager]::SecurityProtocol =
            [Net.ServicePointManager]::SecurityProtocol -bor
            [Net.SecurityProtocolType]::Tls12
    } catch {}

    $headers = @{
        'Accept' = 'application/vnd.github+json'
        'User-Agent' = 'WinToolKit'
    }

    $pathParts = @('Apps')
    if (-not [string]::IsNullOrWhiteSpace($folder)) {
        $pathParts += @($folder -split '/')
    }

    $encodedPath = @($pathParts | ForEach-Object {
        [Uri]::EscapeDataString([string]$_)
    }) -join '/'

    $apiUrl = 'https://api.github.com/repos/Murdervan/WinToolKit/contents/' + $encodedPath + '?ref=main'

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers `
            -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
    } catch {
        throw "GitHub could not list Apps/$folder : $($_.Exception.Message)"
    }

    $entries = @()
    foreach ($item in @($response)) {
        if ($null -eq $item -or [string]::IsNullOrWhiteSpace([string]$item.name)) {
            continue
        }

        $itemType = [string]$item.type
        if ($itemType -ne 'dir' -and $itemType -ne 'file') {
            continue
        }

        $name = [string]$item.name
        if ($name -eq '.' -or $name -eq '..' -or $name.Contains('/') -or $name.Contains('\')) {
            continue
        }

        $relativePath = if ([string]::IsNullOrWhiteSpace($folder)) {
            $name
        } else {
            $folder.TrimEnd('/') + '/' + $name
        }

        if ($itemType -eq 'dir') {
            $entries += [pscustomobject]@{
                type = 'dir'
                name = $name
                size = $null
                download_url = $null
                sha = [string]$item.sha
                relative_path = $relativePath
            }
            continue
        }

        $downloadUrl = [string]$item.download_url
        if ([string]::IsNullOrWhiteSpace($downloadUrl)) {
            $rawPathParts = @('Apps') + @($relativePath -split '/')
            $encodedRawPath = @($rawPathParts | ForEach-Object {
                [Uri]::EscapeDataString([string]$_)
            }) -join '/'
            $downloadUrl = 'https://raw.githubusercontent.com/Murdervan/WinToolKit/main/' + $encodedRawPath
        }

        $entries += [pscustomobject]@{
            type = 'file'
            name = $name
            size = $item.size
            download_url = $downloadUrl
            sha = [string]$item.sha
            relative_path = $relativePath
        }
    }

    $entries = @($entries | Sort-Object -Property @(
        @{ Expression = { if ($_.type -eq 'dir') { 0 } else { 1 } } },
        @{ Expression = { [string]$_.name } }
    ))

    $script:GitHubAppsDirectoryCache[$cacheKey] = @($entries)
    return $entries
}

function Show-GitHubAppsBrowser {
    $relativeFolder = ''

    while ($true) {
        try {
            $entries = @(Get-GitHubAppsDirectory -RelativeFolder $relativeFolder)
        } catch {
            Clear-Host
            Write-Host 'GITHUB APPS' -ForegroundColor Cyan
            Write-Host ''
            if ([string]::IsNullOrWhiteSpace($relativeFolder)) {
                Write-Host 'Repository folder: Apps' -ForegroundColor DarkGray
            } else {
                Write-Host "Repository folder: Apps/$relativeFolder" -ForegroundColor DarkGray
            }
            Write-Host "Could not retrieve this GitHub folder: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host ''
            Write-Host '[R] Retry   [B] Back' -ForegroundColor Yellow
            $errorChoice = (Read-Host 'Choose an action').Trim()

            if ($errorChoice -match '^[rR]$') {
                $script:GitHubAppsDirectoryCache = @{}
                continue
            }
            if ($errorChoice -match '^[bB]$') {
                if ([string]::IsNullOrWhiteSpace($relativeFolder)) {
                    return $null
                }
                $lastSlash = $relativeFolder.LastIndexOf('/')
                if ($lastSlash -ge 0) {
                    $relativeFolder = $relativeFolder.Substring(0, $lastSlash)
                } else {
                    $relativeFolder = ''
                }
                continue
            }
            continue
        }

        Clear-Host
        Write-Host 'GITHUB APPS' -ForegroundColor Cyan
        if ([string]::IsNullOrWhiteSpace($relativeFolder)) {
            Write-Host 'Repository: Murdervan/WinToolKit / Apps' -ForegroundColor DarkGray
        } else {
            Write-Host "Repository folder: Apps/$relativeFolder" -ForegroundColor DarkGray
        }
        Write-Host 'Folders can be opened to browse their contents.' -ForegroundColor Gray
        Write-Host 'Only the file you select and confirm will be downloaded.' -ForegroundColor Gray
        Write-Host ''

        $indexMap = @{}
        $n = 1
        foreach ($entry in $entries) {
            if ($entry.type -eq 'dir') {
                Write-Host ('[{0,2}] [FOLDER] {1}' -f $n, $entry.name) -ForegroundColor Yellow
            } else {
                $extension = [IO.Path]::GetExtension([string]$entry.name).ToUpperInvariant()
                $sizeText = if ($null -ne $entry.size) {
                    '{0:N1} MB' -f ([double]$entry.size / 1MB)
                } else {
                    'size unknown'
                }
                Write-Host ('[{0,2}] {1}  ({2}, {3})' -f $n, $entry.name, $extension, $sizeText) -ForegroundColor Cyan
            }
            $indexMap[$n] = $entry
            $n++
        }

        if ($n -eq 1) {
            Write-Host 'No files or subfolders were found in this GitHub folder.' -ForegroundColor DarkGray
        }

        Write-Host ''
        Write-Host '[R] Refresh   ' -NoNewline -ForegroundColor Green
        if ([string]::IsNullOrWhiteSpace($relativeFolder)) {
            Write-Host '[B] Back to Install Custom Apps' -ForegroundColor Yellow
        } else {
            Write-Host '[B] Back one folder' -ForegroundColor Yellow
        }

        $selection = (Read-Host 'Choose a number or action').Trim()

        if ($selection -match '^[rR]$') {
            $script:GitHubAppsDirectoryCache = @{}
            continue
        }

        if ($selection -match '^[bB]$') {
            if ([string]::IsNullOrWhiteSpace($relativeFolder)) {
                return $null
            }

            # Move up exactly one GitHub folder level. Avoid Split-Path here:
            # Relative GitHub paths are not filesystem paths.
            $lastSlash = $relativeFolder.LastIndexOf('/')
            if ($lastSlash -ge 0) {
                $relativeFolder = $relativeFolder.Substring(0, $lastSlash)
            } else {
                $relativeFolder = ''
            }
            continue
        }

        $number = 0
        if (-not [int]::TryParse($selection, [ref]$number) -or
            -not $indexMap.ContainsKey($number)) {
            Write-Host 'Invalid selection.' -ForegroundColor Yellow
            Start-Sleep -Milliseconds 800
            continue
        }

        $selectedEntry = $indexMap[$number]
        if ($selectedEntry.type -eq 'dir') {
            $relativeFolder = [string]$selectedEntry.relative_path
            continue
        }

        return [pscustomobject]@{
            Entry = $selectedEntry
            RelativePath = [string]$selectedEntry.relative_path
        }
    }
}

function Get-GitHubAppFile {
    param(
        [Parameter(Mandatory=$true)]$RemoteSelection
    )

    $relativePath = [string]$RemoteSelection.RelativePath
    $pathParts = @($relativePath -split '/')
    $invalidChars = [IO.Path]::GetInvalidFileNameChars()
    foreach ($part in $pathParts) {
        if ([string]::IsNullOrWhiteSpace($part) -or $part -eq '.' -or $part -eq '..' -or $part.IndexOfAny($invalidChars) -ge 0) {
            throw 'GitHub returned an invalid app file path.'
        }
    }

    $cacheRoot = Join-Path $script:AppsPath 'GitHub'
    New-Item -ItemType Directory -Path $cacheRoot -Force -ErrorAction Stop | Out-Null
    $cacheRootFull = [IO.Path]::GetFullPath($cacheRoot).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $localRelativePath = $relativePath.Replace('/', [IO.Path]::DirectorySeparatorChar)
    $destination = [IO.Path]::GetFullPath((Join-Path $cacheRoot $localRelativePath))
    if (-not $destination.StartsWith($cacheRootFull, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The selected GitHub app path is outside the local Apps cache.'
    }

    $remoteUrl = [string]$RemoteSelection.Entry.download_url
    if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
        $encodedPath = @((@('Apps') + $pathParts) | ForEach-Object { [Uri]::EscapeDataString([string]$_) }) -join '/'
        $remoteUrl = 'https://raw.githubusercontent.com/Murdervan/WinToolKit/main/' + $encodedPath
    }

    $downloadUri = $null
    if (-not [Uri]::TryCreate($remoteUrl, [UriKind]::Absolute, [ref]$downloadUri) -or
        $downloadUri.Scheme -ne 'https' -or
        $downloadUri.Host -ne 'raw.githubusercontent.com') {
        throw 'GitHub returned an unexpected app download URL.'
    }

    $destinationFolder = Split-Path -Parent $destination
    New-Item -ItemType Directory -Path $destinationFolder -Force -ErrorAction Stop | Out-Null
    $temporaryFile = $destination + '.' + [Guid]::NewGuid().ToString('N') + '.download'

    try {
        Write-Host ''
        Write-Host "Downloading $relativePath ..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $remoteUrl -OutFile $temporaryFile `
            -Headers @{ 'User-Agent' = 'WinToolKit' } -UseBasicParsing -TimeoutSec 180 -ErrorAction Stop | Out-Null

        if (($null -ne $RemoteSelection.Entry.size) -and
            ((Get-Item -LiteralPath $temporaryFile).Length -ne [long]$RemoteSelection.Entry.size)) {
            throw 'The downloaded file size did not match the GitHub file listing.'
        }

        Move-Item -LiteralPath $temporaryFile -Destination $destination -Force -ErrorAction Stop
        Write-Log "Downloaded GitHub app after user selection: $relativePath"
        Write-Host 'Download completed.' -ForegroundColor Green
    } finally {
        if (Test-Path -LiteralPath $temporaryFile) {
            Remove-Item -LiteralPath $temporaryFile -Force -ErrorAction SilentlyContinue
        }
    }

    return Get-Item -LiteralPath $destination -ErrorAction Stop
}

function Install-CustomApp {
    $currentFolder = $script:AppsPath
    while ($true) {
        $listing = Get-CustomInstallerList -Folder $currentFolder
        Clear-Host
        Write-Host 'INSTALL CUSTOM APPS' -ForegroundColor Cyan
        Write-Host 'Browse local folders, or browse GitHub apps and download only what you select.' -ForegroundColor Gray
        Write-Host "Current folder: $currentFolder" -ForegroundColor DarkGray
        Write-Host 'Installers: EXE/MSI/MSIX/APPX | Scripts: BAT/CMD/PS1/VBS/JS | Other files open with their default Windows app' -ForegroundColor DarkGray
        Write-Host ''

        $indexMap = @{}
        $n = 1
        foreach ($dir in $listing.Folders) {
            Write-Host ('[{0,2}] [FOLDER] {1}' -f $n, $dir.Name) -ForegroundColor Yellow
            $indexMap[$n] = @{ Type='Folder'; Item=$dir }
            $n++
        }
        foreach ($file in $listing.Files) {
            Write-Host ('[{0,2}] {1}  ({2})' -f $n, $file.Name, $file.Extension.ToUpperInvariant()) -ForegroundColor Cyan
            $indexMap[$n] = @{ Type='File'; Item=$file }
            $n++
        }
        if ($n -eq 1) { Write-Host 'No local folders or files in this location.' -ForegroundColor DarkGray }
        Write-Host ''
        Write-Host -NoNewline '[O] Open current folder in Explorer   [R] Refresh   ' -ForegroundColor Green
        if ($currentFolder -eq $script:AppsPath) {
            Write-Host '[G] Browse GitHub Apps   ' -NoNewline -ForegroundColor Cyan
        }
        Write-Host '[B] Back' -ForegroundColor Yellow

        $sel = (Read-Host 'Choose a number or action').Trim()
        if ($sel -match '^[bB]$') {
            # Back moves up exactly one local Apps folder level.
            # At the Apps root it returns to the WinToolKit main menu.
            $appsRootFull = [IO.Path]::GetFullPath($script:AppsPath).TrimEnd([char[]]@([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar))
            $currentFull = [IO.Path]::GetFullPath($currentFolder).TrimEnd([char[]]@([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar))

            if (-not $currentFull.Equals($appsRootFull, [StringComparison]::OrdinalIgnoreCase)) {
                $parentInfo = [IO.Directory]::GetParent($currentFull)
                if ($null -ne $parentInfo) {
                    $parentFull = $parentInfo.FullName.TrimEnd([char[]]@([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar))
                    $appsPrefix = $appsRootFull + [IO.Path]::DirectorySeparatorChar
                    if ($parentFull.Equals($appsRootFull, [StringComparison]::OrdinalIgnoreCase) -or
                        $parentFull.StartsWith($appsPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                        $currentFolder = $parentFull
                    } else {
                        $currentFolder = $script:AppsPath
                    }
                } else {
                    $currentFolder = $script:AppsPath
                }
                continue
            }
            return
        }
        if ($sel -match '^[rR]$') { continue }
        if ($sel -match '^[oO]$') {
            try { Start-Process explorer.exe -ArgumentList ('"{0}"' -f $currentFolder) -ErrorAction Stop }
            catch { Write-Host "Could not open folder: $($_.Exception.Message)" -ForegroundColor Red; Pause-Return }
            continue
        }

        $installer = $null
        if ($sel -match '^[gG]$' -and $currentFolder -eq $script:AppsPath) {
            $remoteSelection = Show-GitHubAppsBrowser
            if ($null -eq $remoteSelection) { continue }
            $remoteName = [string]$remoteSelection.Entry.name
            Write-Host ''
            Write-Host "Selected GitHub app: $remoteName" -ForegroundColor Cyan
            Write-Host "Repository path: Apps/$($remoteSelection.RelativePath)" -ForegroundColor Gray
            Write-Host 'Only this selected file will be downloaded. Other GitHub apps will not be downloaded.' -ForegroundColor Yellow
            $confirm = Read-Host 'Type RUN to download and start, or press Enter to cancel'
            if ($confirm -ceq 'RUN') {
                try {
                    $installer = Get-GitHubAppFile -RemoteSelection $remoteSelection
                } catch {
                    Write-Host "Could not download selected app: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Log "ERROR downloading GitHub app $($remoteSelection.RelativePath): $($_.Exception.Message)"
                    Pause-Return
                    continue
                }
            } else {
                Write-Host 'Download cancelled. No app file was downloaded.' -ForegroundColor DarkGray
                Start-Sleep -Milliseconds 700
                continue
            }
        } else {
            $number = 0
            if (-not [int]::TryParse($sel, [ref]$number) -or -not $indexMap.ContainsKey($number)) {
                Write-Host 'Invalid selection.' -ForegroundColor Yellow
                Start-Sleep -Milliseconds 800
                continue
            }
            $entry = $indexMap[$number]
            if ($entry.Type -eq 'Folder') { $currentFolder = $entry.Item.FullName; continue }
            $installer = $entry.Item

            Write-Host ''
            Write-Host "Selected: $($installer.Name)" -ForegroundColor Cyan
            Write-Host "Location: $($installer.FullName)" -ForegroundColor Gray
            Write-Host 'Only run installers you trust; they may make system-wide changes.' -ForegroundColor Yellow
            $confirm = Read-Host 'Type RUN to start, or press Enter to cancel'
            if ($confirm -cne 'RUN') {
                Write-Host 'Installer start cancelled.' -ForegroundColor DarkGray
                Start-Sleep -Milliseconds 500
                continue
            }
        }

        if ($null -eq $installer) { continue }
        $extension = $installer.Extension.ToLowerInvariant()

        try {
            Write-Log "Started custom installer: $($installer.FullName)"
            switch ($extension) {
                '.exe' {
                    $proc = Start-Process -FilePath $installer.FullName -Wait -PassThru -ErrorAction Stop
                    Write-Host "Program finished with exit code $($proc.ExitCode)." -ForegroundColor Green
                    Write-Log "Program exited with code $($proc.ExitCode): $($installer.FullName)"
                }
                '.msi' {
                    $proc = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList @('/i', ('"{0}"' -f $installer.FullName)) -Wait -PassThru -ErrorAction Stop
                    Write-Host "Installer finished with exit code $($proc.ExitCode)." -ForegroundColor Green
                    Write-Log "Installer exited with code $($proc.ExitCode): $($installer.FullName)"
                }
                { $_ -in '.msix', '.appx', '.msixbundle', '.appxbundle' } {
                    Add-AppxPackage -Path $installer.FullName -ErrorAction Stop
                    Write-Host 'Package installation command completed.' -ForegroundColor Green
                    Write-Log "Package installation completed: $($installer.FullName)"
                }
                { $_ -in '.bat', '.cmd' } {
                    # Run command scripts in a separate CMD window and leave it open for output.
                    $proc = Start-Process -FilePath $env:ComSpec -ArgumentList ('/k "{0}"' -f $installer.FullName) -Wait -PassThru -ErrorAction Stop
                    Write-Host "Command script window closed (exit code $($proc.ExitCode))." -ForegroundColor Green
                    Write-Log "Started command script: $($installer.FullName)"
                }
                '.ps1' {
                    # Open PowerShell scripts in a separate, visible PowerShell window.
                    $proc = Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -NoExit -File "{0}"' -f $installer.FullName) -Wait -PassThru -ErrorAction Stop
                    Write-Host 'PowerShell script window closed.' -ForegroundColor Green
                    Write-Log "Started PowerShell script: $($installer.FullName)"
                }
                '.vbs' {
                    Start-Process -FilePath 'wscript.exe' -ArgumentList ('"{0}"' -f $installer.FullName) -ErrorAction Stop
                    Write-Host 'VBScript opened.' -ForegroundColor Green
                    Write-Log "Opened VBScript: $($installer.FullName)"
                }
                '.js' {
                    Start-Process -FilePath 'wscript.exe' -ArgumentList ('"{0}"' -f $installer.FullName) -ErrorAction Stop
                    Write-Host 'JavaScript file opened.' -ForegroundColor Green
                    Write-Log "Opened JavaScript file: $($installer.FullName)"
                }
                default {
                    # Documents, shortcuts, and any other file type use their Windows default app.
                    Start-Process -FilePath $installer.FullName -ErrorAction Stop
                    Write-Host 'Opened file with its default Windows application.' -ForegroundColor Green
                    Write-Log "Opened file with default application: $($installer.FullName)"
                }
            }
        } catch {
            Write-Host "Could not install/start installer: $($_.Exception.Message)" -ForegroundColor Red
            Write-Log "ERROR installing $($installer.FullName): $($_.Exception.Message)"
        }
        Pause-Return
    }
}

function Show-SystemInformation {
    Clear-Host
    Write-Host 'SYSTEM INFORMATION' -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor DarkCyan
    Write-Host ''
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        $ramGB = [Math]::Round(($computer.TotalPhysicalMemory / 1GB), 2)

        Write-Host 'SYSTEM' -ForegroundColor Green
        [pscustomobject]@{
            ComputerName = $env:COMPUTERNAME
            Windows = $os.Caption
            Version = $os.Version
            Build = $os.BuildNumber
            Architecture = $os.OSArchitecture
            Manufacturer = $computer.Manufacturer
            Model = $computer.Model
            Processor = $cpu.Name
            InstalledRAM_GB = $ramGB
            PowerShell = $PSVersionTable.PSVersion.ToString()
            Administrator = (Test-IsAdministrator)
            ToolPath = $script:ToolRoot
        } | Format-List | Out-Host

        Write-Host 'GRAPHICS' -ForegroundColor Green
        try {
            $gpus = @(Get-CimInstance Win32_VideoController -ErrorAction Stop)
            if ($gpus.Count -eq 0) { Write-Host 'No graphics adapters were reported.' -ForegroundColor DarkGray }
            foreach ($gpu in $gpus) {
                Write-Host ("Name:   {0}" -f $gpu.Name) -ForegroundColor Cyan
                Write-Host ("Driver: {0}" -f $(if ($gpu.DriverVersion) { $gpu.DriverVersion } else { 'Unavailable' }))
                Write-Host ("VRAM:   {0} GB" -f $(if ($gpu.AdapterRAM) { [Math]::Round(($gpu.AdapterRAM / 1GB), 2) } else { 'N/A' }))
                Write-Host ''
            }
        } catch {
            Write-Host "Graphics information unavailable: $($_.Exception.Message)" -ForegroundColor Yellow
        }

        Write-Host 'PHYSICAL DISKS' -ForegroundColor Green
        try {
            $physicalDisks = @(Get-CimInstance Win32_DiskDrive -ErrorAction Stop)
            foreach ($disk in $physicalDisks) {
                Write-Host ("{0} | {1} | {2} GB" -f $disk.DeviceID, $disk.Model, [Math]::Round(($disk.Size / 1GB), 2)) -ForegroundColor Cyan
            }
            if ($physicalDisks.Count -eq 0) { Write-Host 'No physical disks were reported.' -ForegroundColor DarkGray }
        } catch {
            Write-Host "Physical disk information unavailable: $($_.Exception.Message)" -ForegroundColor Yellow
        }

        Write-Host "`nVOLUMES / DRIVE LETTERS" -ForegroundColor Green
        try {
            $volumes = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction Stop | Sort-Object DeviceID)
            foreach ($volume in $volumes) {
                $sizeGB = if ($volume.Size) { [Math]::Round(($volume.Size / 1GB), 2) } else { 0 }
                $freeGB = if ($volume.FreeSpace) { [Math]::Round(($volume.FreeSpace / 1GB), 2) } else { 0 }
                Write-Host ("{0,-5} Total: {1,10} GB   Free: {2,10} GB   {3}" -f $volume.DeviceID, $sizeGB, $freeGB, $volume.VolumeName) -ForegroundColor Cyan
            }
            if ($volumes.Count -eq 0) { Write-Host 'No fixed drive letters were reported.' -ForegroundColor DarkGray }
        } catch {
            Write-Host "Volume information unavailable: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        Write-Log 'System information, graphics, physical disks and volumes displayed.'
    } catch {
        Write-Host "Could not collect system information: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "ERROR collecting system information: $($_.Exception.Message)"
    }
    Pause-Return
}

function Show-About {
    while ($true) {
        Clear-Host
        Write-Host 'ABOUT WINTOOLKIT' -ForegroundColor Green
        Write-Host ''
        Write-Host 'WinToolKit by Murdervan' -ForegroundColor Green
        Write-Host "Version: v$script:ToolVersion"
        Write-Host 'A portable Windows toolkit for everyday setup and maintenance.'
        Write-Host 'Install your own apps, remove selected built-in apps, and view system information and logs.'
        Write-Host 'Supports Windows 10/11 and Windows PowerShell 5.1; can run from a folder or USB drive.'
        Write-Host 'Administrator rights are required for system-wide changes. Review app-removal prompts carefully.'
        Write-Host ''
        Write-Host '[1] Open WinToolKit GitHub Issues'
        Write-Host '[2] Open README.md'
        Write-Host '[B] Back to main menu' -ForegroundColor Yellow
        Write-Host ''
        $choice = Read-Host 'Select an option'
        switch ($choice.ToUpperInvariant()) {
            '1' {
                try { Start-Process $script:IssuesUrl }
                catch { Write-Host "Could not open browser: $($_.Exception.Message)" -ForegroundColor Yellow; Pause-Return }
            }
            '2' {
                $readme = Join-Path $script:ToolRoot 'README.md'
                if (Test-Path -LiteralPath $readme) { Start-Process notepad.exe -ArgumentList @($readme) }
                else { Write-Host 'README.md was not found.' -ForegroundColor Yellow; Pause-Return }
            }
            'B' { return }
            default { Write-Host 'Invalid selection.' -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
        }
    }
}

function Invoke-Massgrave {
    Clear-Host
    Write-Host 'Starting Massgrave...' -ForegroundColor Green
    Write-Host 'This runs the external Massgrave script, as requested.' -ForegroundColor Gray
    Write-Log 'Massgrave selected; invoking the existing external script endpoint.'
    try {
        # Preserves the existing direct-launch behavior selected by the user.
        Invoke-Expression (Invoke-RestMethod -Uri 'https://get.activated.win' -ErrorAction Stop)
        Write-Log 'Massgrave process returned control to WinToolKit.'
    } catch {
        Write-Host "Massgrave could not be started: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "ERROR starting Massgrave: $($_.Exception.Message)"
        Pause-Return
    }
}

function Get-QuickSystemPanel {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('SYSTEM INFO')
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $lines.Add('OS:')
        $lines.Add([string]$os.Caption)
        $lines.Add(('Version: {0} (Build {1})' -f $os.Version, $os.BuildNumber))
    } catch { $lines.Add('OS details unavailable') }
    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $ram = if ($computer) { '{0:N1} GB' -f ($computer.TotalPhysicalMemory / 1GB) } else { 'N/A' }
        $lines.Add('')
        $lines.Add('HARDWARE:')
        if ($cpu) { $lines.Add(('CPU: {0}' -f $cpu.Name)) }
        $lines.Add(('RAM: {0}' -f $ram))
    } catch {}
    try {
        $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        $lines.Add('')
        $lines.Add('GRAPHICS CARD:')
        if ($gpu) {
            $lines.Add([string]$gpu.Name)
            $lines.Add(('Driver: {0}' -f $(if ($gpu.DriverVersion) { $gpu.DriverVersion } else { 'N/A' })))
        } else { $lines.Add('Not reported') }
    } catch {}
    try {
        $lines.Add('')
        $lines.Add('DISKS / DRIVES:')
        $volumes = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction SilentlyContinue | Sort-Object DeviceID)
        foreach ($v in ($volumes | Select-Object -First 4)) {
            $total = if ($v.Size) { [Math]::Round($v.Size / 1GB) } else { 0 }
            $free = if ($v.FreeSpace) { [Math]::Round($v.FreeSpace / 1GB) } else { 0 }
            $lines.Add(('{0}  {1} GB ({2} GB free)' -f $v.DeviceID, $total, $free))
        }
        if ($volumes.Count -eq 0) { $lines.Add('No fixed drives found') }
    } catch { $lines.Add('Drive info unavailable') }
    $lines.Add('')
    $lines.Add('LOG LOCATION:')
    $lines.Add([string]$script:LogsPath)
    return $lines.ToArray()
}

function Write-PanelLine {
    param([string]$Left, [string]$Right, [int]$LeftWidth = 96, [int]$RightWidth = 39)
    if ($Left.Length -gt $LeftWidth) { $Left = $Left.Substring(0, $LeftWidth) }
    if ($Right.Length -gt $RightWidth) { $Right = $Right.Substring(0, $RightWidth) }
    Write-Host ('| ' + $Left.PadRight($LeftWidth) + ' | ' + $Right.PadRight($RightWidth) + ' |') -ForegroundColor Cyan
}

function ConvertTo-WinToolKitVersion {
    param([string]$VersionText)
    if ([string]::IsNullOrWhiteSpace($VersionText)) { return $null }
    $normalized = $VersionText.Trim() -replace '^[vV]', ''
    try { return [version]$normalized } catch { return $null }
}

function Invoke-WinToolKitUpdate {
    Clear-Host
    Write-Host 'UPDATE WINTOOLKIT' -ForegroundColor Green
    Write-Host ('=' * 48) -ForegroundColor DarkCyan
    Write-Host "Installed version: v$script:ToolVersion"
    Write-Host 'Checking the latest published GitHub release...' -ForegroundColor Gray
    Write-Host ''

    try {
        # Windows PowerShell 5.1 may default to older TLS settings on some PCs.
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        } catch {}
        $release = Invoke-RestMethod -Uri $script:GitHubLatestReleaseApi `
            -Headers @{ 'Accept' = 'application/vnd.github+json'; 'User-Agent' = 'WinToolKit' } `
            -UseBasicParsing -TimeoutSec 25 -ErrorAction Stop
    } catch {
        Write-Host "Could not contact GitHub: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "UPDATE CHECK FAILED: $($_.Exception.Message)"
        Pause-Return
        return
    }

    $currentVersion = ConvertTo-WinToolKitVersion -VersionText $script:ToolVersion
    $latestVersion = ConvertTo-WinToolKitVersion -VersionText ([string]$release.tag_name)
    if ($null -eq $latestVersion -or $null -eq $currentVersion) {
        Write-Host 'GitHub returned a version number WinToolKit could not understand. No files were changed.' -ForegroundColor Red
        Write-Log "UPDATE CHECK FAILED: invalid version tag '$($release.tag_name)'"
        Pause-Return
        return
    }

    $releaseVersionText = ([string]$release.tag_name -replace '^[vV]', '')
    if ($latestVersion -le $currentVersion) {
        if ($latestVersion -lt $currentVersion) {
            Write-Host "GitHub's latest release is v$releaseVersionText; this local copy is newer (v$script:ToolVersion)." -ForegroundColor Yellow
            Write-Host 'No downgrade was performed. Publish a newer GitHub release to make it available here.' -ForegroundColor Gray
        } else {
            Write-Host "You already have the latest released version (v$releaseVersionText)." -ForegroundColor Green
        }
        Write-Log "UPDATE CHECK: local=v$script:ToolVersion latest=v$releaseVersionText; no update needed"
        Pause-Return
        return
    }

    Write-Host "New version available: v$releaseVersionText" -ForegroundColor Green
    if (-not [string]::IsNullOrWhiteSpace([string]$release.html_url)) {
        Write-Host "Release notes: $($release.html_url)" -ForegroundColor DarkGray
    }
    Write-Host 'Your Apps and Logs folders will not be changed.' -ForegroundColor Gray
    Write-Host 'A backup of each replaced core file will be stored in the Backups folder.' -ForegroundColor Gray
    Write-Host ''
    $confirm = Read-Host 'Type UPDATE to download and install this release, or press Enter to cancel'
    if ($confirm -cne 'UPDATE') {
        Write-Log "UPDATE CANCELLED: v$releaseVersionText"
        Write-Host 'Update cancelled. No files were changed.' -ForegroundColor Yellow
        Pause-Return
        return
    }

    $tempRoot = Join-Path $env:TEMP ('WinToolKit_Update_' + [Guid]::NewGuid().ToString('N'))
    $downloadPath = Join-Path $tempRoot 'release.zip'
    $extractPath = Join-Path $tempRoot 'extracted'
    try {
        New-Item -ItemType Directory -Path $tempRoot -Force -ErrorAction Stop | Out-Null

        $asset = @($release.assets | Where-Object { ([string]$_.name) -match '^WinToolKit.*\.zip$' } | Select-Object -First 1)
        if ($asset.Count -gt 0) {
            $downloadUrl = [string]$asset[0].browser_download_url
        } else {
            # If a release has no packaged ZIP, fall back to GitHub's source archive for this release tag.
            $downloadUrl = [string]$release.zipball_url
        }
        if ($downloadUrl -notmatch '^https://(?:github\.com|api\.github\.com)/') {
            throw 'GitHub did not provide an expected HTTPS download link.'
        }

        Write-Host 'Downloading release files...' -ForegroundColor Gray
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath `
            -Headers @{ 'User-Agent' = 'WinToolKit' } -UseBasicParsing -TimeoutSec 90 -ErrorAction Stop
        Expand-Archive -LiteralPath $downloadPath -DestinationPath $extractPath -Force -ErrorAction Stop

        $sourceScript = Get-ChildItem -LiteralPath $extractPath -Filter 'WinToolKit.ps1' -File -Recurse -ErrorAction Stop | Select-Object -First 1
        if ($null -eq $sourceScript) {
            throw 'The downloaded release did not contain WinToolKit.ps1. No files were changed.'
        }
        $sourceText = Get-Content -LiteralPath $sourceScript.FullName -Raw -ErrorAction Stop
        $versionMatch = [regex]::Match($sourceText, '(?m)^\s*\$script:ToolVersion\s*=\s*[''"]([^''"]+)[''"]')
        if (-not $versionMatch.Success) {
            throw 'The downloaded script does not declare a recognizable WinToolKit version. No files were changed.'
        }
        $archiveVersion = ConvertTo-WinToolKitVersion -VersionText $versionMatch.Groups[1].Value
        if ($null -eq $archiveVersion -or $archiveVersion -ne $latestVersion) {
            throw "Release tag v$releaseVersionText does not match the script version in the downloaded files. No files were changed."
        }

        # Only update core toolkit files. Apps, Logs, and any unrelated user files are deliberately excluded.
        $updatePlan = @()
        foreach ($fileName in @('WinToolKit.ps1', 'RunAsAdmin.bat', 'README.md')) {
            $sourceFile = if ($fileName -eq 'WinToolKit.ps1') {
                $sourceScript
            } else {
                Get-ChildItem -LiteralPath $extractPath -Filter $fileName -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            }
            if ($null -eq $sourceFile) { continue }

            if ($fileName -eq 'WinToolKit.ps1') {
                $destination = $script:ScriptPath
            } else {
                $destination = Join-Path $script:ToolRoot $fileName
            }
            $updatePlan += [pscustomobject]@{
                Name = $fileName
                Source = $sourceFile.FullName
                Destination = $destination
                Exists = (Test-Path -LiteralPath $destination -PathType Leaf)
                Backup = $null
            }
        }
        if ($updatePlan.Count -eq 0) { throw 'No supported toolkit files were found in the downloaded archive.' }

        $backupFolder = Join-Path $script:ToolRoot 'Backups'
        New-Item -ItemType Directory -Path $backupFolder -Force -ErrorAction Stop | Out-Null
        $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        foreach ($item in $updatePlan) {
            if ($item.Exists) {
                $safeName = $item.Name -replace '[^A-Za-z0-9._-]', '_'
                $item.Backup = Join-Path $backupFolder (('{0}_v{1}_{2}.bak' -f $safeName, $script:ToolVersion, $stamp))
                Copy-Item -LiteralPath $item.Destination -Destination $item.Backup -Force -ErrorAction Stop
            }
        }

        $copiedItems = @()
        try {
            foreach ($item in $updatePlan) {
                Copy-Item -LiteralPath $item.Source -Destination $item.Destination -Force -ErrorAction Stop
                $copiedItems += $item
            }
        } catch {
            # If any copy fails, restore files already replaced during this update attempt.
            foreach ($item in $copiedItems) {
                try {
                    if ($item.Exists -and $item.Backup -and (Test-Path -LiteralPath $item.Backup)) {
                        Copy-Item -LiteralPath $item.Backup -Destination $item.Destination -Force -ErrorAction Stop
                    } elseif (-not $item.Exists -and (Test-Path -LiteralPath $item.Destination)) {
                        Remove-Item -LiteralPath $item.Destination -Force -ErrorAction SilentlyContinue
                    }
                } catch {}
            }
            throw
        }

        Write-Log "UPDATE INSTALLED: v$releaseVersionText; updated=$($updatePlan.Name -join ', '); user Apps and Logs preserved"
        Write-Host ''
        Write-Host "WinToolKit v$releaseVersionText was installed successfully." -ForegroundColor Green
        Write-Host "Backup location: $backupFolder" -ForegroundColor Gray
        Write-Host 'Your Apps and Logs folders were left untouched.' -ForegroundColor Green
        Write-Host 'Restart WinToolKit to load the updated code.' -ForegroundColor Yellow
        Write-Host ''
        $restart = Read-Host 'Type R to restart WinToolKit now, or press Enter to return'
        if ($restart -match '^[rR]$') {
            try {
                Start-Process -FilePath 'powershell.exe' `
                    -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $script:ScriptPath) `
                    -WorkingDirectory $script:ToolRoot -ErrorAction Stop
                exit
            } catch {
                Write-Host "Automatic restart failed: $($_.Exception.Message)" -ForegroundColor Yellow
                Write-Host 'Close WinToolKit and start it again manually.' -ForegroundColor Yellow
                Pause-Return
            }
        }
    } catch {
        Write-Host ''
        Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host 'Your Apps and Logs folders were not changed.' -ForegroundColor Gray
        Write-Log "UPDATE FAILED for v$releaseVersionText : $($_.Exception.Message)"
        Pause-Return
    } finally {
        if (Test-Path -LiteralPath $tempRoot) {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Show-MainMenu {
    Show-Banner
    Write-Host 'MAIN MENU' -ForegroundColor Green
    Write-Host '----------------------------------------------' -ForegroundColor DarkCyan
    Write-Host '[1] Install Custom Apps' -ForegroundColor Cyan
    Write-Host '[2] Massgrave - Activate Windows & Office' -ForegroundColor Cyan
    Write-Host '[3] Remove Apps (Standard MS Apps)' -ForegroundColor Cyan
    Write-Host '[4] System Info' -ForegroundColor Cyan
    Write-Host '[5] Log Info' -ForegroundColor Cyan
    Write-Host '[6] Update WinToolKit' -ForegroundColor Cyan
    Write-Host "[7] About WinToolKit v$script:ToolVersion" -ForegroundColor Cyan
    Write-Host '[Q] Quit' -ForegroundColor Red
    Write-Host '----------------------------------------------' -ForegroundColor DarkCyan
    Write-Host ''
}

# Main entry point
if (-not (Test-IsAdministrator)) {
    Write-Host 'WinToolKit needs administrator rights for app removal and system-wide actions.' -ForegroundColor Yellow
    Write-Host 'Close this window and start RunAsAdmin.bat, then approve the Windows prompt.' -ForegroundColor Yellow
    Pause-Return
    exit 1
}

Initialize-Log
Write-Log "WinToolKit v$script:ToolVersion started. Root=$script:ToolRoot"

while ($true) {
    Show-MainMenu
    $keyInfo = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    $choice = [string]$keyInfo.Character
    if (-not [string]::IsNullOrWhiteSpace($choice)) {
        Write-Log "Main menu selection: $($choice.ToUpperInvariant())"
    }
    switch ($choice.ToUpperInvariant()) {
        '1' { Install-CustomApp }
        '2' { Invoke-Massgrave }
        '3' { Show-RemovalMenu }
        '4' { Show-SystemInformation }
        '5' { Show-Log }
        '6' { Invoke-WinToolKitUpdate }
        '7' { Show-About }
        'Q' {
            Write-Log 'WinToolKit closed by user.'
            Clear-Host
            Write-Host 'Thank you for using WinToolKit by Murdervan.' -ForegroundColor Green
            Write-Host ''
            break
        }
        default { Write-Host 'Invalid selection. Please choose 1-7, or Q.' -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
    }
    if ($choice.ToUpperInvariant() -eq 'Q') { break }
}

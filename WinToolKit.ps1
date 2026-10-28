# WinToolKit by Murdervan
# Version: 1.2.1
# Windows 10 / Windows 11
# PowerShell 5.1 compatible

$ErrorActionPreference = 'Continue'
$script:ToolVersion = '1.0.0'
$script:ToolRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($script:ToolRoot)) {
    $script:ToolRoot = (Get-Location).Path
}
$script:AppsPath = Join-Path $script:ToolRoot 'Apps'
$script:LogsPath = Join-Path $script:ToolRoot 'Logs'
$script:LogFile = $null
$script:IssuesUrl = 'https://github.com/murdervan/WinToolKit/issues'

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

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Initialize-Log {
    try {
        if (-not (Test-Path -LiteralPath $script:LogsPath)) {
            New-Item -ItemType Directory -Path $script:LogsPath -Force -ErrorAction Stop | Out-Null
        }
        $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
        $script:LogFile = Join-Path $script:LogsPath "WinToolKit_$stamp.log"
        New-Item -ItemType File -Path $script:LogFile -Force -ErrorAction Stop | Out-Null
    } catch {
        # USB may be write-protected. Fall back to a user-local log location.
        try {
            $fallback = Join-Path $env:LOCALAPPDATA 'WinToolKit\Logs'
            New-Item -ItemType Directory -Path $fallback -Force -ErrorAction Stop | Out-Null
            $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
            $script:LogFile = Join-Path $fallback "WinToolKit_$stamp.log"
            New-Item -ItemType File -Path $script:LogFile -Force -ErrorAction Stop | Out-Null
            Write-Host "[NOTICE] USB logging is unavailable. Logs will be saved locally:" -ForegroundColor Yellow
            Write-Host "         $fallback" -ForegroundColor Yellow
        } catch {
            $script:LogFile = $null
            Write-Host '[WARNING] Logging is unavailable because no writable log location was found.' -ForegroundColor Yellow
        }
    }
}

function Write-Log {
    param([Parameter(Mandatory=$true)][string]$Message)
    $entry = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    if ($script:LogFile) {
        try { Add-Content -LiteralPath $script:LogFile -Value $entry -Encoding UTF8 -ErrorAction Stop }
        catch { Write-Host '[WARNING] Could not write to the log file.' -ForegroundColor Yellow }
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
            # In folder browsing, Back means parent folder; at Apps root it returns to main menu.
            if ($currentFolder -ne $script:AppsPath) {
                $parent = Split-Path -Parent $currentFolder
                if ($parent -and ($parent -eq $script:AppsPath -or $parent.StartsWith($script:AppsPath + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase))) {
                    $currentFolder = $parent
                } else {
                    $currentFolder = $script:AppsPath
                }
                continue
            }
            return
        }
        $number = 0
        if ([int]::TryParse($sel, [ref]$number) -and $indexMap.ContainsKey($number)) {
            $app = $indexMap[$number]
            Remove-App -Name $app.Name -Package $app.Package
            Pause-Return
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
        Write-Host '[5] View log'
        Write-Host '[6] Clear log'
        Write-Host '[B] Back to main menu'
        Write-Host ''
        $choice = Read-Host 'Select an option'
        switch ($choice.ToUpperInvariant()) {
            '1' { Show-AppSelection }
            '2' { Invoke-MassRemoval }
            '3' { Force-Remove-SpecialApps; Pause-Return }
            '4' { Show-AppScan }
            '5' { Show-Log }
            '6' { Clear-Log }
            'B' { return }
            default { Write-Host 'Invalid selection.' -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
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

function Show-Log {
    Clear-Host
    Write-Host 'ACTIVITY LOG' -ForegroundColor Green
    Write-Host ''
    if ($script:LogFile -and (Test-Path -LiteralPath $script:LogFile)) {
        Get-Content -LiteralPath $script:LogFile
        Write-Host "`nCurrent log: $script:LogFile" -ForegroundColor DarkGray
    } else {
        Write-Host 'No log entries are available.' -ForegroundColor Yellow
    }
    Pause-Return
}

function Clear-Log {
    Write-Host ''
    Write-Host 'This clears the current log file only.' -ForegroundColor Yellow
    $confirm = Read-Host 'Type CLEAR to continue, or press Enter to cancel'
    if ($confirm -cne 'CLEAR') {
        Write-Log 'Cancelled log clearing.'
        Write-Host 'Log clearing cancelled.' -ForegroundColor Cyan
        return
    }
    if ($script:LogFile -and (Test-Path -LiteralPath $script:LogFile)) {
        try {
            Clear-Content -LiteralPath $script:LogFile -ErrorAction Stop
            Write-Log 'Log cleared by user.'
            Write-Host 'Current log cleared.' -ForegroundColor Green
        } catch {
            Write-Host "Could not clear log: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host 'No current log file exists.' -ForegroundColor Yellow
    }
    Pause-Return
}

function Get-CustomInstallerList {
    param([string]$Folder = $script:AppsPath)
    if (-not (Test-Path -LiteralPath $script:AppsPath)) {
        New-Item -ItemType Directory -Path $script:AppsPath -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $Folder -PathType Container)) { $Folder = $script:AppsPath }
    # Show all files so BAT, CMD, PowerShell scripts, and other file types can be opened too.
    $dirs = @(Get-ChildItem -LiteralPath $Folder -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
    $files = @(Get-ChildItem -LiteralPath $Folder -File -ErrorAction SilentlyContinue | Sort-Object Name)
    return @{ Folders = $dirs; Files = $files; Current = $Folder }
}

function Install-CustomApp {
    $currentFolder = $script:AppsPath
    while ($true) {
        $listing = Get-CustomInstallerList -Folder $currentFolder
        Clear-Host
        Write-Host 'INSTALL CUSTOM APPS' -ForegroundColor Cyan
        Write-Host 'Browse folders, open them in Explorer, or choose a file to run/open.' -ForegroundColor Gray
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
        if ($n -eq 1) { Write-Host 'No folders or files in this location.' -ForegroundColor DarkGray }
        Write-Host ''
        Write-Host '[O] Open current folder in Explorer   [U] Up   [R] Refresh   [B] Back' -ForegroundColor Green
        $sel = (Read-Host 'Choose a number or action').Trim()
        if ($sel -match '^[bB]$') {
            # In folder browsing, Back means parent folder; at Apps root it returns to main menu.
            if ($currentFolder -ne $script:AppsPath) {
                $parent = Split-Path -Parent $currentFolder
                if ($parent -and ($parent -eq $script:AppsPath -or $parent.StartsWith($script:AppsPath + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase))) {
                    $currentFolder = $parent
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
        if ($sel -match '^[uU]$') {
            if ($currentFolder -ne $script:AppsPath) {
                $parent = Split-Path -Parent $currentFolder
                if ($parent.StartsWith($script:AppsPath, [StringComparison]::OrdinalIgnoreCase) -or $parent -eq $script:AppsPath) { $currentFolder = $parent }
                else { $currentFolder = $script:AppsPath }
            }
            continue
        }
        $number = 0
        if (-not [int]::TryParse($sel, [ref]$number) -or -not $indexMap.ContainsKey($number)) {
            Write-Host 'Invalid selection.' -ForegroundColor Yellow; Start-Sleep -Milliseconds 800; continue
        }
        $entry = $indexMap[$number]
        if ($entry.Type -eq 'Folder') { $currentFolder = $entry.Item.FullName; continue }
        $installer = $entry.Item
        $extension = $installer.Extension.ToLowerInvariant()
        Write-Host ''
        Write-Host "Selected: $($installer.Name)" -ForegroundColor Cyan
        Write-Host "Location: $($installer.FullName)" -ForegroundColor Gray
        Write-Host 'Only run installers you trust; they may make system-wide changes.' -ForegroundColor Yellow
        $confirm = Read-Host 'Type RUN to start, or press Enter to cancel'
        if ($confirm -ceq 'RUN') {
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
            } catch { Write-Host "Could not install/start installer: $($_.Exception.Message)" -ForegroundColor Red; Write-Log "ERROR installing $($installer.FullName): $($_.Exception.Message)" }
            Pause-Return
        } else { Write-Host 'Installer start cancelled.' -ForegroundColor DarkGray; Start-Sleep -Milliseconds 500 }
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
        Write-Host "Version: $script:ToolVersion"
        Write-Host 'Purpose: Manage selected built-in Windows apps, launch personal installers, and view system information.'
        Write-Host 'Platform: Windows 10 and Windows 11'
        Write-Host 'Designed for portable use from a USB drive where Windows permissions allow it.'
        Write-Host ''
        Write-Host '[1] Open WinToolKit GitHub Issues'
        Write-Host '[2] Open README.md'
        Write-Host '[B] Back to main menu'
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

function Show-MainMenu {
    Show-Banner
    Write-Host 'MAIN MENU' -ForegroundColor Green
    Write-Host '----------------------------------------------' -ForegroundColor DarkCyan
    Write-Host '[1] Install Custom Apps' -ForegroundColor Cyan
    Write-Host '[2] Massgrave - Activate Windows & Office' -ForegroundColor Cyan
    Write-Host '[3] Remove Apps (Standard MS Apps)' -ForegroundColor Cyan
    Write-Host '[4] System Info' -ForegroundColor Cyan
    Write-Host '[5] Log' -ForegroundColor Cyan
    Write-Host "[6] About WinToolKit v$script:ToolVersion" -ForegroundColor Cyan
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
    $choice = (Read-Host 'Choose (1-6, Q)').Trim()
    switch ($choice.ToUpperInvariant()) {
        '1' { Install-CustomApp }
        '2' { Invoke-Massgrave }
        '3' { Show-RemovalMenu }
        '4' { Show-SystemInformation }
        '5' { Show-Log }
        '6' { Show-About }
        'Q' {
            Write-Log 'WinToolKit closed by user.'
            Clear-Host
            Write-Host 'Thank you for using WinToolKit by Murdervan.' -ForegroundColor Green
            Write-Host ''
            break
        }
        default { Write-Host 'Invalid selection. Please choose 1-6 or Q.' -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
    }
    if ($choice.ToUpperInvariant() -eq 'Q') { break }
}

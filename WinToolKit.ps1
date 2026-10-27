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
        @{N='Clipchamp'; P='Clipchamp'}
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
    'EXTENSIONS' = @(
        @{N='HEIF Image Extensions'; P='HEIFImageExtension'},
        @{N='Web Media Extensions'; P='WebMediaExtensions'},
        @{N='Raw Image Extension'; P='RawImageExtension'}
    )
    'OTHER' = @(
        @{N='Phone Link'; P='YourPhone'},
        @{N='Family Safety'; P='MicrosoftFamily'},
        @{N='Store Ads'; P='StorePurchaseApp'},
        @{N='Power Automate'; P='Microsoft.PowerAutomateDesktop'}
    )
}

function Remove-App {
    param(
        [string]$Name,
        [string]$Package,
        [switch]$SkipConfirmation
    )

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

function Show-AppScan {
    Clear-Host
    Write-Host 'APP SCAN' -ForegroundColor Green
    Write-Host 'Reading installed app packages. This may take a moment.' -ForegroundColor Gray
    try {
        $installed = @(Get-AppxPackage -AllUsers -ErrorAction Stop)
    } catch {
        Write-Host "Could not read packages: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "ERROR scanning installed packages: $($_.Exception.Message)"
        Pause-Return
        return
    }
    $present = 0
    $missing = 0
    foreach ($cat in $script:Categories.Keys) {
        Write-Host "`n--- $cat ---" -ForegroundColor Cyan
        foreach ($app in $script:Categories[$cat]) {
            $found = @($installed | Where-Object {
                $_.Name -like "*$($app.P)*" -or
                $_.PackageFamilyName -like "*$($app.P)*" -or
                $_.PackageFullName -like "*$($app.P)*"
            })
            if ($found.Count -gt 0) {
                Write-Host "  [FOUND] $($app.N)" -ForegroundColor Yellow
                $present++
            } else {
                Write-Host "  [NOT FOUND] $($app.N)" -ForegroundColor DarkGray
                $missing++
            }
        }
    }
    Write-Host "`nFound: $present    Not found: $missing" -ForegroundColor Green
    Write-Log "App scan completed. Found=$present; NotFound=$missing"
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
    $extensions = @('.exe', '.msi', '.msix', '.appx', '.msixbundle', '.appxbundle')
    $dirs = @(Get-ChildItem -LiteralPath $Folder -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
    $files = @(Get-ChildItem -LiteralPath $Folder -File -ErrorAction SilentlyContinue |
        Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() } | Sort-Object Name)
    return @{ Folders = $dirs; Files = $files; Current = $Folder }
}

function Install-CustomApp {
    $currentFolder = $script:AppsPath
    while ($true) {
        $listing = Get-CustomInstallerList -Folder $currentFolder
        Clear-Host
        Write-Host 'INSTALL CUSTOM APPS' -ForegroundColor Cyan
        Write-Host 'Browse folders, open them in Explorer, or choose an installer.' -ForegroundColor Gray
        Write-Host "Current folder: $currentFolder" -ForegroundColor DarkGray
        Write-Host 'Supported installers: EXE, MSI, MSIX, APPX, MSIXBUNDLE, APPXBUNDLE' -ForegroundColor DarkGray
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
        if ($n -eq 1) { Write-Host 'No folders or supported installers in this location.' -ForegroundColor DarkGray }
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
                    '.exe' { $proc = Start-Process -FilePath $installer.FullName -Wait -PassThru -ErrorAction Stop }
                    '.msi' { $proc = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList @('/i', ('"{0}"' -f $installer.FullName)) -Wait -PassThru -ErrorAction Stop }
                    { $_ -in '.msix', '.appx', '.msixbundle', '.appxbundle' } { Add-AppxPackage -Path $installer.FullName -ErrorAction Stop; $proc = $null }
                    default { throw "Unsupported installer type: $extension" }
                }
                if ($null -ne $proc) { Write-Host "Installer finished with exit code $($proc.ExitCode)." -ForegroundColor Green; Write-Log "Installer exited with code $($proc.ExitCode): $($installer.FullName)" }
                else { Write-Host 'Package installation command completed.' -ForegroundColor Green; Write-Log "Package installation completed: $($installer.FullName)" }
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

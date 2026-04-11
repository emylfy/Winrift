param(
    [switch]$DryRun,
    [switch]$NoConfirm,
    [switch]$Uninstall
)

# Admin elevation — fail fast before any expensive I/O
# Loads only AdminLaunch.ps1 (~55 lines, no deps) so the non-admin process
# exits as cheaply as possible without going through Common.ps1 / transcript.
# Without this, the user sees several [STARTUP] lines flash by before the
# UAC prompt — looks like the script hung or crashed.
. "$PSScriptRoot\scripts\AdminLaunch.ps1"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Winrift requires administrator privileges. Requesting elevation..." -ForegroundColor Yellow

    $passthrough = @()
    if ($DryRun)    { $passthrough += "-DryRun" }
    if ($NoConfirm) { $passthrough += "-NoConfirm" }
    if ($Uninstall) { $passthrough += "-Uninstall" }

    try {
        Start-AdminProcess -ScriptPath $PSCommandPath -Arguments $passthrough -NoExit
    } catch {
        Write-Host "Elevation cancelled or failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    exit 0
}

# Startup transcript — captures everything, even pre-Common.ps1 failures
$script:StartupLogStarted = $false
try {
    $logDir = Join-Path $env:USERPROFILE "Winrift\logs"
    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    $script:StartupLog = Join-Path $logDir "winrift_startup_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')_$PID.log"
    Start-Transcript -Path $script:StartupLog -Force -ErrorAction Stop | Out-Null
    $script:StartupLogStarted = $true
} catch {
    Write-Warning "Failed to start startup transcript: $($_.Exception.Message)"
}

$ErrorActionPreference = 'Stop'

try {
    . "$PSScriptRoot\scripts\Common.ps1"

    if ($DryRun) { $env:WINRIFT_DRY_RUN = "1" }
    if ($NoConfirm) { $env:WINRIFT_NO_CONFIRM = "1" }

    # Admin check was already done at the very top of the file (early elevation
    # before transcript / Common.ps1 load). If we reached here, we're already
    # running as administrator — no need to re-check.

    if ($Uninstall) {
        Write-Host ""
        Write-Log -Message "Uninstalling Winrift..." -Level INFO
        $shortcut = Join-Path ([Environment]::GetFolderPath('StartMenu')) "Programs\Winrift.lnk"
        if (Test-Path $shortcut) { Remove-Item $shortcut -Force; Write-Log -Message "Removed Start Menu shortcut" -Level SUCCESS }
        $dataDir = Join-Path $env:USERPROFILE "Winrift"
        if (Test-Path $dataDir) { Remove-Item $dataDir -Recurse -Force; Write-Log -Message "Removed data directory: $dataDir" -Level SUCCESS }
        $iconDir = Join-Path $env:APPDATA "Winrift"
        if (Test-Path $iconDir) { Remove-Item $iconDir -Recurse -Force; Write-Log -Message "Removed icon directory" -Level SUCCESS }
        try { Unregister-ScheduledTask -TaskName "Winrift-DriftCheck" -Confirm:$false -ErrorAction Stop; Write-Log -Message "Removed drift check scheduled task" -Level SUCCESS } catch {}
        Write-Log -Message "Winrift uninstalled." -Level SUCCESS
        exit 0
    }

    # Capture root path for use in scriptblock closures (where $PSScriptRoot may not resolve correctly)
    $script:Root = $PSScriptRoot

    # Load version from version.json
    $script:UpdateAvailable = $null
    $script:UpdateCheckJob = $null
    $versionInfo = $null
    $versionFile = Join-Path $script:Root "config\version.json"
    if (Test-Path $versionFile) {
        $versionInfo = Get-Content $versionFile -Raw | ConvertFrom-Json
        $full = $versionInfo.version
        $script:AppVersion = ($full -split '\.')[0..1] -join '.'

        # Kick off update check in background — does not block startup.
        # Result is consumed lazily by Get-UpdateCheckResult before each main menu draw.
        if ($versionInfo.repo) {
            $script:UpdateCheckJob = Start-Job -ScriptBlock {
                param($Repo, $LocalVer)
                try {
                    $url = "https://raw.githubusercontent.com/$Repo/main/config/version.json"
                    $remote = Invoke-RestMethod -Uri $url -TimeoutSec 5 -ErrorAction Stop
                    if ($remote.version -and $remote.version -ne $LocalVer) {
                        return $remote.version
                    }
                } catch {}
                return $null
            } -ArgumentList $versionInfo.repo, $versionInfo.version
        }
    } else {
        $script:AppVersion = "unknown"
    }

    # AdminLaunch.ps1 was already dot-sourced at the very top of this file
    # (before the elevation check), so Start-AdminProcess / Start-UserProcess
    # are already in scope here. No re-source needed.

function Invoke-Module {
    param([string]$ScriptPath, [switch]$UserProcess)
    if (-not (Test-Path $ScriptPath)) {
        Write-Log -Message "Module not found: $ScriptPath" -Level ERROR
        Write-Host "$Yellow This module may not be included in your installation.$Reset"
        $null = Read-Host "Press Enter to continue"
        return
    }
    if ($UserProcess) {
        Start-UserProcess -ScriptPath $ScriptPath
    } else {
        & $ScriptPath
        $Host.UI.RawUI.WindowTitle = "Winrift v$script:AppVersion"
    }
}

function Get-UpdateCheckResult {
    # Lazily consume the background update-check job. No-op if already consumed
    # or still running. Called before every main menu draw so the "U › Update"
    # entry appears as soon as the network call resolves.
    if ($null -eq $script:UpdateCheckJob) { return }
    if ($script:UpdateCheckJob.State -eq 'Completed') {
        $result = Receive-Job $script:UpdateCheckJob -ErrorAction SilentlyContinue
        Remove-Job $script:UpdateCheckJob -Force -ErrorAction SilentlyContinue
        $script:UpdateCheckJob = $null
        if ($result) { $script:UpdateAvailable = $result }
    } elseif ($script:UpdateCheckJob.State -in 'Failed','Stopped') {
        Remove-Job $script:UpdateCheckJob -Force -ErrorAction SilentlyContinue
        $script:UpdateCheckJob = $null
    }
}

function Invoke-SelfUpdate {
    param([string]$Version)
    $zipUrl  = "https://github.com/$($versionInfo.repo)/archive/refs/heads/main.zip"
    $tempZip = Join-Path $env:TEMP "winrift_update_$(Get-Random).zip"
    $tempDir = Join-Path $env:TEMP "winrift_update_$(Get-Random)"
    try {
        Invoke-WithSpinner -Message "Downloading v$Version" -ScriptBlock {
            param($url, $out)
            Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
        } -ArgumentList $zipUrl, $tempZip

        Write-Log -Message "Extracting..." -Level INFO
        Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force

        $srcDir = Get-ChildItem $tempDir -Directory | Select-Object -First 1
        Get-ChildItem $srcDir.FullName | Where-Object { $_.Name -ne 'logs' } | ForEach-Object {
            Copy-Item $_.FullName $script:Root -Recurse -Force
        }

        Write-Log -Message "Updated to v$Version. Restarting..." -Level SUCCESS
        Start-Sleep -Seconds 1
        Start-AdminProcess -ScriptPath $PSCommandPath -NoExit
        exit 0
    } catch {
        Write-Log -Message "Update failed: $($_.Exception.Message)" -Level ERROR
        Wait-ForUser
    } finally {
        Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Show-CommunityToolsMenu {
    $launcherPath = "$script:Root\modules\tools\ExternalLauncher.ps1"

    Invoke-MenuLoop -Title "Community Tools" -Items @(
        "1 › WinUtil - Tweaks, Apps & Fixes",
        "2 › Sparkle - Optimize & Debloat",
        "3 › GTweak - Debloat & Tweak",
        "4 › WinScript - Custom Script Builder",
        "---",
        "5 › Back to main menu"
    ) -Actions @{
        "1" = { Start-AdminProcess -ScriptPath $launcherPath -Arguments @("-ToolId", "winutil") }
        "2" = { Start-AdminProcess -ScriptPath $launcherPath -Arguments @("-ToolId", "sparkle") }
        "3" = { Start-AdminProcess -ScriptPath $launcherPath -Arguments @("-ToolId", "gtweak") }
        "4" = {
            & "$script:Root\modules\tools\WinScript.ps1"
            $Host.UI.RawUI.WindowTitle = "Winrift v$script:AppVersion"
        }
    } -ExitKey "5"
}

function Show-DocsMenu {
    Invoke-MenuLoop -Title "Docs & Guides" -Items @(
        "1 › Tweaks Guide - What each tweak does",
        "2 › Answer File Guide - Windows installation",
        "3 › Benchmark Guide - Methodology & results",
        "4 › Wiki - Full documentation",
        "---",
        "5 › Back to main menu"
    ) -Actions @{
        "1" = { Start-Process "https://github.com/emylfy/winrift/blob/main/docs/tweaks_guide.md" }
        "2" = { Start-Process "https://github.com/emylfy/winrift/blob/main/docs/autounattend_guide.md" }
        "3" = { Start-Process "https://github.com/emylfy/winrift/blob/main/docs/tests.md" }
        "4" = { Start-Process "https://github.com/emylfy/Winrift/wiki" }
    } -ExitKey "5"
}

function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Winrift v$script:AppVersion"
    Get-UpdateCheckResult

    $menuItems = @(
        "1 › System Audit - Find issues & fix them",
        "2 › Benchmark - Measure system performance",
        "3 › System Tweaks - Optimization & power management",
        "4 › Security & Privacy - Defender, Copilot, privacy",
        "5 › Drivers - NVIDIA, AMD, Intel, OEM",
        "6 › App Bundles - Install app collections",
        "7 › Customize - Desktop, terminal, themes",
        "8 › ISO Builder - Embed answer file into Windows ISO",
        "---",
        "9 › Community Tools",
        "0 › Docs & Guides"
    )
    $actions = @{
        "1" = { Invoke-Module "$script:Root\modules\system\Audit.Menu.ps1" }
        "2" = { Invoke-Module "$script:Root\modules\system\Benchmark.ps1" }
        "3" = { Invoke-Module "$script:Root\modules\system\Tweaks.ps1" }
        "4" = { Invoke-Module "$script:Root\modules\security\SecurityMenu.ps1" }
        "5" = { Invoke-Module "$script:Root\modules\drivers\Drivers.ps1" }
        "6" = { Invoke-Module "$script:Root\modules\unigetui\UniGetUI.ps1" -UserProcess }
        "7" = { Invoke-Module "$script:Root\modules\customize\Customize.Menu.ps1" -UserProcess }
        "8" = { Invoke-Module "$script:Root\modules\iso\ISOBuilder.ps1" }
        "9" = { Show-CommunityToolsMenu }
        "0" = { Show-DocsMenu }
    }

    if ($script:UpdateAvailable) {
        $menuItems += "---"
        $menuItems += "U › $Green Update available: v$($script:UpdateAvailable)$Reset"
        $actions["U"] = { Invoke-SelfUpdate -Version $script:UpdateAvailable }
    }

    Invoke-MenuLoop -Title "Winrift v$script:AppVersion" -Items $menuItems -Actions $actions
}

    Show-MainMenu
} catch {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Red
    Write-Host " FATAL: Winrift startup failed" -ForegroundColor Red
    Write-Host "================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error:    $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Type:     $($_.Exception.GetType().FullName)" -ForegroundColor DarkGray
    if ($_.InvocationInfo) {
        Write-Host "At:       $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor DarkGray
        Write-Host "Line:     $($_.InvocationInfo.Line.Trim())" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    Write-Host ""
    if ($script:StartupLogStarted) {
        Write-Host "Full log: $script:StartupLog" -ForegroundColor Cyan
        Write-Host ""
    }
    $null = Read-Host "Press Enter to exit"
    exit 1
} finally {
    if ($script:UpdateCheckJob) {
        try { Remove-Job $script:UpdateCheckJob -Force -ErrorAction SilentlyContinue } catch {}
    }
    if ($script:StartupLogStarted) {
        try { Stop-Transcript | Out-Null } catch {}
    }
}

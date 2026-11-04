param(
    [switch]$DryRun,
    [switch]$NoConfirm,
    [switch]$Uninstall,
    [string]$Apply
)

# Admin elevation — fail fast before any expensive I/O
# Loads only AdminLaunch.ps1 (~55 lines, no deps) so the non-admin process
# exits as cheaply as possible without going through Common.ps1 / transcript.
# Without this, the user sees several [STARTUP] lines flash by before the
# UAC prompt — looks like the script hung or crashed.
. "$PSScriptRoot\AdminLaunch.ps1"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Winrift requires administrator privileges. Requesting elevation..." -ForegroundColor Yellow

    $passthrough = @()
    if ($DryRun)    { $passthrough += "-DryRun" }
    if ($NoConfirm) { $passthrough += "-NoConfirm" }
    if ($Uninstall) { $passthrough += "-Uninstall" }
    if ($Apply)     { $passthrough += @("-Apply", $Apply) }

    try {
        Start-AdminProcess -ScriptPath $PSCommandPath -Arguments $passthrough
    } catch {
        Write-Host "Elevation cancelled or failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    exit 0
}

# Startup transcript — captures everything, even pre-Common.ps1 failures
$script:StartupLogStarted = $false
try {
    $logDir = Join-Path $env:LOCALAPPDATA "Winrift\logs"
    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    $script:StartupLog = Join-Path $logDir "winrift_startup_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')_$PID.log"
    Start-Transcript -Path $script:StartupLog -Force -ErrorAction Stop | Out-Null
    $script:StartupLogStarted = $true
} catch {
    Write-Warning "Failed to start startup transcript: $($_.Exception.Message)"
}

$ErrorActionPreference = 'Stop'

try {
    if($env:WINRIFT_ORIGIN_SID -and $env:WINRIFT_ORIGIN_SID -ne [Security.Principal.WindowsIdentity]::GetCurrent().User.Value){
        throw 'UAC changed the Windows account. Winrift stopped to preserve the original user registry and configuration context. Start Winrift elevated as the same account.'
    }
    . "$PSScriptRoot\Common.ps1"

    if ($DryRun) { $env:WINRIFT_DRY_RUN = "1" }
    if ($NoConfirm) { $env:WINRIFT_NO_CONFIRM = "1" }

    if ($Uninstall) { & "$PSScriptRoot\uninstall.ps1"; return }
    . "$PSScriptRoot\Migration.ps1"
    Invoke-WinriftUpgradeMigration

    # Headless profile apply — the single-pass entry point. Runs the whole
    # profile (tweaks + privacy + apps + configs) without the menu, then exits.
    if ($Apply) {
        $env:WINRIFT_NO_CONFIRM = "1"
        Initialize-Logging -ModuleName "apply"
        . "$PSScriptRoot\..\modules\customize\Customize.Configs.ps1"
        . "$PSScriptRoot\..\modules\security\Privacy.ps1"
        . "$PSScriptRoot\..\modules\profile\Profile.ps1"
        try {
            $profileObj = Read-WinriftProfile -Path $Apply
            Invoke-WinriftProfileApply -ProfileObject $profileObj
            if ($script:StartupLogStarted) { try { Stop-Transcript | Out-Null } catch { $null = $_ } }
            exit 0
        } catch {
            Write-Log -Message "Profile apply failed: $($_.Exception.Message)" -Level ERROR
            if ($script:StartupLogStarted) { try { Stop-Transcript | Out-Null } catch { $null = $_ } }
            exit 1
        }
    }

    $script:Root = Split-Path $PSScriptRoot -Parent
    $versionInfo = Get-Content (Join-Path $script:Root 'config\version.json') -Raw | ConvertFrom-Json
    $script:AppVersion = $versionInfo.version
    . "$PSScriptRoot\Navigation.ps1"
    Show-WinriftMainMenu
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
        try { Remove-Job $script:UpdateCheckJob -Force -ErrorAction SilentlyContinue } catch { $null = $_ }
    }
    if ($script:StartupLogStarted) {
        try { Stop-Transcript | Out-Null } catch { $null = $_ }
    }
}

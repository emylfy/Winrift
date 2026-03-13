# ── Simplify11 Shared Utilities ──────────────────────────────────────────────
# Colors, menu framework, registry helpers, and common functions
# Used by every module in the project — dot-source this file first.

# ── ANSI Color Constants ────────────────────────────────────────────────────
$Purple = "$([char]0x1b)[38;5;141m"
$Reset = "$([char]0x1b)[0m"
$Red = "$([char]0x1b)[38;5;203m"
$Green = "$([char]0x1b)[38;5;120m"
$Yellow = "$([char]0x1b)[38;5;220m"

# ── Menu Framework ──────────────────────────────────────────────────────────
function Show-Menu {
    param(
        [string]$Title,
        [hashtable[]]$Options,       # @{ Key="1"; Label="System Tweaks"; Action={...} }
        [string]$BackLabel = "Back to menu",
        [scriptblock]$BackAction = $null,
        [switch]$NoLoop,
        [string]$Prompt = ">"
    )

    while ($true) {
        Clear-Host
        Write-Host ""

        # Calculate inner width from longest label
        $maxLen = ($Title.Length)
        foreach ($opt in $Options) {
            $line = " [$($opt.Key)] $($opt.Label)"
            if ($line.Length -gt $maxLen) { $maxLen = $line.Length }
        }
        $backLine = " [0] $BackLabel"
        if ($backLine.Length -gt $maxLen) { $maxLen = $backLine.Length }
        $innerWidth = $maxLen + 2
        $border = "+" + ("-" * ($innerWidth + 2)) + "+"

        # Draw menu
        Write-Host "$Purple $border$Reset"
        Write-Host "$Purple '$Purple  $($Title.PadRight($innerWidth)) $Purple'$Reset"
        Write-Host "$Purple $border$Reset"
        foreach ($opt in $Options) {
            $line = " [$($opt.Key)] $($opt.Label)"
            Write-Host "$Purple '$Reset$($line.PadRight($innerWidth + 1))$Purple'$Reset"
        }
        Write-Host "$Purple $border$Reset"
        Write-Host "$Purple '$Reset$($backLine.PadRight($innerWidth + 1))$Purple'$Reset"
        Write-Host "$Purple $border$Reset"

        $choice = Read-Host $Prompt

        if ($choice -eq "0") {
            if ($BackAction) { & $BackAction }
            return
        }

        $matched = $false
        foreach ($opt in $Options) {
            if ($opt.Key -eq $choice) {
                & $opt.Action
                $matched = $true
                break
            }
        }

        if (-not $matched) {
            Write-Host "$Red Invalid choice. Please try again.$Reset"
            Start-Sleep -Seconds 1
        }

        if ($NoLoop) { return }
    }
}

# ── Header Helper ───────────────────────────────────────────────────────────
function Write-Header {
    param(
        [string]$Text,
        [int]$Width = 56
    )
    $border = "+" + ("-" * ($Width + 2)) + "+"
    Write-Host ""
    Write-Host "$Purple $border$Reset"
    Write-Host "$Purple '$Purple  $($Text.PadRight($Width)) $Purple'$Reset"
    Write-Host "$Purple $border$Reset"
}

# ── Registry Helper ─────────────────────────────────────────────────────────
function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Type,
        $Value,
        [string]$Message
    )

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -Force
        Write-Host "$Green[SUCCESS]$Reset $Message"
    }
    catch {
        Write-Host "$Red[FAILED]$Reset Failed to set $Name at $Path"
        Write-Host "Error: $_"
    }
}

# ── Restore Point Helper ───────────────────────────────────────────────────
function New-SafeRestorePoint {
    param(
        [string]$Description = "Simplify11 - Before System Tweaks"
    )
    Write-Host "`n$Purple Creating System Restore Point before applying tweaks...$Reset"
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "$Description $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "$Green[SUCCESS]$Reset System Restore Point created successfully."
    } catch {
        Write-Host "$Yellow[WARNING]$Reset Could not create restore point: $($_.Exception.Message)"
        Write-Host "$Yellow[WARNING]$Reset Proceeding without restore point. Consider creating one manually."
    }
    Write-Host ""
}

# ── Admin Check ─────────────────────────────────────────────────────────────
function Test-AdminRights {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ── Version Loader ─────────────────────────────────────────────────────────
function Get-AppVersion {
    param(
        [string]$RootPath
    )
    $versionFile = Join-Path $RootPath "config\version.json"
    if (Test-Path $versionFile) {
        $versionInfo = Get-Content $versionFile -Raw | ConvertFrom-Json
        return $versionInfo.version
    }
    return "unknown"
}

# Headless Winrift bootstrap: fetch Winrift if needed, then apply a profile in
# one non-interactive pass. Intended for autounattend FirstLogon and any scripted
# provisioning. PS 5.1-safe (no PS7 syntax) — it hands off to Winrift.ps1, which
# bootstraps PS7 itself.
#
# Profile resolution: $env:WINRIFT_PROFILE, then
# C:\Windows\Setup\Scripts\winrift-profile.json, then C:\Winrift\profile.json.

function Get-WinriftApplyRoot {
    param([string]$ScriptDirectory)

    # An extracted checkout or embedded copy must apply its own reviewed version.
    if ($ScriptDirectory) {
        $localRoot = Split-Path -Path $ScriptDirectory -Parent
        if ((Test-Path -LiteralPath (Join-Path $localRoot 'Winrift.ps1') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $localRoot 'scripts\Main.ps1') -PathType Leaf)) {
            return $localRoot
        }
    }

    # The standalone online path shares the release resolver, validation, locking,
    # and rollback implementation with the interactive launcher. Never reuse main.
    $launcher = Invoke-RestMethod -Uri 'https://github.com/emylfy/winrift/releases/latest/download/launch.ps1' -TimeoutSec 60 -ErrorAction Stop
    $root = & ([scriptblock]::Create([string]$launcher)) -DownloadOnly -Channel stable
    if (-not ($root -is [string]) -or -not $root -or
        -not (Test-Path -LiteralPath (Join-Path $root 'Winrift.ps1') -PathType Leaf)) {
        throw 'The stable launcher did not return a usable Winrift installation.'
    }
    return $root
}

$ErrorActionPreference = 'Continue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }

$profilePath = $env:WINRIFT_PROFILE
if (-not $profilePath) {
    foreach ($cand in @("C:\Windows\Setup\Scripts\winrift-profile.json", "C:\Winrift\profile.json")) {
        if (Test-Path $cand) { $profilePath = $cand; break }
    }
}
if (-not $profilePath -or -not (Test-Path $profilePath)) {
    Write-Host "Winrift apply: no profile found (set WINRIFT_PROFILE or place winrift-profile.json)." -ForegroundColor Yellow
    return
}

try {
    $extractPath = Get-WinriftApplyRoot -ScriptDirectory $PSScriptRoot
} catch {
    Write-Error "Winrift apply: $($_.Exception.Message)"
    throw
}

Write-Host "Applying Winrift profile: $profilePath" -ForegroundColor Cyan
& "$extractPath\Winrift.ps1" -Apply $profilePath -NoConfirm

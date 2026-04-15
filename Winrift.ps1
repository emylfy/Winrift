param(
    [switch]$DryRun,
    [switch]$NoConfirm,
    [switch]$Uninstall
)

# Thin entry point — PS 5.1 compatible (no ternary, no ??, no Start-ThreadJob).
# Ensures PowerShell 7 is available, then hands off to scripts/Main.ps1 which
# uses PS7 syntax freely. This file is the only .ps1 that PS 5.1 ever parses.

if ($PSVersionTable.PSVersion.Major -lt 7) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)

    $pwsh = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
    if (-not $pwsh) {
        $pwsh = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
        if (-not (Test-Path $pwsh)) { $pwsh = $null }
    }

    $mainPath = "$PSScriptRoot\scripts\Main.ps1"
    $extraArgs = @()
    if ($DryRun)    { $extraArgs += "-DryRun" }
    if ($NoConfirm) { $extraArgs += "-NoConfirm" }
    if ($Uninstall) { $extraArgs += "-Uninstall" }

    # Fast path: PS7 already installed — elevate directly into WT + pwsh (skip intermediate PS 5.1 window)
    if ($pwsh -and -not $isAdmin) {
        $hasWT = [bool](Get-Command wt.exe -ErrorAction SilentlyContinue)
        $pwshArgString = "-ExecutionPolicy Bypass -File `"$mainPath`" $($extraArgs -join ' ')".Trim()
        if ($hasWT) {
            Start-Process "wt.exe" -ArgumentList "pwsh.exe $pwshArgString" -Verb RunAs
        } else {
            Start-Process $pwsh -ArgumentList $pwshArgString -Verb RunAs
        }
        exit 0
    }

    # Slow path: PS7 not installed — need admin first to install it
    if (-not $isAdmin) {
        Write-Host "  Winrift requires PowerShell 7 and administrator privileges." -ForegroundColor Yellow
        Write-Host "  Requesting elevation..." -ForegroundColor Yellow
        $psArgs = @("-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
        $psArgs += $extraArgs
        try {
            Start-Process "powershell.exe" -ArgumentList $psArgs -Verb RunAs
        } catch {
            Write-Host "  Elevation cancelled or failed." -ForegroundColor Red
        }
        exit 0
    }

    # Admin PS 5.1 — install PS7 then relaunch
    . "$PSScriptRoot\scripts\RequirePwsh.ps1"
    $pwsh = Install-Pwsh
    if (-not $pwsh) { exit 1 }

    $pwshArgs = @("-ExecutionPolicy", "Bypass", "-File", $mainPath) + $extraArgs
    if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
        & wt.exe $pwsh @pwshArgs
    } else {
        & $pwsh @pwshArgs
    }
    exit $LASTEXITCODE
}

# Already running PS7+ — call Main.ps1 directly in the same process
& "$PSScriptRoot\scripts\Main.ps1" @PSBoundParameters

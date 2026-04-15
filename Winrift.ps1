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

    # Find existing pwsh
    $pwsh = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
    if (-not $pwsh) {
        $pwsh = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
        if (-not (Test-Path $pwsh)) {
            $pwsh = "$env:LOCALAPPDATA\Winrift\pwsh\pwsh.exe"
            if (-not (Test-Path $pwsh)) { $pwsh = $null }
        }
    }

    # Install portable PS7 if missing (no admin needed — goes to %LOCALAPPDATA%)
    if (-not $pwsh) {
        . "$PSScriptRoot\scripts\RequirePwsh.ps1"
        $pwsh = Install-Pwsh
        if (-not $pwsh) { exit 1 }
    }

    # Launch Main.ps1 in pwsh with admin elevation
    $mainPath = "$PSScriptRoot\scripts\Main.ps1"
    $extraArgs = @()
    if ($DryRun)    { $extraArgs += "-DryRun" }
    if ($NoConfirm) { $extraArgs += "-NoConfirm" }
    if ($Uninstall) { $extraArgs += "-Uninstall" }

    $pwshArgString = "-ExecutionPolicy Bypass -File `"$mainPath`" $($extraArgs -join ' ')".Trim()

    if ($isAdmin) {
        $hasWT = [bool](Get-Command wt.exe -ErrorAction SilentlyContinue)
        if ($hasWT) {
            & wt.exe $pwsh $pwshArgString.Split(' ')
        } else {
            & $pwsh @($pwshArgString.Split(' '))
        }
        exit $LASTEXITCODE
    }

    $hasWT = [bool](Get-Command wt.exe -ErrorAction SilentlyContinue)
    if ($hasWT) {
        Start-Process "wt.exe" -ArgumentList "$pwsh $pwshArgString" -Verb RunAs
    } else {
        Start-Process $pwsh -ArgumentList $pwshArgString -Verb RunAs
    }
    exit 0
}

# Already running PS7+ — call Main.ps1 directly in the same process
& "$PSScriptRoot\scripts\Main.ps1" @PSBoundParameters

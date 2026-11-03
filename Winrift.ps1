param(
    [switch]$DryRun,
    [switch]$NoConfirm,
    [switch]$Uninstall,
    [string]$Apply
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

    # Preserve argument boundaries. Main.ps1 handles elevation using this exact
    # PowerShell executable, including portable installations outside PATH.
    $mainPath = Join-Path $PSScriptRoot 'scripts\Main.ps1'
    $forwardArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $mainPath)
    if ($DryRun)    { $forwardArgs += '-DryRun' }
    if ($NoConfirm) { $forwardArgs += '-NoConfirm' }
    if ($Uninstall) { $forwardArgs += '-Uninstall' }
    if ($Apply)     { $forwardArgs += @('-Apply', $Apply) }
    & $pwsh @forwardArgs
    exit $LASTEXITCODE
}

# Already running PS7+ — call Main.ps1 directly in the same process
& "$PSScriptRoot\scripts\Main.ps1" @PSBoundParameters

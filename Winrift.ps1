param(
    [switch]$DryRun,
    [switch]$NoConfirm,
    [switch]$Uninstall,
    [string]$Apply
)

# Windows PowerShell 5.1-compatible entry point. Main.ps1 runs in PowerShell 7.
if ($PSVersionTable.PSVersion.Major -lt 7) {
    . "$PSScriptRoot\scripts\RequirePwsh.ps1"
    $pwsh = Install-Pwsh
    if (-not $pwsh) { exit 1 }

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

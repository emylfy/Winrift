# . "$PSScriptRoot\AdminLaunch.ps1"

function Start-UserProcess {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [string]$Arguments = "",

        [Parameter(Mandatory = $false)]
        [switch]$NoExit
    )
    $useWindowsTerminal = Get-Command wt.exe -ErrorAction SilentlyContinue

    $psArgs = @()
    if ($NoExit) { $psArgs += "-NoExit" }
    $psArgs += @("-ExecutionPolicy", "Bypass", "-File", $ScriptPath)
    if ($Arguments) { $psArgs += $Arguments.Split(' ') }

    $insideWT = $null -ne $env:WT_SESSION

    if ($useWindowsTerminal -and $insideWT) {
        # Inside WT: open as new tab in current window (no elevation)
        & wt.exe -w 0 new-tab powershell.exe @psArgs
    } elseif ($useWindowsTerminal) {
        # WT available: open new WT window (no elevation)
        & wt.exe powershell.exe @psArgs
    } else {
        Start-Process -FilePath "powershell.exe" -ArgumentList $psArgs
    }
}

function Start-AdminProcess {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [string]$Arguments = "",

        [Parameter(Mandatory = $false)]
        [switch]$NoExit
    )
    $useWindowsTerminal = Get-Command wt.exe -ErrorAction SilentlyContinue
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)

    $psArgs = @()
    if ($NoExit) { $psArgs += "-NoExit" }
    $psArgs += @("-ExecutionPolicy", "Bypass", "-File", $ScriptPath)
    if ($Arguments) { $psArgs += $Arguments.Split(' ') }

    $insideWT = $null -ne $env:WT_SESSION

    if ($useWindowsTerminal -and $isAdmin -and $insideWT) {
        # Already admin + inside WT: open as new tab in current window
        & wt.exe -w 0 new-tab powershell.exe @psArgs
    } elseif ($useWindowsTerminal -and $isAdmin) {
        # Admin but not inside WT: open new WT window
        & wt.exe powershell.exe @psArgs
    } elseif ($useWindowsTerminal) {
        # Not admin + WT: must elevate, opens new window (UAC restriction)
        $psArgString = ($psArgs | ForEach-Object { if ($_ -match ' ') { "`"$_`"" } else { $_ } }) -join ' '
        Start-Process -FilePath "wt.exe" -ArgumentList "powershell $psArgString" -Verb RunAs
    } else {
        $psArgString = ($psArgs | ForEach-Object { if ($_ -match ' ') { "`"$_`"" } else { $_ } }) -join ' '
        Start-Process -FilePath "powershell.exe" -ArgumentList $psArgString -Verb RunAs
    }
}

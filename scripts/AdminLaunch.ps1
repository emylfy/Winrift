# . "$PSScriptRoot\AdminLaunch.ps1"

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

    $psArguments = ""
    if ($NoExit) {
        $psArguments += "-NoExit "
    }

    $psArguments += "-ExecutionPolicy Bypass -File `"$ScriptPath`" $Arguments"

    $insideWT = $env:WT_SESSION -ne $null

    if ($useWindowsTerminal -and $isAdmin -and $insideWT) {
        # Already admin + inside WT: open as new tab in current window
        & wt.exe -w 0 new-tab powershell.exe $psArguments.Split(' ')
    } elseif ($useWindowsTerminal -and $isAdmin) {
        # Admin but not inside WT: open new WT window
        & wt.exe powershell.exe $psArguments.Split(' ')
    } elseif ($useWindowsTerminal) {
        # Not admin + WT: must elevate, opens new window (UAC restriction)
        Start-Process -FilePath "wt.exe" -ArgumentList "powershell $psArguments" -Verb RunAs
    } else {
        Start-Process -FilePath "powershell.exe" -ArgumentList $psArguments -Verb RunAs
    }
}

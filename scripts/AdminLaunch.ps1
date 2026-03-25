function Start-UserProcess {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @(),

        [Parameter(Mandatory = $false)]
        [switch]$NoExit
    )
    $useWindowsTerminal = Get-Command wt.exe -ErrorAction SilentlyContinue

    $psArgs = @()
    if ($NoExit) { $psArgs += "-NoExit" }
    $psArgs += @("-ExecutionPolicy", "Bypass", "-File", $ScriptPath)
    if ($Arguments.Count -gt 0) { $psArgs += $Arguments }

    $insideWT = $null -ne $env:WT_SESSION

    if ($useWindowsTerminal -and $insideWT) {
        & wt.exe -w 0 new-tab powershell.exe @psArgs
    } elseif ($useWindowsTerminal) {
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
        [string[]]$Arguments = @(),

        [Parameter(Mandatory = $false)]
        [switch]$NoExit
    )
    $useWindowsTerminal = Get-Command wt.exe -ErrorAction SilentlyContinue
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)

    $psArgs = @()
    if ($NoExit) { $psArgs += "-NoExit" }
    $psArgs += @("-ExecutionPolicy", "Bypass", "-File", $ScriptPath)
    if ($Arguments.Count -gt 0) { $psArgs += $Arguments }

    $insideWT = $null -ne $env:WT_SESSION

    if ($useWindowsTerminal -and $isAdmin -and $insideWT) {
        & wt.exe -w 0 new-tab powershell.exe @psArgs
    } elseif ($useWindowsTerminal -and $isAdmin) {
        & wt.exe powershell.exe @psArgs
    } elseif ($useWindowsTerminal) {
        $psArgString = ($psArgs | ForEach-Object { if ($_ -match ' ') { "`"$_`"" } else { $_ } }) -join ' '
        Start-Process -FilePath "wt.exe" -ArgumentList "powershell $psArgString" -Verb RunAs
    } else {
        $psArgString = ($psArgs | ForEach-Object { if ($_ -match ' ') { "`"$_`"" } else { $_ } }) -join ' '
        Start-Process -FilePath "powershell.exe" -ArgumentList $psArgString -Verb RunAs
    }
}

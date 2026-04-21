function Start-UserProcess {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @()
    )
    # Drop admin privileges using runas /trustlevel:0x20000 (basic user)
    $psArgs = @("-ExecutionPolicy", "Bypass", "-File", $ScriptPath)
    if ($Arguments.Count -gt 0) { $psArgs += $Arguments }
    $psArgString = ($psArgs | ForEach-Object { if ($_ -match ' ') { "`"$_`"" } else { $_ } }) -join ' '

    $useWT = Get-Command wt.exe -ErrorAction SilentlyContinue
    if ($useWT) {
        Start-Process "runas.exe" -ArgumentList "/trustlevel:0x20000 `"wt.exe pwsh.exe $psArgString`""
    } else {
        Start-Process "runas.exe" -ArgumentList "/trustlevel:0x20000 `"pwsh.exe $psArgString`""
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
        & wt.exe -w 0 new-tab pwsh.exe @psArgs
    } elseif ($useWindowsTerminal -and $isAdmin) {
        & wt.exe pwsh.exe @psArgs
    } elseif ($useWindowsTerminal) {
        $psArgString = ($psArgs | ForEach-Object { if ($_ -match ' ') { "`"$_`"" } else { $_ } }) -join ' '
        Start-Process -FilePath "wt.exe" -ArgumentList "pwsh $psArgString" -Verb RunAs
    } else {
        $psArgString = ($psArgs | ForEach-Object { if ($_ -match ' ') { "`"$_`"" } else { $_ } }) -join ' '
        Start-Process -FilePath "pwsh.exe" -ArgumentList $psArgString -Verb RunAs
    }
}

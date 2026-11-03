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
    # Resolve the running host, not a PATH-dependent pwsh.exe in a new UAC
    # environment. Encode the invocation so spaces, apostrophes, dollar signs
    # and Windows Terminal command separators remain literal argument data.
    $pwshPath = (Get-Process -Id $PID -ErrorAction Stop).Path
    if (-not $pwshPath -or -not (Test-Path -LiteralPath $pwshPath)) {
        throw 'Cannot resolve the running PowerShell executable.'
    }
    $literalPath = "'" + $ScriptPath.Replace("'", "''") + "'"
    $literalArgs = @()
    $expectValue = $false
    foreach ($argument in $Arguments) {
        if (-not $expectValue -and $argument -match '^-[A-Za-z][A-Za-z0-9]*$') {
            $literalArgs += $argument
            $expectValue = $argument -eq '-Apply'
        } else {
            $literalArgs += "'" + $argument.Replace("'", "''") + "'"
            $expectValue = $false
        }
    }
    $originSid=if($env:WINRIFT_ORIGIN_SID){$env:WINRIFT_ORIGIN_SID}else{[Security.Principal.WindowsIdentity]::GetCurrent().User.Value}
    if($originSid -notmatch '^S-\d(-\d+)+$'){throw 'Invalid original Windows user SID.'}
    $command = '$env:WINRIFT_ORIGIN_SID=''' + $originSid + '''; & ' + $literalPath
    if ($literalArgs.Count) { $command += ' ' + ($literalArgs -join ' ') }
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $psArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass')
    if ($NoExit) { $psArgs += '-NoExit' }
    $psArgs += @('-EncodedCommand', $encoded)
    # Use the inbox host for ShellExecute/UAC. On the target Windows system,
    # direct RunAs on the downloaded portable host fails with path-not-found,
    # while invoking it inside an elevated inbox host succeeds.
    $inbox = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $hostLiteral = "'" + $pwshPath.Replace("'", "''") + "'"
    $argLiterals = @($psArgs | ForEach-Object { "'" + $_.Replace("'", "''") + "'" })
    $bridge = '& ' + $hostLiteral + ' ' + ($argLiterals -join ' ')
    $bridgeEncoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($bridge))
    Start-Process -FilePath $inbox -ArgumentList @('-NoProfile', '-EncodedCommand', $bridgeEncoded) -Verb RunAs -ErrorAction Stop
}
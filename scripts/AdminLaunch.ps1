function ConvertTo-WinriftLaunchPath {
    param([string]$Path)

    if ($Path -notmatch '^(?:[A-Za-z]:[\\/]|\\\\)') {
        $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    }
    # Drive mappings (including Parallels Y:) belong to the unelevated token.
    # ShellExecute can start successfully even though the child cannot see Y:.
    if ($Path -match '^([A-Za-z]):[\\/]') {
        $drive = Get-PSDrive -Name $Matches[1] -PSProvider FileSystem -ErrorAction SilentlyContinue
        if ($drive.DisplayRoot -like '\\*') {
            return $drive.DisplayRoot.TrimEnd('\') + '\' + $Path.Substring(3)
        }
    }
    return $Path
}

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
        [switch]$NoExit,

        [switch]$InTerminal
    )
    # Resolve the running host, not a PATH-dependent pwsh.exe in a new UAC
    # environment. Encode the invocation so spaces, apostrophes, dollar signs
    # and Windows Terminal command separators remain literal argument data.
    $pwshPath = (Get-Process -Id $PID -ErrorAction Stop).Path
    if (-not $pwshPath -or -not (Test-Path -LiteralPath $pwshPath)) {
        throw 'Cannot resolve the running PowerShell executable.'
    }
    $pwshPath = ConvertTo-WinriftLaunchPath $pwshPath
    $ScriptPath = ConvertTo-WinriftLaunchPath $ScriptPath
    $literalPath = "'" + $ScriptPath.Replace("'", "''") + "'"
    $literalArgs = @()
    $expectValue = $false
    foreach ($argument in $Arguments) {
        if (-not $expectValue -and $argument -match '^-[A-Za-z][A-Za-z0-9]*$') {
            $literalArgs += $argument
            $expectValue = $argument -eq '-Apply'
        } else {
            if ($expectValue) { $argument = ConvertTo-WinriftLaunchPath $argument }
            $literalArgs += "'" + $argument.Replace("'", "''") + "'"
            $expectValue = $false
        }
    }
    $originSid=if($env:WINRIFT_ORIGIN_SID){$env:WINRIFT_ORIGIN_SID}else{[Security.Principal.WindowsIdentity]::GetCurrent().User.Value}
    if($originSid -notmatch '^S-\d(-\d+)+$'){throw 'Invalid original Windows user SID.'}
    $command = '$env:WINRIFT_ORIGIN_SID=''' + $originSid + '''; & ' + $literalPath
    if ($literalArgs.Count) { $command += ' ' + ($literalArgs -join ' ') }
    if ($InTerminal) { $command = '$env:WINRIFT_HOST_PID = $PID; ' + $command }
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
    # Start diagnostics before invoking the downloaded host or shared-folder script.
    # Native child failures do not throw in Windows PowerShell 5.1.
    $bridge = @'
$ErrorActionPreference = 'Stop'
$transcriptStarted = $false
try {
    $logDir = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Winrift\logs'
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    $log = Join-Path $logDir ('elevation_{0}_{1}.log' -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'), $PID)
    Start-Transcript -Path $log -ErrorAction Stop | Out-Null
    $transcriptStarted = $true
'@
    $bridge += "`n& " + $hostLiteral + ' ' + ($argLiterals -join ' ') + "`n"
    $bridge += @'
    if ($LASTEXITCODE) { throw "PowerShell exited with code $LASTEXITCODE." }
} catch {
    Write-Host "Winrift could not start: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
    if ($log) { Write-Host "Startup log: $log" }
    $null = Read-Host 'Press Enter to exit'
    exit 1
} finally {
    if ($transcriptStarted) { Stop-Transcript | Out-Null }
}
'@
    $bridgeEncoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($bridge))
    if ($InTerminal) {
        $terminal = Get-Command wt.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($terminal -and $pwshPath -notlike '*;*') {
            try {
                $terminalArgs = @('-w', 'new', 'new-tab', '--title', 'Winrift', ('"' + $pwshPath + '"')) + $psArgs
                Start-Process -FilePath $terminal.Source -ArgumentList $terminalArgs -ErrorAction Stop
                return
            } catch {
                Write-Warning "Windows Terminal could not start: $($_.Exception.Message)"
            }
        }

        # Only the system host and encoded data cross CMD's command-line parser.
        $cmd = Join-Path $env:SystemRoot 'System32\cmd.exe'
        $cmdArgs = '/d /s /c "title Winrift & "' + $inbox + '" -NoProfile -EncodedCommand ' + $bridgeEncoded + '"'
        Start-Process -FilePath $cmd -ArgumentList $cmdArgs -ErrorAction Stop
        return
    }
    $child = Start-Process -FilePath $inbox -ArgumentList @('-NoProfile', '-EncodedCommand', $bridgeEncoded) -Verb RunAs -Wait -PassThru -ErrorAction Stop
    if ($child) { return $child.ExitCode }
}

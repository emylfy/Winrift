function Get-WinriftFileSnapshot {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @{Exists=$false;Hash=$null} }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Expected a file: $Path" }
    return @{Exists=$true;Hash=(Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash}
}

function Write-WinriftFileBytes {
    param([string]$Path,[byte[]]$Bytes)
    [IO.Directory]::CreateDirectory((Split-Path $Path -Parent))|Out-Null
    $temp=$Path+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
    try {
        $stream=[IO.FileStream]::new($temp,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try{$stream.Write($Bytes,0,$Bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()}
        if([IO.File]::Exists($Path)){[IO.File]::Move($temp,$Path,$true)}else{[IO.File]::Move($temp,$Path)}
    }finally{if([IO.File]::Exists($temp)){[IO.File]::Delete($temp)}}
}

function Copy-WinriftJournaledFile {
    param([string]$Source,[string]$Destination,[string]$Label)
    $script:LastFileResult=@{Status='Pending';Error=$null}
    if($env:WINRIFT_DRY_RUN -eq '1'){Write-Log "[DRY-RUN] $Source -> $Destination";$script:LastFileResult.Status='DryRun';return}
    $record=$null
    try{
        $before=Get-WinriftFileSnapshot $Destination
        $proposed=Get-WinriftFileSnapshot $Source
        if(-not $proposed.Exists){throw "Source file missing: $Source"}
        if($before.Exists -and $before.Hash -eq $proposed.Hash){$script:LastFileResult.Status='AlreadyMatches';Write-Log "Already matches: $Destination" -Level SKIP;return}
        $record=New-WinriftActionRecord -Kind File -Label $Label -Target @{Path=$Destination} -Before $before -Proposed $proposed
        if($before.Exists){
            $backup=Join-Path (Get-WinriftStateRoot) "backups\$($record.id).bin"
            [IO.Directory]::CreateDirectory((Split-Path $backup -Parent))|Out-Null
            [IO.File]::Copy($Destination,$backup,$false)
            if((Get-WinriftFileSnapshot $backup).Hash -ne $before.Hash){throw 'Backup verification failed.'}
            $record.before.BackupPath=$backup
            # Keep compatibility with pre-journal backups without overwriting them.
            if(-not (Test-Path -LiteralPath "$Destination.bak")){[IO.File]::Copy($Destination,"$Destination.bak",$false)}
        }
        Save-WinriftActionRecord $record
        # Catch edits made while the preview/backup was being prepared.
        $current=Get-WinriftFileSnapshot $Destination
        if($current.Exists -ne $before.Exists -or $current.Hash -ne $before.Hash){throw 'File changed before replacement; preserved.'}
        Write-WinriftFileBytes $Destination ([IO.File]::ReadAllBytes($Source))
        if((Get-WinriftFileSnapshot $Destination).Hash -ne $proposed.Hash){throw 'Configuration hash verification failed.'}
        $record.status='Applied';$record.verification='File hash verified.'
        Save-WinriftActionRecord $record
        $script:LastFileResult.Status='Applied'
        Write-Log "$Label — file verified, versioned backup preserved." -Level SUCCESS
    }catch{
        $script:LastFileResult=@{Status='Failed';Error=$_.Exception.Message}
        if($record){$record.status='Failed';$record.error=$_.Exception.Message;try{Save-WinriftActionRecord $record}catch{Write-Warning 'File journal finalization failed; inspect stored history before retrying.'}}
        Write-Log "Configuration failed: $($script:LastFileResult.Error)" -Level ERROR
    }
}

function Restore-WinriftFileAction {
    param($Record)
    $path=$Record.target.Path
    $current=Get-WinriftFileSnapshot $path
    if($current.Exists -eq $Record.before.Exists -and $current.Hash -eq $Record.before.Hash){return 'AlreadyRestored'}
    if($current.Exists -ne $Record.proposed.Exists -or $current.Hash -ne $Record.proposed.Hash){return 'Conflict'}
    if($env:WINRIFT_DRY_RUN -eq '1'){return 'DryRun'}
    if($Record.before.Exists){
        $backup=Get-WinriftFileSnapshot $Record.before.BackupPath
        if(-not $backup.Exists -or $backup.Hash -ne $Record.before.Hash){throw 'Versioned backup missing or changed.'}
        Write-WinriftFileBytes $path ([IO.File]::ReadAllBytes($Record.before.BackupPath))
    }else{Remove-Item -LiteralPath $path -ErrorAction Stop}
    $after=Get-WinriftFileSnapshot $path
    if($after.Exists -ne $Record.before.Exists -or $after.Hash -ne $Record.before.Hash){throw 'File restoration verification failed.'}
    $Record.status='Undone';$Record.verification='Previous file hash verified.';Save-WinriftActionRecord $Record
    return 'Restored'
}
function Resolve-WinriftEditorCli {
    param([string]$Cli)
    if(-not $Cli){return $null}
    $command=Get-Command $Cli -ErrorAction SilentlyContinue
    if($command -and $command.Source){return $command.Source}
    $directories=@{code='Microsoft VS Code';cursor='cursor';windsurf='Windsurf';codium='VSCodium';trae='Trae'}
    if(-not $directories.ContainsKey($Cli)){return $null}
    foreach($root in @((Join-Path $env:LOCALAPPDATA 'Programs'),$env:ProgramFiles,${env:ProgramFiles(x86)})){
        if(-not $root){continue}
        foreach($relative in @("bin\$Cli.cmd","resources\app\bin\$Cli.cmd")){
            $candidate=Join-Path (Join-Path $root $directories[$Cli]) $relative
            if(Test-Path -LiteralPath $candidate -PathType Leaf){return $candidate}
        }
    }
    return $null
}
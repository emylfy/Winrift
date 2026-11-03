# Versioned state and action journal. No machine changes occur while loading.
function Get-WinriftStateRoot {
    if ($env:WINRIFT_STATE_ROOT) { return $env:WINRIFT_STATE_ROOT }
    $base = [Environment]::GetFolderPath('LocalApplicationData')
    if (-not $base) { $base = [IO.Path]::GetTempPath() }
    return Join-Path $base 'Winrift'
}

function Write-WinriftAtomicJson {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)]$Value)
    $directory = Split-Path $Path -Parent
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    $temp = Join-Path $directory ('.' + [guid]::NewGuid().ToString('N') + '.tmp')
    $json = $Value | ConvertTo-Json -Depth 40
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json)
        $stream = [IO.FileStream]::new($temp, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temp, $Path, "$Path.previous", $true) }
        else { [IO.File]::Move($temp, $Path) }
    } finally { if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) } }
}

function Read-WinriftJson {
    param([Parameter(Mandatory)][string]$Path)
    # Corrupt state is never silently replaced with an empty document.
    $value = [IO.File]::ReadAllText($Path) | ConvertFrom-Json -ErrorAction Stop
    if ($value.schemaVersion -ne 1) { throw "Unsupported Winrift state schema in $Path" }
    return $value
}

function Get-WinriftRegistrySnapshot {
    param([string]$Path, [string]$Name)
    if (-not (Test-Path -LiteralPath $Path)) { return @{ Exists = $false; Type = $null; Value = $null } }
    $key = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($Name -notin $key.GetValueNames()) { return @{ Exists = $false; Type = $null; Value = $null } }
    return @{
        Exists = $true
        Type = $key.GetValueKind($Name).ToString()
        Value = $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    }
}

function ConvertTo-WinriftRegistryValue {
    param([string]$Type, $Value)
    switch ($Type.ToLowerInvariant()) {
        'dword' {
            if ("$Value" -match '^0x') { return [Convert]::ToUInt32("$Value".Substring(2), 16).ToString() }
            if ([long]$Value -lt 0) { return ([long]$Value + 4294967296).ToString() }
            return ([uint32]$Value).ToString()
        }
        'qword' { return "$Value" }
        'binary' { return [Convert]::ToBase64String([byte[]]$Value) }
        'multistring' { return ConvertTo-Json -InputObject @($Value) -Compress }
        default { return [string]$Value }
    }
}

function Test-WinriftRegistrySnapshot {
    param($Left, $Right)
    if ([bool]$Left.Exists -ne [bool]$Right.Exists) { return $false }
    if (-not $Left.Exists) { return $true }
    if ($Left.Type -ne $Right.Type) { return $false }
    return (ConvertTo-WinriftRegistryValue $Left.Type $Left.Value) -ceq (ConvertTo-WinriftRegistryValue $Right.Type $Right.Value)
}

function New-WinriftActionRecord {
    param([string]$Kind, [string]$Label, $Target, $Before, $Proposed)
    return [ordered]@{
        schemaVersion = 1; id = [guid]::NewGuid().ToString('N')
        timestamp = [DateTimeOffset]::Now.ToString('o'); kind = $Kind
        label = $Label; target = $Target; before = $Before; proposed = $Proposed
        status = 'Pending'; verification = 'Not checked'; error = $null
    }
}

function Save-WinriftActionRecord {
    param($Record)
    $path = Join-Path (Get-WinriftStateRoot) "history\$($Record.id).json"
    Write-WinriftAtomicJson -Path $path -Value $Record
}

function Get-WinriftHistory {
    $directory = Join-Path (Get-WinriftStateRoot) 'history'
    foreach ($file in @(Get-ChildItem -LiteralPath $directory -Filter '*.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)) {
        try { Read-WinriftJson $file.FullName }
        catch { Write-Warning "History preserved but unreadable: $($file.Name): $($_.Exception.Message)" }
    }
}

function Restore-WinriftRegistryAction {
    param([Parameter(Mandatory)]$Record)
    if ($Record.kind -eq 'Organizer') { . "$PSScriptRoot\..\modules\customize\Organizer.ps1"; return Restore-WinriftOrganizerAction $Record }
    if ($Record.kind -eq 'File') { return Restore-WinriftFileAction $Record }
    if ($Record.kind -eq 'System') { return Restore-WinriftSystemAction $Record }
    if ($Record.kind -ne 'Registry') { throw 'This action is not a registry change.' }
    if ($Record.status -eq 'Undone') { return 'AlreadyRestored' }
    $current = Get-WinriftRegistrySnapshot $Record.target.Path $Record.target.Name
    if (Test-WinriftRegistrySnapshot $current $Record.before) { return 'AlreadyRestored' }
    $expected=if($Record.status -eq 'Failed' -and $null -ne $Record.observed){$Record.observed}else{$Record.proposed}
    if (-not (Test-WinriftRegistrySnapshot $current $expected)) { return 'Conflict' }
    if ($env:WINRIFT_DRY_RUN -eq '1') { return 'DryRun' }
    if ($Record.before.Exists) {
        Set-ItemProperty -LiteralPath $Record.target.Path -Name $Record.target.Name -Type $Record.before.Type -Value $Record.before.Value -ErrorAction Stop
    } else {
        Remove-ItemProperty -LiteralPath $Record.target.Path -Name $Record.target.Name -ErrorAction Stop
    }
    $after = Get-WinriftRegistrySnapshot $Record.target.Path $Record.target.Name
    if (-not (Test-WinriftRegistrySnapshot $after $Record.before)) { throw 'Previous registry state could not be verified.' }
    $Record.status = 'Undone'
    $Record.verification = 'Previous registry value and type verified; system effect not measured.'
    Save-WinriftActionRecord $Record
    return 'Restored'
}

function Show-WinriftActionHistory {
    param([string]$TargetPrefix)
    Import-WinriftLegacyRegistryBackups
    $records = @(Get-WinriftHistory | Where-Object { $_.kind -in @('Registry','System','File','Organizer') -and $_.status -in @('Applied', 'Pending', 'Failed') } | Sort-Object timestamp -Descending)
    if($TargetPrefix){$boundary=[IO.Path]::GetFullPath($TargetPrefix).TrimEnd('\')+'\';$records=@($records|Where-Object{$_.kind -eq 'File' -and $_.target.Path -and $_.target.Path.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)})}
    if (-not $records.Count) { Write-Log 'No supported action history yet.'; Wait-ForUser; return }
    $items = @()
    $date=$null
    for($i=0;$i -lt $records.Count;$i++){
        $timestamp=[DateTimeOffset]::MinValue
        $valid=[DateTimeOffset]::TryParse([string]$records[$i].timestamp,[ref]$timestamp)
        $recordDate=if($valid){$timestamp.ToString('yyyy-MM-dd')}else{'Legacy / unknown date'}
        if($recordDate -ne $date){$items+="--- $recordDate ---";$date=$recordDate}
        $time=if($valid){$timestamp.ToString('HH:mm')}else{''}
        $items+="$i › $time  $($records[$i].label)"
    }
    $items += @('---', 'B › Back')
    $choice = Show-InteractiveMenu -Title 'Undo Changes — Action History' -Items $items
    $index = 0
    if (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 0 -or $index -ge $records.Count) { return }
    $record = $records[$index]
    $expected=if($record.status -eq 'Failed' -and $null -ne $record.observed){$record.observed}else{$record.proposed}
    if ($record.kind -eq 'Organizer') {
        $conflict=$false
        foreach($entry in $record.before){
            $source=Get-WinriftFileSnapshot $entry.Source;$destination=Get-WinriftFileSnapshot $entry.Destination
            if(($source.Exists -and $source.Hash -ne $entry.Hash) -or ($destination.Exists -and $destination.Hash -ne $entry.Hash)){$conflict=$true}
        }
        $review=@("Archive: $($record.target.Archive)")+@($record.before|ForEach-Object{"$($_.Destination) -> $($_.Source)"})
    } elseif ($record.kind -eq 'File') {
        $current=Get-WinriftFileSnapshot $record.target.Path
        $conflict=($current.Hash -ne $record.proposed.Hash -or $current.Exists -ne $record.proposed.Exists) -and ($current.Hash -ne $record.before.Hash -or $current.Exists -ne $record.before.Exists)
        $review=@($record.target.Path,"Current hash: $($current.Hash)","Previous hash: $($record.before.Hash)","Backup: $($record.before.BackupPath)")
    } elseif ($record.kind -eq 'System') {
        $current = Get-WinriftSystemValue $record.target.Id
        $conflict = "$current" -ne "$expected" -and "$current" -ne "$($record.before)"
        $review = @($record.target.Id, "Current: $current", "Previous: $($record.before)")
    } else {
        $current = Get-WinriftRegistrySnapshot $record.target.Path $record.target.Name
        $conflict = -not (Test-WinriftRegistrySnapshot $current $expected) -and -not (Test-WinriftRegistrySnapshot $current $record.before)
        $review = @("$($record.target.Path)\$($record.target.Name)", "Current: $($current.Value) ($($current.Type))", "Previous: $($record.before.Value) ($($record.before.Type)); existed: $($record.before.Exists)")
    }
    if ($conflict) {
        Show-InfoBox 'Undo conflict' ($review + 'This value changed after Winrift. It will not be overwritten.')
        Wait-ForUser; return
    }
    $confirm = Show-InteractiveMenu -Title 'Review Changes' -Items ($review + @('---', 'Y › Restore Previous State', 'N › Back'))
    if ($confirm -eq 'Y') {
        try { $result = Restore-WinriftRegistryAction $record; Write-Log "Undo result: $result" }
        catch { Write-Log "Undo failed: $($_.Exception.Message)" -Level ERROR }
        Wait-ForUser
    }
}
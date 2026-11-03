
$script:AuditQueue = [System.Collections.Generic.List[hashtable]]::new()

function Add-AuditEntry {
    param([string]$Path, [string]$Name, [string]$Type, $Value, [string]$Message)
    $current = $null
    $snapshot = Get-WinriftRegistrySnapshot $Path $Name
    try {
        $prop = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $prop -and $null -ne $prop.$Name) { $current = $prop.$Name }
    } catch { $null = $_ }
    $script:AuditQueue.Add(@{
        Path = $Path; Name = $Name; Type = $Type; Value = $Value
        Message = $Message; Current = $current; CurrentSnapshot = $snapshot
    })
}

function Show-AuditTable {
    if ($script:AuditQueue.Count -eq 0) {
        Write-Log -Message "No changes to preview." -Level INFO
        return $false
    }
    $changed = @($script:AuditQueue | Where-Object { Test-WinriftQueuedChange $_ })
    $skipped = $script:AuditQueue.Count - $changed.Count
    if ($changed.Count -eq 0) {
        Write-Log -Message "All values already match. Nothing to apply." -Level INFO
        $script:AuditQueue.Clear()
        return $false
    }

    $items = @()
    foreach ($e in $changed) {
        $cur = ($null -eq $e.Current) ? "(not set)" : "$($e.Current)"
        $new = "$($e.Value)"
        $items += "$($e.Message)  $Dim$cur$Reset $Yellow->$Reset $Green$new$Reset"
    }
    if ($skipped -gt 0) { $items += "---"; $items += "$Dim$skipped value(s) already match — skipped$Reset" }
    $items += "---"
    $items += "$($changed.Count) change(s) to apply"
    $items += "---"
    $items += "Y › Apply changes"
    $items += "N › Cancel"

    $choice = Show-InteractiveMenu -Title "Review Changes" -HideKeys -Items $items
    return ($choice -eq "Y")
}

function Invoke-AuditedApply {
    $changed = @($script:AuditQueue | Where-Object { Test-WinriftQueuedChange $_ })
    foreach ($e in $changed) {
        if ($e.Kind -eq 'System') { Invoke-WinriftSystemAction $e; continue }
        Set-RegistryValue -Path $e.Path -Name $e.Name -Type $e.Type -Value $e.Value -Message $e.Message
    }
    $script:AuditQueue.Clear()
}

function Clear-AuditQueue {
    $script:AuditQueue.Clear()
}

$script:TweakBackupEntries = [System.Collections.Generic.List[hashtable]]::new()
$script:DesiredStateEntries = [System.Collections.Generic.List[hashtable]]::new()
$script:DesiredStateCategory = "Uncategorized"
$_baseDir = $env:LOCALAPPDATA ?? $env:USERPROFILE ?? [System.IO.Path]::GetTempPath()
$script:TweakBackupDir = Join-Path $_baseDir "Winrift\tweaks"
$script:DesiredStateDir = Join-Path $_baseDir "Winrift\tweaks"

function Start-TweakSession {
    # Don't clear if entries already accumulated this session
    $script:DesiredStateCategory = "Uncategorized"
}

function Invoke-TweakApply {
    # Shared collect→preview→apply pattern used by Power, GPU, and similar single-category callers.
    # Returns $true if the user confirmed and changes were applied, $false if cancelled.
    param(
        [Parameter(Mandatory)][string]$Category,
        [Parameter(Mandatory)][scriptblock]$CollectBlock,
        [scriptblock]$AfterApply = $null,
        [ref]$SessionStarted = $null
    )
    $script:CollectMode = $true
    $script:DesiredStateCategory = $Category
    try { & $CollectBlock } finally { $script:CollectMode = $false }

    if (Show-AuditTable) {
        $alreadyStarted = ($SessionStarted -ne $null -and $SessionStarted.Value) -or $script:TweakSessionStarted
        if (-not $alreadyStarted) {
            New-SafeRestorePoint
            Start-TweakSession
            $script:TweakSessionStarted = $true
            if ($SessionStarted -ne $null) { $SessionStarted.Value = $true }
        }
        Invoke-AuditedApply
        if ($AfterApply) { & $AfterApply }
        return $true
    } else {
        Clear-AuditQueue
        return $false
    }
}

function Set-RegistryValue {
    param([string]$Path, [string]$Name, [string]$Type, $Value, [string]$Message)
    if ($script:CollectMode) {
        Add-AuditEntry -Path $Path -Name $Name -Type $Type -Value $Value -Message $Message
        return
    }
    $script:LastActionResult = @{ Status = 'Pending'; Error = $null }
    if ($env:WINRIFT_DRY_RUN -eq '1') {
        $script:LastActionResult.Status = 'DryRun'
        Write-Log "[DRY-RUN] $Message"
        return
    }
    $record = $null
    try {
        $before = Get-WinriftRegistrySnapshot $Path $Name
        $proposed = @{ Exists = $true; Type = $Type; Value = $Value }
        if (Test-WinriftRegistrySnapshot $before $proposed) {
            $script:LastActionResult.Status = 'AlreadyMatches'
            Write-Log "Already matches: $Name" -Level SKIP
            return
        }
        $record = New-WinriftActionRecord -Kind Registry -Label $Message -Target @{ Path = $Path; Name = $Name } -Before $before -Proposed $proposed
        # Durable previous state is required BEFORE any write, including failures.
        Save-WinriftActionRecord $record
        if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
        Set-ItemProperty -LiteralPath $Path -Name $Name -Type $Type -Value $Value -Force -ErrorAction Stop
        $after = Get-WinriftRegistrySnapshot $Path $Name
        if (-not (Test-WinriftRegistrySnapshot $after $proposed)) { throw "Registry verification failed for $Name (value or type mismatch)." }
        $record.status = 'Applied'
        $record.verification = 'Registry value and type verified; system effect not measured.'
        Save-WinriftActionRecord $record
        $script:TweakBackupEntries.Add(@{
            Path = $Path; Name = $Name; PrevValue = $before.Value; PrevType = $before.Type
            Existed = $before.Exists; AppliedValue = $after.Value; AppliedType = $after.Type
        })
        $script:DesiredStateEntries.Add(@{ Path = $Path; Name = $Name; Value = $Value; Type = $Type; Category = $script:DesiredStateCategory })
        $script:LastActionResult.Status = 'Applied'
        Write-Log "$Message — registry value/type verified; effect not measured." -Level SUCCESS
    } catch {
        $script:LastActionResult = @{ Status = 'Failed'; Error = $_.Exception.Message }
        if ($null -ne $record) {
            $record.status = 'Failed'; $record.error = $_.Exception.Message
            try { $record.observed=Get-WinriftRegistrySnapshot $Path $Name } catch {}
            try { Save-WinriftActionRecord $record } catch { Write-Warning 'Journal finalization failed. Inspect stored history before retrying.' }
        }
        Write-Log "Failed to set $Name at ${Path}: $($script:LastActionResult.Error)" -Level ERROR
    }
}
function Save-TweakBackup {
    if ($script:TweakBackupEntries.Count -eq 0) { return $null }
    [System.IO.Directory]::CreateDirectory($script:TweakBackupDir) | Out-Null
    $backup = @{
        timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        entries   = @($script:TweakBackupEntries)
    }
    $fileName = "backup_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')_$([guid]::NewGuid().ToString('N')).json"
    $filePath = Join-Path $script:TweakBackupDir $fileName
    Write-WinriftAtomicJson -Path $filePath -Value $backup
    Write-Log -Message "Tweak backup saved: $filePath ($($script:TweakBackupEntries.Count) entries)" -Level SUCCESS
}

function Save-DesiredState {
    if ($script:DesiredStateEntries.Count -eq 0) { return }
    [System.IO.Directory]::CreateDirectory($script:DesiredStateDir) | Out-Null
    $filePath = Join-Path $script:DesiredStateDir "desired_state.json"

    $existing = @()
    if (Test-Path $filePath) {
        try {
            $json = Get-Content $filePath -Raw | ConvertFrom-Json
            if ($json.entries) { $existing = @($json.entries) }
        } catch {
            Write-Log -Message "Could not read existing desired state, starting fresh." -Level WARNING
        }
    }

    $lookup = [ordered]@{}
    foreach ($entry in $existing) {
        $key = "$($entry.Path)|$($entry.Name)"
        $lookup[$key] = $entry
    }

    $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
    foreach ($entry in $script:DesiredStateEntries) {
        $key = "$($entry.Path)|$($entry.Name)"
        $lookup[$key] = @{
            Path      = $entry.Path
            Name      = $entry.Name
            Value     = $entry.Value
            Type      = $entry.Type
            Category  = $entry.Category
            UpdatedAt = $now
        }
    }

    $state = @{
        version     = 1
        lastUpdated = $now
        entries     = @($lookup.Values)
    }
    Write-WinriftAtomicJson -Path $filePath -Value $state
    Write-Log -Message "Desired state updated: $filePath ($($lookup.Count) total entries)" -Level SUCCESS
}

function Import-WinriftLegacyRegistryBackups {
    if(-not(Test-Path -LiteralPath $script:TweakBackupDir)){return}
    $desired=@{}
    $desiredFile=Join-Path $script:DesiredStateDir 'desired_state.json'
    if(Test-Path -LiteralPath $desiredFile){try{foreach($entry in (Get-Content -LiteralPath $desiredFile -Raw|ConvertFrom-Json).entries){$desired["$($entry.Path)|$($entry.Name)"]=$entry}}catch{Write-Log 'Legacy desired state is unreadable and has been preserved.' -Level WARNING}}
    $history=@(Get-WinriftHistory)
    foreach($file in @(Get-ChildItem -LiteralPath $script:TweakBackupDir -Filter 'backup_*.json')){
        try{
            $backup=Get-Content -LiteralPath $file.FullName -Raw|ConvertFrom-Json -ErrorAction Stop
            $index=0
            foreach($entry in @($backup.entries)){
                $key="$($entry.Path)|$($entry.Name)";$after=$desired[$key]
                if('AppliedValue' -in $entry.PSObject.Properties.Name){$after=@{Value=$entry.AppliedValue;Type=$entry.AppliedType}}
                if(-not $after){$index++;continue}
                if(@($history|Where-Object{$_.target.Path -eq $entry.Path -and $_.target.Name -eq $entry.Name -and "$($_.before.Value)" -eq "$($entry.PrevValue)" -and "$($_.proposed.Value)" -eq "$($after.Value)"}).Count){$index++;continue}
                $identity=$file.FullName+'|'+$index
                $id=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($identity))).Substring(0,32).ToLowerInvariant()
                $destination=Join-Path (Get-WinriftStateRoot) "history\$id.json"
                if(Test-Path -LiteralPath $destination){$index++;continue}
                $record=New-WinriftActionRecord -Kind Registry -Label ("Legacy backup (application unverified): "+$entry.Name) -Target @{Path=$entry.Path;Name=$entry.Name} -Before @{Exists=[bool]$entry.Existed;Type=$entry.PrevType;Value=$entry.PrevValue} -Proposed @{Exists=$true;Type=$after.Type;Value=$after.Value}
                $record.id=$id;$record.timestamp=$backup.timestamp;$record.verification='Imported backup; original application was not verified.'
                Save-WinriftActionRecord $record
                $index++
            }
        }catch{Write-Log "Legacy backup retained but not migrated: $($file.Name)" -Level WARNING}
    }
}

function Restore-TweakBackup {
    if(-not(Test-Path -LiteralPath $script:TweakBackupDir)){Write-Log 'No tweak backups found.';Wait-ForUser;return}
    Import-WinriftLegacyRegistryBackups
    Show-WinriftActionHistory
}
function Invoke-DesiredStateApply {
    # Applies desired-state entries (Path/Name/Value/Type/Category) via
    # Set-RegistryValue, which records a rollback backup + desired state and
    # honours dry-run. Callers persist with Save-TweakBackup / Save-DesiredState.
    # Shared by profile apply and profile import. Returns the count applied.
    param(
        [Parameter(Mandatory)][object[]]$Entries,
        [string]$DefaultCategory = "Profile"
    )
    $applied = 0
    foreach ($e in $Entries) {
        if (-not $e.Path -or -not $e.Name) { continue }
        $script:DesiredStateCategory = $e.Category ? $e.Category : $DefaultCategory
        $type = $e.Type ? $e.Type : "DWord"
        Set-RegistryValue -Path $e.Path -Name $e.Name -Type $type -Value $e.Value -Message "Apply: $($e.Name)"
        if ($script:LastActionResult.Status -eq 'Applied') { $applied++ }
    }
    return $applied
}

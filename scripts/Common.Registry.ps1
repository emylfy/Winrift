
$script:AuditQueue = [System.Collections.Generic.List[hashtable]]::new()

function Add-AuditEntry {
    param([string]$Path, [string]$Name, [string]$Type, $Value, [string]$Message)
    $current = $null
    try {
        $prop = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $prop -and $null -ne $prop.$Name) { $current = $prop.$Name }
    } catch { $null = $_ }
    $script:AuditQueue.Add(@{
        Path = $Path; Name = $Name; Type = $Type; Value = $Value
        Message = $Message; Current = $current
    })
}

function Show-AuditTable {
    if ($script:AuditQueue.Count -eq 0) {
        Write-Log -Message "No changes to preview." -Level INFO
        return $false
    }
    $changed = @($script:AuditQueue | Where-Object { "$($_.Current)" -ne "$($_.Value)" })
    $skipped = $script:AuditQueue.Count - $changed.Count
    if ($changed.Count -eq 0) {
        Write-Log -Message "All values already match. Nothing to apply." -Level INFO
        $script:AuditQueue.Clear()
        return $false
    }

    $items = @()
    foreach ($e in $changed) {
        $cur = if ($null -eq $e.Current) { "(not set)" } else { "$($e.Current)" }
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
    $changed = @($script:AuditQueue | Where-Object { "$($_.Current)" -ne "$($_.Value)" })
    foreach ($e in $changed) {
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
$_baseDir = $env:USERPROFILE
if (-not $_baseDir) { $_baseDir = $env:HOME }
if (-not $_baseDir) { $_baseDir = [System.IO.Path]::GetTempPath() }
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
    param (
        [string]$Path,
        [string]$Name,
        [string]$Type,
        $Value,
        [string]$Message
    )

    if ($script:CollectMode) {
        Add-AuditEntry -Path $Path -Name $Name -Type $Type -Value $Value -Message $Message
        return
    }

    if ($env:WINRIFT_DRY_RUN -eq "1") {
        Write-Log -Message "[DRY-RUN] $Message" -Level INFO
        return
    }

    try {
        # Capture previous value for rollback
        $existed = Test-Path $Path
        $prevValue = $null
        $prevType = $null
        if ($existed) {
            $prop = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($null -ne $prop -and $null -ne $prop.$Name) {
                $prevValue = $prop.$Name
                $prevType = (Get-Item $Path).GetValueKind($Name).ToString()
            }
        }
        $script:TweakBackupEntries.Add(@{
            Path      = $Path
            Name      = $Name
            PrevValue = $prevValue
            PrevType  = $prevType
            Existed   = ($null -ne $prevValue)
        })

        if (-not $existed) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -Force -ErrorAction Stop

        $written = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
        if ($null -eq $written) {
            Write-Log -Message "Failed to verify $Name at $Path - value not found after write" -Level ERROR
        } else {
            $script:DesiredStateEntries.Add(@{
                Path     = $Path
                Name     = $Name
                Value    = $Value
                Type     = $Type
                Category = $script:DesiredStateCategory
            })
            Write-Log -Message $Message -Level SUCCESS
        }
    }
    catch {
        Write-Log -Message "Failed to set $Name at $Path. Error: $_" -Level ERROR
    }
}

function Save-TweakBackup {
    if ($script:TweakBackupEntries.Count -eq 0) { return $null }
    [System.IO.Directory]::CreateDirectory($script:TweakBackupDir) | Out-Null
    $backup = @{
        timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        entries   = @($script:TweakBackupEntries)
    }
    $fileName = "backup_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
    $filePath = Join-Path $script:TweakBackupDir $fileName
    $backup | ConvertTo-Json -Depth 5 | Set-Content -Path $filePath -Encoding UTF8
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
    $state | ConvertTo-Json -Depth 5 | Set-Content -Path $filePath -Encoding UTF8
    Write-Log -Message "Desired state updated: $filePath ($($lookup.Count) total entries)" -Level SUCCESS
}

function Restore-TweakBackup {
    if (-not (Test-Path $script:TweakBackupDir)) {
        Write-Log -Message "No tweak backups found." -Level INFO
        Wait-ForUser
        return
    }

    $backups = Get-ChildItem -Path $script:TweakBackupDir -Filter "backup_*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($backups.Count -eq 0) {
        Write-Log -Message "No tweak backups found." -Level INFO
        Wait-ForUser
        return
    }

    $menuItems = @()
    for ($i = 0; $i -lt [math]::Min($backups.Count, 10); $i++) {
        $b = Get-Content $backups[$i].FullName -Raw | ConvertFrom-Json
        $count = $b.entries.Count
        $menuItems += "$($i + 1) › $($b.timestamp) ($count changes)"
    }
    $cancelIdx = [math]::Min($backups.Count, 10) + 1
    $menuItems += "---"
    $menuItems += "$cancelIdx › Cancel"

    $choice = Show-InteractiveMenu -Title "Restore Tweak Backup" -Items $menuItems
    if ($null -eq $choice -or $choice -eq "$cancelIdx") { return }

    $idx = 0
    if (-not ([int]::TryParse($choice, [ref]$idx)) -or $idx -lt 1 -or $idx -gt $backups.Count) { return }

    $selected = Get-Content $backups[$idx - 1].FullName -Raw | ConvertFrom-Json
    $restored = 0
    $errors = 0

    foreach ($entry in $selected.entries) {
        try {
            if ($entry.Existed -and $null -ne $entry.PrevValue) {
                $type = if ($entry.PrevType) { $entry.PrevType } else { "String" }
                Set-ItemProperty -Path $entry.Path -Name $entry.Name -Type $type -Value $entry.PrevValue -Force
                $restored++
            } elseif (-not $entry.Existed) {
                Remove-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
                $restored++
            }
        } catch {
            $errors++
        }
    }

    Write-Log -Message "Restored $restored of $($selected.entries.Count) registry values. Errors: $errors" -Level $(if ($errors -eq 0) { 'SUCCESS' } else { 'WARNING' })
    Write-Log -Message "A system restart is recommended for changes to take effect." -Level INFO
    Wait-ForUser
}

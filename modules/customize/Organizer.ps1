. "$PSScriptRoot\..\..\scripts\Common.ps1"
$excludeList = @(
    "Accentcolorizer",
    "CapCut",
    "Character Map",
    "Command Prompt",
    "Component Services",
    "Computer Management",
    "Control Panel",
    "Disk Cleanup",
    "Event Viewer",
    "Git",
    "Install Additional Tools for Node.js",
    "iSCsI Initiator",
    "Memory Diagnostics Tool",
    "Node.js",
    "ODBC Data Sources",
    "Performance Monitor",
    "postgreSQL",
    "RecoveryDrive",
    "Registry Editor",
    "Resource Monitor",
    "Uninstall",
    "Windows Powershell"
)
function Get-WinriftOrganizerPlan {
    param([string[]]$Roots)
    $destinations=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($root in $Roots){
        if(-not(Test-Path -LiteralPath $root -PathType Container)){continue}
        $resolvedRoot=[IO.Path]::GetFullPath($root).TrimEnd('\')+'\'
        foreach($folder in @(Get-ChildItem -LiteralPath $root -Directory)){
            if($folder.Name -match '^(Windows|Microsoft|Steam|Accessibility|Accessories)$' -or $folder.Name -in $excludeList){continue}
            foreach($file in @(Get-ChildItem -LiteralPath $folder.FullName -File -Recurse -ErrorAction SilentlyContinue)){
                if($file.Extension -notin @('.lnk','.url','.appref-ms') -or $file.BaseName -like 'Uninstall*'){continue}
                $excluded=$false
                foreach($term in $excludeList){if($file.BaseName -like "*$term*"){$excluded=$true;break}}
                if($excluded){continue}
                $source=[IO.Path]::GetFullPath($file.FullName)
                $destination=[IO.Path]::GetFullPath((Join-Path $root $file.Name))
                if(-not $source.StartsWith($resolvedRoot,[StringComparison]::OrdinalIgnoreCase) -or -not $destination.StartsWith($resolvedRoot,[StringComparison]::OrdinalIgnoreCase)){throw 'Organizer path escaped the selected Start Menu directory.'}
                if(Test-Path -LiteralPath $destination){Write-Log "Organizer conflict; preserved existing destination: $destination" -Level WARNING;continue}
                if(-not $destinations.Add($destination)){Write-Log "Duplicate shortcut destination preserved: $destination" -Level WARNING;continue}
                [pscustomobject]@{Source=$source;Destination=$destination;Hash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash;Root=$root}
            }
        }
    }
}

function Invoke-WinriftOrganizer {
    Initialize-Logging -ModuleName organizer 6>$null
    $currentUser = [Environment]::GetFolderPath('Programs')
    $allUsers = [Environment]::GetFolderPath('CommonPrograms')
    $plan = @(Get-WinriftOrganizerPlan @($currentUser, $allUsers) 6>$null)
    if (-not $plan.Count) { Write-Log 'No shortcuts to move.'; Wait-ForUser; return }

    $folders = @(
        $plan | Group-Object -Property {
            $relative = [IO.Path]::GetRelativePath($_.Root, $_.Source)
            Join-Path $_.Root ($relative.Split([IO.Path]::DirectorySeparatorChar)[0])
        } | ForEach-Object {
            [pscustomobject]@{
                Name = [IO.Path]::GetFileName($_.Name)
                Scope = if ($_.Group[0].Root -eq $currentUser) { 'Current user' } else { 'All users' }
                Shortcuts = $_.Group
            }
        } | Sort-Object Name, Scope
    )
    $sameName = $folders | Group-Object -Property Name -AsHashTable -AsString
    $items = @('--- Move shortcuts to the top level of the Start menu.', '---')
    $defaults = @($false, $false)
    $details = @{}
    for ($i = 0; $i -lt $folders.Count; $i++) {
        $folder = $folders[$i]
        $label = $folder.Name
        if ($sameName[$folder.Name].Count -gt 1) { $label += " ($($folder.Scope))" }
        $count = $folder.Shortcuts.Count
        $unit = if ($count -eq 1) { 'shortcut' } else { 'shortcuts' }
        $details[$items.Count] = @(
            $folder.Scope
            $folder.Shortcuts | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_.Source) } | Sort-Object
        )
        $items += "$i › $label  ($count $unit)"
        $defaults += ($count -le 5 -and $folder.Name -notlike 'Parallels Shared Applications*')
    }

    do {
        $picker = @{
            Title = 'Organize Start Menu Shortcuts'
            Items = $items
            Defaults = $defaults
            Descriptions = $details
            DetailsOnly = $true
            DetailsTitle = 'Shortcuts in Folder'
            Hint = 'Space toggle  → view shortcuts  Enter review  Esc back'
        }
        $selected = @(Show-MultiSelect @picker)
        if (-not $selected.Count) { return }
        $plan = @(foreach ($key in $selected) { $folders[[int]$key].Shortcuts })
        $counts = @(foreach ($group in ($plan | Group-Object -Property Root)) {
            $scope = if ($group.Name -eq $currentUser) { 'Current user' } else { 'All users' }
            "$($scope): $($group.Count)"
        })
        $description = if ($plan.Count -eq 1) { 'Move 1 shortcut to the top level.' } else { "Move $($plan.Count) shortcuts to the top level." }
        $review = @($description) + $counts + @('A backup is created before moving shortcuts.', '---', 'A › Back Up and Apply', 'E › Edit Selection')
        $choice = Show-InteractiveMenu -Title 'Review Shortcut Moves' -Items $review
        if ($choice -eq 'E') {
            for ($i = 0; $i -lt $folders.Count; $i++) { $defaults[$i + 2] = [string]$i -in $selected }
        }
    } while ($choice -eq 'E')
    if ($choice -ne 'A') { return }
    Clear-Host
    if($env:WINRIFT_DRY_RUN -eq '1'){Write-Log "[DRY-RUN] Archive and move $($plan.Count) shortcuts";Wait-ForUser;return}
    $id=[guid]::NewGuid().ToString('N')
    $archiveDir=Join-Path (Get-WinriftStateRoot) "organizer\$id"
    [IO.Directory]::CreateDirectory($archiveDir)|Out-Null
    # A manifest maps each unique archive filename to its exact original path.
    # It avoids duplicate Programs directory names in the two user scopes.
    $manifest=@();$index=0
    foreach($entry in $plan){
        $backup=Join-Path $archiveDir "$index.bin"
        [IO.File]::Copy($entry.Source,$backup,$false)
        if((Get-FileHash -LiteralPath $backup).Hash -ne $entry.Hash){throw 'Organizer backup hash mismatch. Nothing moved.'}
        $manifest+=@{Source=$entry.Source;Destination=$entry.Destination;Hash=$entry.Hash;ArchiveEntry="$index.bin"}
        $index++
    }
    Write-WinriftAtomicJson -Path (Join-Path $archiveDir 'manifest.json') -Value @{schemaVersion=1;entries=$manifest}
    $zip=Join-Path (Get-WinriftStateRoot) "organizer\$id.zip"
    Compress-Archive -LiteralPath @(Get-ChildItem -LiteralPath $archiveDir -File|ForEach-Object FullName) -DestinationPath $zip -ErrorAction Stop
    $record=New-WinriftActionRecord -Kind Organizer -Label 'Organize Start Menu shortcuts' -Target @{Archive=$zip;BackupDirectory=$archiveDir} -Before $manifest -Proposed $manifest
    $record.id=$id;Save-WinriftActionRecord $record
    $errors=@()
    foreach($entry in $manifest){
        try{
            if(Test-Path -LiteralPath $entry.Destination){throw 'Destination appeared after preview.'}
            if((Get-FileHash -LiteralPath $entry.Source).Hash -ne $entry.Hash){throw 'Source changed after preview.'}
            # Paths were resolved and checked inside their explicit Start Menu root.
            Move-Item -LiteralPath $entry.Source -Destination $entry.Destination -ErrorAction Stop
            if((Get-FileHash -LiteralPath $entry.Destination).Hash -ne $entry.Hash){throw 'Moved shortcut hash mismatch.'}
        }catch{$errors+="$($entry.Source): $($_.Exception.Message)"}
    }
    $record.status=if($errors.Count){'Failed'}else{'Applied'}
    $record.error=$errors -join "`n";$record.verification='Moved shortcuts checked by hash; archive retained.'
    Save-WinriftActionRecord $record
    Write-Log "Organizer finished. Planned: $($manifest.Count). Errors: $($errors.Count). Archive: $zip" -Quiet
    foreach ($errorText in $errors) { Write-Log $errorText -Level ERROR -Quiet }
    $moved = $manifest.Count - $errors.Count
    $summary = if ($moved -eq 1) { '1 shortcut moved.' } else { "$moved shortcuts moved." }
    $items = @($summary, 'Undo Changes → Action History')
    if ($errors.Count) { $items += "$($errors.Count) moves need review. See Help → Open Logs." }
    Show-InfoBox -Title 'Organizer Results' -Items $items
    Wait-ForUser
}

function Restore-WinriftOrganizerAction {
    param($Record)
    $conflicts=@()
    foreach($entry in $Record.before){
        $source=Get-WinriftFileSnapshot $entry.Source
        $destination=Get-WinriftFileSnapshot $entry.Destination
        if($source.Exists -and $source.Hash -ne $entry.Hash){$conflicts+=$entry.Source}
        if($destination.Exists -and $destination.Hash -ne $entry.Hash){$conflicts+=$entry.Destination}
    }
    if($conflicts.Count){return 'Conflict'}
    if($env:WINRIFT_DRY_RUN -eq '1'){return 'DryRun'}
    $backupDir=$Record.target.BackupDirectory
    if(-not(Test-Path -LiteralPath $backupDir)){
        $backupDir=Join-Path (Get-WinriftStateRoot) ('organizer\restore_'+$Record.id)
        Expand-Archive -LiteralPath $Record.target.Archive -DestinationPath $backupDir -ErrorAction Stop
    }
    foreach($entry in $Record.before){
        $backup=Join-Path $backupDir $entry.ArchiveEntry
        if((Get-WinriftFileSnapshot $backup).Hash -ne $entry.Hash){throw 'Organizer archive entry missing or changed.'}
    }
    foreach($entry in $Record.before){
        if(-not(Test-Path -LiteralPath $entry.Source)){Write-WinriftFileBytes $entry.Source ([IO.File]::ReadAllBytes((Join-Path $backupDir $entry.ArchiveEntry)))}
        if(Test-Path -LiteralPath $entry.Destination){Remove-Item -LiteralPath $entry.Destination -ErrorAction Stop}
    }
    foreach($entry in $Record.before){if((Get-WinriftFileSnapshot $entry.Source).Hash -ne $entry.Hash -or (Test-Path -LiteralPath $entry.Destination)){throw 'Organizer restoration verification failed.'}}
    $Record.status='Undone';$Record.verification='Original shortcut paths restored from verified archive entries.';Save-WinriftActionRecord $Record
    return 'Restored'
}

if($MyInvocation.InvocationName -ne '.'){Invoke-WinriftOrganizer}
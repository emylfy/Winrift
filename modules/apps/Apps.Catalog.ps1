function Get-WinriftCatalog {
    $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $lookup = [ordered]@{}
    $names = @{ Development='Developer Apps'; DesktopTools='Utilities'; Utilities='Utilities'; Browsers='Browsers'; Communications='Communication'; Productivity='Productivity'; CreativeMedia='Media & Creative'; Games='Games' }
    foreach ($file in Get-ChildItem (Join-Path $root 'config\bundles') -Filter '*.ubundle' | Sort-Object Name) {
        $bundle = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
        foreach ($package in @($bundle.packages)) {
            if ($package.ManagerName -ne 'Winget') { continue }
            $category = $names[$file.BaseName]
            if ($lookup.Contains($package.Id)) { continue }
            $lookup[$package.Id] = [pscustomobject]@{ Id=$package.Id; Name=$package.Name; Category=$category; ManagerName='Winget'; Source=$package.Source }
        }
    }
    foreach ($font in @(@{Id='DEVCOM.JetBrainsMonoNerdFont';Name='JetBrains Mono Nerd Font'}, @{Id='SourceFoundry.HackFonts';Name='Hack Fonts'})) {
        $lookup[$font.Id] = [pscustomobject]@{Id=$font.Id;Name=$font.Name;Category='Fonts';ManagerName='Winget';Source='winget'}
    }
    return @($lookup.Values)
}

function Get-WinriftAppQueue {
    $path=Join-Path (Get-WinriftStateRoot) 'apps\queue.json'
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    $state=Read-WinriftJson $path
    return @($state.packages | Where-Object { $_ })
}

function Save-WinriftAppQueue {
    param([object[]]$Packages)
    $deduplicated=@($Packages | Group-Object Id | ForEach-Object { $_.Group[0] })
    Write-WinriftAtomicJson -Path (Join-Path (Get-WinriftStateRoot) 'apps\queue.json') -Value @{schemaVersion=1;packages=$deduplicated}
}

function Get-InstalledAndBrokenIds {
    $installed=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $broken=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    if(Get-Command winget -ErrorAction SilentlyContinue) {
        $output=& winget list --accept-source-agreements --disable-interactivity 2>&1
        foreach($line in $output) {
            if($line -match '^.+?\s{2,}([A-Za-z0-9][\w.-]*\.[A-Za-z0-9][\w.-]*|[A-Za-z0-9]{12,14})\s{2,}\S+') { $null=$installed.Add($Matches[1]) }
        }
    }
    # Unknown version is still installed. No forced reinstall is inferred.
    Write-Output -NoEnumerate $installed
    Write-Output -NoEnumerate $broken
}

function Show-WinriftAppPicker {
    param([string]$Category='All', [string]$Search='')
    $packages=@(Get-WinriftCatalog | Where-Object {
        ($Category -eq 'All' -or $_.Category -eq $Category -or ($Category -eq 'Command Line' -and $_.Id -match 'Git|Terminal|PowerShell|Fastfetch|FFmpeg|astral-sh|NodeJS|WSL|GoLang|PlatformTools|scrcpy|OhMyPosh')) -and
        (-not $Search -or $_.Name.IndexOf($Search,[StringComparison]::OrdinalIgnoreCase) -ge 0 -or $_.Id.IndexOf($Search,[StringComparison]::OrdinalIgnoreCase) -ge 0)
    } | Sort-Object Name)
    if (-not $packages.Count) { Write-Log 'No matching curated apps.'; Wait-ForUser; return }
    $installed,$unknownVersion=Get-InstalledAndBrokenIds
    $queue=@(Get-WinriftAppQueue)
    $items=@(); $defaults=@(); $disabled=@(); $markers=@(); $details=@{}
    for($i=0;$i -lt $packages.Count;$i++) {
        $package=$packages[$i]; $isInstalled=$installed.Contains($package.Id)
        $items+="$($package.Id) › $($package.Name)"
        $defaults+=(-not $isInstalled -and $package.Id -in $queue.Id)
        $disabled+=$isInstalled; $markers+=$(if($isInstalled){'✓'}else{''})
        $details[$i]=@($package.Id, "Category: $($package.Category)", $(if($isInstalled){'Installed; version may be unknown. Reinstallation is not selected.'}else{'Not detected by winget. Review before installation.'}))
    }
    $changed={
        param($keys)
        $retained=@(Get-WinriftAppQueue | Where-Object { $_.Id -notin $packages.Id })
        $chosen=@($packages | Where-Object { $_.Id -in $keys })
        Save-WinriftAppQueue -Packages @($retained+$chosen)
    }
    $selection=@(Show-MultiSelect -Title $Category -Items $items -Defaults $defaults -Disabled $disabled -Markers $markers -Descriptions $details -OnSelectionChanged $changed)
    if ($selection.Count) { Show-WinriftAppQueue }
}

function Invoke-WinriftQueuedInstall {
    param([object[]]$Packages, [switch]$Upgrade)
    $remaining=@(Get-WinriftAppQueue)
    $results=@()
    foreach($package in $Packages) {
        if($env:WINRIFT_DRY_RUN -eq '1') {
            $results+=@{Id=$package.Id;Status='DryRun';Error=$null}
            Write-Log "[DRY-RUN] $(if($Upgrade){'Upgrade'}else{'Install'}) $($package.Id)"
            continue
        }
        $status='Failed'; $errorText=$null
        try {
            if($package.ManagerName -and $package.ManagerName -ne 'Winget') { throw "Unsupported manager: $($package.ManagerName)" }
            $source=if ($package.Source -eq 'msstore') { 'msstore' } else { 'winget' }
            & winget show --id $package.Id --exact --source $source --accept-source-agreements --disable-interactivity 2>&1 | Out-Null
            if($LASTEXITCODE -ne 0) { throw 'Package ID is unavailable or unsupported on the current source/system.' }
            if($Upgrade) {
                & winget upgrade --id $package.Id --exact --source $source --accept-source-agreements --accept-package-agreements --disable-interactivity --silent 2>&1 | Out-Host
                if($LASTEXITCODE -ne 0) { throw "winget upgrade exit code $LASTEXITCODE" }
                $status='Completed'
            } elseif(Install-WingetPackage -PackageId $package.Id -Name $package.Name -Source $source) { $status='Completed' }
            else { throw 'winget installation did not complete successfully.' }
        } catch { $errorText=$_.Exception.Message; Write-Log "$($package.Id): $errorText" -Level ERROR }
        $results+=@{Id=$package.Id;Status=$status;Error=$errorText}
        if($status -eq 'Completed' -and -not $Upgrade) {
            $remaining=@($remaining | Where-Object Id -NE $package.Id)
            Save-WinriftAppQueue $remaining
        }
        Write-WinriftAtomicJson -Path (Join-Path (Get-WinriftStateRoot) 'apps\last-results.json') -Value @{schemaVersion=1;timestamp=[DateTimeOffset]::Now.ToString('o');results=$results}
    }
    return ,$results
}

function Show-WinriftAppQueue {
    $queue=@(Get-WinriftAppQueue)
    if(-not $queue.Count) { return }
    $rows=@($queue | ForEach-Object { "$($_.Name) — $($_.Id)" })
    $choice=Show-InteractiveMenu -Title 'Review Selected Apps' -Items ($rows+@('---','Y › Install Selected','U › Open in UniGetUI','N › Back'))
    if($choice -eq 'U') { Export-WinriftQueueToUniGetUI $queue; return }
    if($choice -ne 'Y') { return }
    $results=Invoke-WinriftQueuedInstall $queue
    Show-InfoBox -Title 'App Results' -Items @($results | ForEach-Object { "$($_.Id): $($_.Status) $($_.Error)" })
    $failed=@($results | Where-Object Status -EQ Failed)
    if($failed.Count) {
        $retry=Show-InteractiveMenu -Title 'App Results' -NoClear -Items @('R › Retry Failed Items','N › Back')
        if($retry -eq 'R') { $null=Invoke-WinriftQueuedInstall @($queue | Where-Object { $_.Id -in $failed.Id }); Wait-ForUser }
    } else { Wait-ForUser }
}

function Import-WinriftAppBundle {
    $path=Read-Host 'Bundle file to import (full path)'
    if(-not $path) { return }
    try {
        $bundle=Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $supported=@($bundle.packages|Where-Object ManagerName -EQ Winget)
        $unsupported=@($bundle.packages|Where-Object ManagerName -NE Winget)
        if(-not $bundle.packages) { throw 'This file has no supported bundle package list.' }
        $rows=@($supported|ForEach-Object{"$($_.Name) — $($_.Id) (Winget)"})
        $rows+=@($unsupported|ForEach-Object{"UNSUPPORTED: $($_.Id) — $($_.ManagerName). Will not be imported."})
        $choice=Show-InteractiveMenu -Title 'Review Bundle Import' -Items ($rows+@('---','Y › Add Supported Apps to Queue','N › Back'))
        if($choice -eq 'Y') { Save-WinriftAppQueue -Packages @(@(Get-WinriftAppQueue)+$supported); Show-WinriftAppQueue }
    } catch { Write-Log "Bundle import failed: $($_.Exception.Message)" -Level ERROR; Wait-ForUser }
}

function Show-WinriftAppUpdates {
    Write-Log 'Scope: winget-source updates. Store apps use Microsoft Store updating.'
    if(-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Log 'winget is unavailable.' -Level WARNING; Wait-ForUser; return }
    $preview=& winget upgrade --source winget --accept-source-agreements --disable-interactivity 2>&1
    if($LASTEXITCODE -ne 0) { Show-InfoBox 'Update Preview Unavailable' @($preview); Wait-ForUser; return }
    $packages=@()
    foreach($line in $preview) {
        if($line -match '^(.+?)\s{2,}([A-Za-z0-9][\w.-]*\.[A-Za-z0-9][\w.-]*)\s{2,}\S+\s+\S+') {
            $packages+=[pscustomobject]@{Id=$Matches[2];Name=$Matches[1].Trim();ManagerName='Winget'}
        }
    }
    if(-not $packages.Count) { Show-InfoBox 'Update Installed Apps' @($preview); Wait-ForUser; return }
    $items=@($packages|ForEach-Object{"$($_.Id) › $($_.Name)"})
    $selected=@(Show-MultiSelect -Title 'Select App Updates' -Items $items)
    if(-not $selected.Count) { return }
    $choice=Show-InteractiveMenu -Title 'Review App Updates' -Items (@($preview)+@('---','Y › Update Selected','N › Back'))
    if($choice -eq 'Y') { $results=Invoke-WinriftQueuedInstall @($packages|Where-Object{$_.Id -in $selected}) -Upgrade; Show-InfoBox 'Update Results' @($results|ForEach-Object{"$($_.Id): $($_.Status) $($_.Error)"}); Wait-ForUser }
}

function Show-AppCategoryMenu {
    try {
    Invoke-MenuLoop -Title 'Install Your Apps' -Items @(
        'S › Search Apps                      ›', 'C › Command Line                     ›',
        'D › Developer Apps                   ›', 'U › Utilities                        ›',
        'B › Browsers                         ›', 'M › Communication                    ›',
        'P › Productivity                     ›', 'V › Media & Creative                 ›',
        'G › Games                            ›', 'F › Fonts                            ›',
        'A › Browse All Apps                  ›', 'W › Update Installed Apps            ›',
        'I › Import Bundle                    ›', '---',
        'N › Continue to App Configuration    ›', '0 › Back to Menu'
    ) -Actions @{
        'S'={ $query=Read-Host 'Search curated apps'; if($query){Show-WinriftAppPicker -Search $query} }
        'C'={ Show-WinriftAppPicker 'Command Line' }; 'D'={ Show-WinriftAppPicker 'Developer Apps' }
        'U'={ Show-WinriftAppPicker Utilities }; 'B'={ Show-WinriftAppPicker Browsers }
        'M'={ Show-WinriftAppPicker Communication }; 'P'={ Show-WinriftAppPicker Productivity }
        'V'={ Show-WinriftAppPicker 'Media & Creative' }; 'G'={ Show-WinriftAppPicker Games }
        'F'={ Show-WinriftAppPicker Fonts }; 'A'={ Show-WinriftAppPicker All }
        'W'={ Show-WinriftAppUpdates }; 'I'={ Import-WinriftAppBundle }
        'N'={ Show-WinriftAppConfiguration }
    } -ExitKey '0' -HideKeys -OnTab { Show-WinriftAppQueue } -HintProvider {
        $count=@(Get-WinriftAppQueue).Count
        if($count){ "Selected: $count  Tab: queue  Enter: open  ←/Esc: back" } else { '↑↓: navigate  Enter: open  ←/Esc: back' }
    }
    }catch{
        Write-Log "App menu could not continue: $($_.Exception.Message)" -Level ERROR
        try{$null=Get-WinriftAppQueue;Wait-ForUser;return}catch{}
        $path=Join-Path (Get-WinriftStateRoot) 'apps\queue.json'
        $previous=$null
        try{$previous=Read-WinriftJson "$path.previous"}catch{}
        $items=@('The unreadable queue will be preserved before recovery.')
        if($previous){$items+='P › Restore Previous Queue'}
        $items+=@('R › Start Empty Queue','N › Back')
        $choice=Show-InteractiveMenu -Title 'Recover App Queue' -Items $items
        if($choice -notin @('P','R')){return}
        if(Test-Path -LiteralPath $path){[IO.File]::Copy($path,($path+'.corrupt_'+[guid]::NewGuid().ToString('N')),$false)}
        $packages=if($choice -eq 'P' -and $previous){@($previous.packages)}else{@()}
        Save-WinriftAppQueue -Packages $packages
        Show-AppCategoryMenu
    }
}
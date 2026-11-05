# One portable setup format. Legacy formats are read explicitly, never rewritten.
function Get-WinriftSetupConfigDefinitions {
    $map=Get-WinriftConfigMap
    $map.starship=@{Name='Starship';Target=(Join-Path $env:USERPROFILE '.config');Files=@('starship.toml');TargetNames=$null;Group='Terminal'}
    foreach($key in @('terminal','pwsh','pwsh5','ohmyposh','fastfetch')){$map[$key].Group='Terminal'}
    $map.glazewm.Group='GlazeWM';$map.vscode.Group='Editors';$map.vscode.Cli='code'
    foreach($entry in @(@{Key='cursor';Directory='Cursor';Cli='cursor'},@{Key='windsurf';Directory='Windsurf';Cli='windsurf'},@{Key='vscodium';Directory='VSCodium';Cli='codium'},@{Key='trae';Directory='Trae';Cli='trae'})){
        $map[$entry.Key]=@{Name=$entry.Directory;Target=(Join-Path $env:APPDATA ($entry.Directory+'\User'));Files=@('settings.json');TargetNames=$null;Group='Editors';Cli=$entry.Cli}
    }
    foreach($key in @('vscode','cursor','windsurf','vscodium','trae')){$resolved=Resolve-WinriftEditorCli $map[$key].Cli;if($resolved){$map[$key].Cli=$resolved}}
    return $map
}

function New-WinriftSetup {
    return [pscustomobject]@{
        schemaVersion=1;kind='Winrift.Setup';createdAt=[DateTimeOffset]::Now.ToString('o')
        sections=[pscustomobject]@{Windows=@();Apps=@();Configurations=@()}
        migrationNotes=@()
    }
}

function Get-WinriftSupportedRegistryTargets {
    $targets=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $script:SupportedRegistryTypes=@{}
    . "$PSScriptRoot\..\system\Tweaks.Universal.ps1"
    . "$PSScriptRoot\..\security\Privacy.ps1"
    $savedQueue=$script:AuditQueue;$savedMode=$script:CollectMode
    $script:AuditQueue=[Collections.Generic.List[hashtable]]::new();$script:CollectMode=$true
    try{
        Invoke-SystemLatencyTweaks;Invoke-InputDeviceTweaks;Invoke-SSDTweaks;Invoke-GPUTweaks
        Invoke-NetworkTweaks;Invoke-CPUTweaks;Invoke-PowerTweaks;Invoke-SystemResponsivenessTweaks
        Invoke-BootOptimizationTweaks;Invoke-UIResponsivenessTweaks;Invoke-MemoryTweaks
        Invoke-SystemMaintenanceTweaks;Invoke-DirectXTweaks
        foreach($entry in $script:AuditQueue){if($entry.Path){$null=$targets.Add("$($entry.Path)|$($entry.Name)");$script:SupportedRegistryTypes["$($entry.Path)|$($entry.Name)"]=$(if($entry.Type){$entry.Type}else{'DWord'})}}
        foreach($entry in (Get-WinriftPrivacyManifest).Registry){$null=$targets.Add("$($entry.Path)|$($entry.Name)");$script:SupportedRegistryTypes["$($entry.Path)|$($entry.Name)"]=$(if($entry.Type){$entry.Type}else{'DWord'})}
        foreach($name in @('ShowFrequent','ShowRecent')){$null=$targets.Add("HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer|$name");$script:SupportedRegistryTypes["HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer|$name"]='DWord'}
        foreach($name in @('sShortDate','sShortTime','sTimeFormat')){$null=$targets.Add("HKCU:\Control Panel\International|$name");$script:SupportedRegistryTypes["HKCU:\Control Panel\International|$name"]='String'}
    }finally{$script:AuditQueue=$savedQueue;$script:CollectMode=$savedMode}
    Write-Output -NoEnumerate $targets
}

function ConvertTo-WinriftSetup {
    param([Parameter(Mandatory)]$Value)
    if($Value.kind -eq 'Winrift.Setup'){
        if($Value.schemaVersion -ne 1 -or -not $Value.sections){throw 'Unsupported setup schema.'}
        return $Value
    }
    if($null -eq $Value.tweaks -and $null -eq $Value.apps -and $null -eq $Value.configs){throw 'Unrecognized legacy profile format.'}
    $setup=New-WinriftSetup
    $setup.migrationNotes=@('Imported legacy declarative profile. Original file is preserved.')
    $setup.sections.Windows=@($Value.tweaks|Where-Object{$_})
    $setup.sections.Apps=@($Value.apps|Where-Object{$_}|ForEach-Object{if($_ -is [string]){[pscustomobject]@{Id=$_;Name=$_;ManagerName='Winget';Source='winget'}}else{$_}})
    $setup.sections.Configurations=@($Value.configs|Where-Object{$_}|ForEach-Object{[pscustomobject]@{Id=[string]$_;UseBundledDefaults=$true;Files=@();Extensions=@()}})
    if($Value.privacy){$setup.migrationNotes+='Legacy privacy flag was retained as a migration note. Run Privacy Setup separately and review its complete scope.'}
    return $setup
}

function Read-WinriftSetup {
    param([string]$Path)
    if(Test-Path -LiteralPath $Path -PathType Container){return ConvertFrom-WinriftLegacyFolder $Path}
    $file=Get-Item -LiteralPath $Path -ErrorAction Stop
    if($file.Length -gt 20MB){throw 'Setup file is larger than the supported 20 MiB limit.'}
    $value=Get-Content -LiteralPath $Path -Raw -ErrorAction Stop|ConvertFrom-Json -ErrorAction Stop
    return ConvertTo-WinriftSetup $value
}

function ConvertFrom-WinriftLegacyFolder {
    param([string]$Path)
    if(-not(Test-Path -LiteralPath (Join-Path $Path 'profile.json'))){throw 'Legacy folder is missing profile.json.'}
    $setup=New-WinriftSetup;$setup.migrationNotes=@('Imported legacy folder. Original files and backups are preserved.')
    $desired=Join-Path $Path 'desired_state.json'
    if(Test-Path -LiteralPath $desired){$setup.sections.Windows=@((Get-Content -LiteralPath $desired -Raw|ConvertFrom-Json).entries)}
    $apps=Join-Path $Path 'apps.json'
    if(Test-Path -LiteralPath $apps){
        $export=Get-Content -LiteralPath $apps -Raw|ConvertFrom-Json
        foreach($source in $export.Sources){foreach($package in $source.Packages){$setup.sections.Apps+=@{Id=$package.PackageIdentifier;Name=$package.PackageIdentifier;ManagerName='Winget';Source=$source.SourceDetails.Name}}}
    }
    $files=@(
        @{Name='terminal.json';Id='terminal';Target='settings.json'},@{Name='Microsoft.PowerShell_profile.ps1';Id='pwsh';Target='Microsoft.PowerShell_profile.ps1'},
        @{Name='zen.toml';Id='ohmyposh';Target='zen.toml'},@{Name='fastfetch.jsonc';Id='fastfetch';Target='config.jsonc'},@{Name='glazewm.yaml';Id='glazewm';Target='config.yaml'},
        @{Name='Code-settings.json';Id='vscode';Target='settings.json'},@{Name='Cursor-settings.json';Id='cursor';Target='settings.json'},@{Name='Windsurf-settings.json';Id='windsurf';Target='settings.json'},
        @{Name='VSCodium-settings.json';Id='vscodium';Target='settings.json'},@{Name='Trae-settings.json';Id='trae';Target='settings.json'}
    )
    foreach($entry in $files){
        $file=Join-Path $Path $entry.Name
        if(Test-Path -LiteralPath $file){$setup.sections.Configurations+=@{Id=$entry.Id;Files=@(@{Name=$entry.Target;Content=[Convert]::ToBase64String([IO.File]::ReadAllBytes($file));Hash=(Get-FileHash -LiteralPath $file).Hash});Extensions=@()}}
    }
    if(Test-Path -LiteralPath (Join-Path $Path 'extensions.txt')){$setup.migrationNotes+='Legacy extensions.txt has no reliable editor identity. It was preserved; choose the target editor manually.'}
    return $setup
}

function Get-WinriftSetupSystemIds {
    return @('Trim.NTFS','Trim.ReFS','LastAccess','MMAgent.ApplicationPreLaunch','MMAgent.PageCombining','Accessibility.StickyKeys','Accessibility.ToggleKeys','Accessibility.Keyboard Response','MenuDelay')
}

function Get-WinriftSetupSystemProposedValue {
    param($Entry)
    if($Entry.Id -notin (Get-WinriftSetupSystemIds)){throw 'Unsupported system action ID.'}
    if($Entry.Id.StartsWith('Accessibility.')){
        if($Entry.Value -isnot [bool]){throw 'Accessibility hotkey state must be Boolean.'}
        $flags=Get-WinriftSystemValue $Entry.Id
        return $(if($Entry.Value){[int]$flags -bor 4}else{[int]$flags -band (-bnot 4)})
    }
    if($Entry.Id.StartsWith('MMAgent.') -and $Entry.Value -isnot [bool]){throw 'MMAgent state must be Boolean.'}
    return $Entry.Value
}
function Test-WinriftSetupContent {
    param([Parameter(Mandatory)]$Setup)
    if($Setup.schemaVersion -ne 1 -or $Setup.kind -ne 'Winrift.Setup' -or -not $Setup.sections){throw 'Unsupported setup format.'}
    foreach($name in @('Windows','Apps','Configurations')){if($name -notin $Setup.sections.PSObject.Properties.Name){throw "Setup is missing section $name"}}
    $map=Get-WinriftSetupConfigDefinitions
    foreach($config in @($Setup.sections.Configurations)){
        if(-not $map.ContainsKey($config.Id)){continue}
        if($config.UseBundledDefaults){continue}
        $definition=$map[$config.Id]
        $allowed=if($definition.TargetNames){@($definition.TargetNames)}else{@($definition.Files)}
        foreach($file in @($config.Files)){
            if($file.Name -notin $allowed){throw "Unsupported filename in $($config.Id): $($file.Name)"}
            $bytes=[Convert]::FromBase64String($file.Content)
            if($bytes.Length -gt 5MB){throw 'Configuration file exceeds the size limit.'}
            if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)) -ne $file.Hash){throw "Configuration checksum mismatch: $($file.Name)"}
        }
    }
}
function Get-WinriftSetupPreview {
    param($Setup,[string[]]$Sections)
    Test-WinriftSetupContent $Setup
    $targets=Get-WinriftSupportedRegistryTargets
    $map=Get-WinriftSetupConfigDefinitions
    foreach($note in @($Setup.migrationNotes)){if($note){"Migration: $note"}}
    if('Windows' -in $Sections){foreach($entry in @($Setup.sections.Windows)){
        if($entry.Kind -eq 'System'){"System: $($entry.Id) -> $($entry.Value)";continue}
        $supported=$targets.Contains("$($entry.Path)|$($entry.Name)")
        "$(if(-not $supported){'UNSUPPORTED — skipped: '})$($entry.Path)\$($entry.Name) -> $($entry.Value) ($($entry.Type))"
    }}
    if('Apps' -in $Sections){foreach($app in @($Setup.sections.Apps)){"App: $($app.Id) [$($app.Source)]"}}
    if('Configurations' -in $Sections){foreach($config in @($Setup.sections.Configurations)){
        if(-not $map.ContainsKey($config.Id)){"UNSUPPORTED configuration — skipped: $($config.Id)";continue}
        "Configuration: $($map[$config.Id].Name). Versioned backup before replacement."
        foreach($file in @($config.Files)){"  $($file.Name) -> $($map[$config.Id].Target)"}
        if($config.UseBundledDefaults){'  Legacy profile requests bundled defaults, not a captured prior configuration.'}
        foreach($extension in @($config.Extensions)){"  Extension: $extension"}
    }}
    'Only supported settings, app IDs and configuration files are included. Review custom configs for embedded credentials before transfer.'
}

function Invoke-WinriftSetupApply {
    param([Parameter(Mandatory)]$Setup,[string[]]$Sections=@('Windows','Apps','Configurations'))
    Test-WinriftSetupContent $Setup
    $results=@();$targets=Get-WinriftSupportedRegistryTargets
    if('Windows' -in $Sections){foreach($entry in @($Setup.sections.Windows)){
        if($entry.Kind -eq 'System'){
            try{
                $value=Get-WinriftSetupSystemProposedValue $entry
                Add-WinriftSystemAction -Id $entry.Id -Value $value -Message "Restore setup: $($entry.Id)"
                $results+=@{Action=$entry.Id;Status=$script:LastActionResult.Status}
            }catch{$results+=@{Action=$entry.Id;Status='Unsupported or unavailable'}}
            continue
        }
        if(-not $targets.Contains("$($entry.Path)|$($entry.Name)")){$results+=@{Action=$entry.Name;Status='Unsupported'};continue}
        if($entry.Type -and $entry.Type -ne $script:SupportedRegistryTypes["$($entry.Path)|$($entry.Name)"]){$results+=@{Action=$entry.Name;Status='Unsupported registry type'};continue}
        $type=$script:SupportedRegistryTypes["$($entry.Path)|$($entry.Name)"]
        Set-RegistryValue -Path $entry.Path -Name $entry.Name -Type $type -Value $entry.Value -Message "Restore setup: $($entry.Name)"
        $results+=@{Action=$entry.Name;Status=$script:LastActionResult.Status}
    };$null=Save-TweakBackup;$null=Save-DesiredState}
    if('Apps' -in $Sections -and @($Setup.sections.Apps).Count){
        . "$PSScriptRoot\..\apps\Apps.ps1"
        $appResults=Invoke-WinriftQueuedInstall @($Setup.sections.Apps)
        foreach($result in $appResults){$results+=@{Action=$result.Id;Status=$result.Status}}
    }
    if('Configurations' -in $Sections){
        $map=Get-WinriftSetupConfigDefinitions
        foreach($config in @($Setup.sections.Configurations)){
            if(-not $map.ContainsKey($config.Id)){$results+=@{Action=$config.Id;Status='Unsupported'};continue}
            $definition=$map[$config.Id]
            if($config.UseBundledDefaults){
                $arguments=@{SourceDir=$definition.SourceDir;FileNames=$definition.Files;TargetDir=$definition.Target;ConfigName=$definition.Name;Reviewed=$true}
                if($definition.TargetNames){$arguments.TargetFileNames=$definition.TargetNames}
                Copy-ConfigFiles @arguments
                foreach($fileResult in $script:LastConfigResults){$results+=@{Action=$config.Id;Status=$fileResult.Status}}
                continue
            }
            foreach($file in @($config.Files)){
                $allowedNames=if($definition.TargetNames){@($definition.TargetNames)}else{@($definition.Files)}
                if($file.Name -notin $allowedNames){$results+=@{Action="$($config.Id)/$($file.Name)";Status='Unsupported filename'};continue}
                $bytes=[Convert]::FromBase64String($file.Content)
                if($bytes.Length -gt 5MB){throw 'Configuration exceeds the 5 MiB file limit.'}
                $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
                if($hash -ne $file.Hash){throw "Setup configuration hash mismatch: $($file.Name)"}
                if($env:WINRIFT_DRY_RUN -eq '1'){$results+=@{Action="$($config.Id)/$($file.Name)";Status='DryRun'};continue}
                $stage=Join-Path (Get-WinriftStateRoot) ('staging\'+[guid]::NewGuid().ToString('N'))
                [IO.Directory]::CreateDirectory($stage)|Out-Null
                $source=Join-Path $stage $file.Name
                try{
                    [IO.File]::WriteAllBytes($source,$bytes)
                    Copy-WinriftJournaledFile -Source $source -Destination (Join-Path $definition.Target $file.Name) -Label "Restore $($definition.Name)"
                    $results+=@{Action="$($config.Id)/$($file.Name)";Status=$script:LastFileResult.Status}
                }finally{if(Test-Path -LiteralPath $source){Remove-Item -LiteralPath $source}}
            }
            if(@($config.Extensions).Count){
                if(-not $definition.Cli -or -not(Get-Command $definition.Cli -ErrorAction SilentlyContinue)){$results+=@{Action="$($config.Id) extensions";Status='Unavailable editor CLI'};continue}
                foreach($extension in $config.Extensions){
                    if($extension -notmatch '^[A-Za-z0-9][A-Za-z0-9-]*\.[A-Za-z0-9][A-Za-z0-9._-]*$'){$results+=@{Action=$extension;Status='Unsupported extension ID'};continue}
                    if($env:WINRIFT_DRY_RUN -eq '1'){$results+=@{Action=$extension;Status='DryRun'};continue}
                    & $definition.Cli --install-extension $extension 2>&1|Out-Host
                    $results+=@{Action=$extension;Status=$(if($LASTEXITCODE -eq 0){'Completed'}else{'Failed'})}
                }
            }
        }
    }
    return ,$results
}

function Save-WinriftSetup {
    $selected=@(Show-MultiSelect -Title 'Save Setup — Sections' -Items @('W › Supported Windows Settings','A › App List','T › Terminal & PowerShell','E › Editor Settings & Extensions','G › GlazeWM Configuration'))
    if(-not $selected.Count){return}
    $setup=New-WinriftSetup
    if('W' -in $selected){
        $targets=Get-WinriftSupportedRegistryTargets
        foreach($target in $targets){
            $split=$target.LastIndexOf('|');$path=$target.Substring(0,$split);$name=$target.Substring($split+1)
            try{$snapshot=Get-WinriftRegistrySnapshot $path $name;if($snapshot.Exists){$setup.sections.Windows+=@{Path=$path;Name=$name;Type=$snapshot.Type;Value=$snapshot.Value}}}catch{Write-Log "Cannot export supported value $name" -Level WARNING}
        }
    }
    if('W' -in $selected){
        foreach($id in Get-WinriftSetupSystemIds){
            try{
                $value=Get-WinriftSystemValue $id
                if($id.StartsWith('Accessibility.')){$value=[bool]([int]$value -band 4)}
                $setup.sections.Windows+=@{Kind='System';Id=$id;Value=$value}
            }catch{Write-Log "Native setting unavailable; not exported: $id" -Level WARNING}
        }
    }
    if('A' -in $selected){
        $temp=Join-Path ([IO.Path]::GetTempPath()) ('winrift-apps-'+[guid]::NewGuid().ToString('N')+'.json')
        try{
            & winget export --output $temp --accept-source-agreements --disable-interactivity 2>&1|Out-Host
            if($LASTEXITCODE -ne 0){throw 'winget export failed.'}
            $export=Get-Content -LiteralPath $temp -Raw|ConvertFrom-Json
            $apps=@();foreach($source in $export.Sources){foreach($package in $source.Packages){$apps+=@{Id=$package.PackageIdentifier;Name=$package.PackageIdentifier;ManagerName='Winget';Source=$source.SourceDetails.Name}}}
            $items=@();for($i=0;$i -lt $apps.Count;$i++){$items+="$i › $($apps[$i].Id) [$($apps[$i].Source)]"}
            if($items.Count){$picks=@(Show-MultiSelect -Title 'Review App List Before Export' -Items $items -Defaults @($items|ForEach-Object{$true}));$setup.sections.Apps=@($picks|ForEach-Object{$apps[[int]$_]})}
        }finally{if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp}}
    }
    $definitions=Get-WinriftSetupConfigDefinitions
    foreach($key in $definitions.Keys){
        $definition=$definitions[$key]
        if(($definition.Group -eq 'Terminal' -and 'T' -notin $selected) -or ($definition.Group -eq 'Editors' -and 'E' -notin $selected) -or ($definition.Group -eq 'GlazeWM' -and 'G' -notin $selected)){continue}
        $configuration=@{Id=$key;Files=@();Extensions=@()}
        $names=if($definition.TargetNames){@($definition.TargetNames)}else{@($definition.Files)}
        foreach($name in $names){
            $path=Join-Path $definition.Target $name
            if(-not(Test-Path -LiteralPath $path -PathType Leaf)){continue}
            $file=Get-Item -LiteralPath $path
            if($file.Length -gt 5MB){Write-Log "Configuration too large; skipped: $path" -Level WARNING;continue}
            $bytes=[IO.File]::ReadAllBytes($path);$text=[Text.Encoding]::UTF8.GetString($bytes)
            if($text -match '(?im)(password|passwd|secret|api[_-]?key|access[_-]?token|refresh[_-]?token|license[_-]?key|product[_-]?key)\s*["'']?\s*[:=]\s*["'']?[^\s"'',}]+'){
                Write-Log "Possible credential assignment; not exported: $path" -Level WARNING;continue
            }
            $configuration.Files+=@{Name=$name;Content=[Convert]::ToBase64String($bytes);Hash=(Get-FileHash -LiteralPath $path).Hash}
        }
        if($definition.Cli -and (Get-Command $definition.Cli -ErrorAction SilentlyContinue)){
            $extensions=& $definition.Cli --list-extensions 2>$null
            if($LASTEXITCODE -eq 0){$configuration.Extensions=@($extensions|Where-Object{$_ -match '^[A-Za-z0-9-]+\.[A-Za-z0-9._-]+$'})}
        }
        if($configuration.Files.Count -or $configuration.Extensions.Count){$setup.sections.Configurations+=$configuration}
    }
    $choice=Show-InteractiveMenu -Title 'Review Saved Setup' -Items (@(Get-WinriftSetupPreview $setup @('Windows','Apps','Configurations'))+@('---','Y › Save Setup','N › Back'))
    if($choice -ne 'Y'){return}
    $path=Read-Host 'New setup JSON file (full path)'
    if(-not $path){return}
    if(Test-Path -LiteralPath $path){Write-Log 'Choose a new file. Existing setup is preserved.' -Level WARNING;Wait-ForUser;return}
    Write-WinriftAtomicJson -Path ([IO.Path]::GetFullPath($path)) -Value $setup
    Write-Log "Setup saved: $path" -Level SUCCESS;Wait-ForUser
}

function Restore-WinriftSetup {
    $path=Read-Host 'Setup JSON or legacy folder (full path)'
    if(-not $path){return}
    try{
        $setup=Read-WinriftSetup $path
        $selected=@(Show-MultiSelect -Title 'Restore Setup — Sections' -Items @('Windows › Supported Windows Settings','Apps › App List','Configurations › App Configurations & Extensions'))
        if(-not $selected.Count){return}
        $choice=Show-InteractiveMenu -Title 'Restore Setup — Review Changes' -Items (@(Get-WinriftSetupPreview $setup $selected)+@('---','Y › Back Up and Apply','N › Back'))
        if($choice -ne 'Y'){return}
        $results=Invoke-WinriftSetupApply -Setup $setup -Sections $selected
        Show-InfoBox 'Restore Results' @($results|ForEach-Object{"$($_.Action): $($_.Status)"})
    }catch{Write-Log "Setup restore failed: $($_.Exception.Message)" -Level ERROR}
    Wait-ForUser
}
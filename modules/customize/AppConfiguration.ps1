function Get-WinriftEditors {
    $definitions=@(
        @{Name='Visual Studio Code';Id='Microsoft.VisualStudioCode';Cli='code';Config='Code';Exe='Microsoft VS Code\Code.exe'},
        @{Name='Cursor';Id='Anysphere.Cursor';Cli='cursor';Config='Cursor';Exe='cursor\Cursor.exe'},
        @{Name='Windsurf';Id='Codeium.Windsurf';Cli='windsurf';Config='Windsurf';Exe='Windsurf\Windsurf.exe'},
        @{Name='VSCodium';Id='VSCodium.VSCodium';Cli='codium';Config='VSCodium';Exe='VSCodium\VSCodium.exe'},
        @{Name='Trae';Id='ByteDance.Trae';Cli='trae';Config='Trae';Exe='Trae\Trae.exe'}
    )
    foreach($definition in $definitions){
        $definition.Target=Join-Path $env:APPDATA ($definition.Config+'\User')
        $definition.ResolvedCli=Resolve-WinriftEditorCli $definition.Cli
        $definition.Installed=[bool]$definition.ResolvedCli
        foreach($root in @((Join-Path $env:LOCALAPPDATA 'Programs'),$env:ProgramFiles,${env:ProgramFiles(x86)})){
            if($root -and (Test-Path -LiteralPath (Join-Path $root $definition.Exe))){$definition.Installed=$true}
        }
        [pscustomobject]$definition
    }
}

function Show-VSCodeConfigMenu {
    $editors=@(Get-WinriftEditors)
    $items=@()
    foreach($installed in @($true,$false)){
        $group=@($editors|Where-Object Installed -EQ $installed)
        if(-not $group.Count){continue}
        $items+=$(if($installed){'--- Installed ---'}else{'--- Available to install ---'})
        foreach($editor in $group){$index=[array]::IndexOf($editors,$editor);$items+="$index › $($editor.Name)"}
    }
    $items+=@('---','O › Other Editor (manual path)','B › Back')
    $choice=Show-InteractiveMenu -Title 'Code Editors' -Items $items -HideKeys
    if($choice -eq 'O'){Set-OtherVSCodeConfig;return}
    $index=0
    if(-not [int]::TryParse($choice,[ref]$index) -or $index -lt 0 -or $index -ge $editors.Count){return}
    $editor=$editors[$index]
    if(-not $editor.Installed){
        $offer=Show-InteractiveMenu -Title $editor.Name -Items @('Y › Install and return to configuration','N › Back')
        if($offer -ne 'Y'){return}
        if(-not(Install-WingetPackage $editor.Id $editor.Name)){Wait-ForUser;return}
    }
    Set-VSCodeConfig -targetPath $editor.Target -EditorCli (Resolve-WinriftEditorCli $editor.Cli) -IncludeProductJson:($editor.Config -eq 'VSCodium')
}

function Show-TerminalMenu {
    Invoke-MenuLoop -Title 'Terminal & PowerShell' -Items @(
        '1 › Set Up Terminal & Shell          ›', '---',
        '2 › Windows Terminal                 ›', '3 › PowerShell Profile               ›',
        '4 › Prompt                           ›', '5 › FastFetch                        ›', '---','0 › Back'
    ) -Actions @{
        '1'={Show-WinriftShellSetup}
        '2'={Show-WinriftTerminalConfiguration}
        '3'={Set-PwshConfig}
        '4'={Show-WinriftPrompt}
        '5'={Set-FastFetchConfig}
    } -ExitKey '0' -HideKeys
}

function Show-WinriftTerminalConfiguration {
    if(-not(Get-Command wt.exe -ErrorAction SilentlyContinue)){
        $offer=Show-InteractiveMenu -Title 'Windows Terminal' -Items @('Y › Install and return to configuration','N › Back')
        if($offer -ne 'Y' -or -not(Install-WingetPackage Microsoft.WindowsTerminal 'Windows Terminal')){return}
    }
    Set-WinTermConfig
}

function Show-WinriftPrompt {
    $choice=Show-InteractiveMenu -Title 'Prompt' -Items @('O › Oh My Posh','S › Starship','---','B › Back')
    if($choice -eq 'O'){Set-OhMyPoshConfig}elseif($choice -eq 'S'){Install-Starship}
}

function Show-WinriftShellSetup {
    $selected=@(Show-MultiSelect -Title 'Set Up Terminal & Shell — Components' -Items @(
        '1 › Windows Terminal','2 › PowerShell Profile','3 › Prompt (Starship / Oh My Posh)','4 › FastFetch'
    ) -Defaults @($true,$true,$true,$true))
    if(-not $selected.Count){return}
    $labels=@{'1'='Windows Terminal';'2'='PowerShell Profile';'3'='Prompt';'4'='FastFetch'}
    $choice=Show-InteractiveMenu -Title 'Review Terminal & Shell Setup' -Items (@($selected|ForEach-Object{$labels[$_]})+@('Existing files receive versioned backups. Missing dependencies are offered individually.','---','Y › Apply Selected Components','N › Back'))
    if($choice -ne 'Y'){return}
    foreach($key in $selected){switch($key){'1'{Show-WinriftTerminalConfiguration}'2'{Set-PwshConfig}'3'{Show-WinriftPrompt}'4'{Set-FastFetchConfig}}}
}

function Show-WinriftGlazeWM {
    $target=Join-Path $env:USERPROFILE '.glzr\glazewm'
    Invoke-MenuLoop -Title 'GlazeWM' -Items @(
        '1 › Apply Configuration              ›','2 › Open Configuration File','3 › Restore Previous Configuration   ›','---','0 › Back'
    ) -Actions @{
        '1'={
            if(-not(Get-Command glazewm -ErrorAction SilentlyContinue)){
                $offer=Show-InteractiveMenu -Title GlazeWM -Items @('Y › Install and return to configuration','N › Back')
                if($offer -ne 'Y' -or -not(Install-WingetPackage glzr-io.glazewm GlazeWM)){return}
            }
            Copy-GlazeWMConfig;Wait-ForUser
        }
        '2'={ $path=Join-Path $target 'config.yaml';if(Test-Path -LiteralPath $path){Start-Process notepad.exe -ArgumentList ('"'+$path+'"')}else{Write-Log 'GlazeWM configuration not found.';Wait-ForUser} }
        '3'={Show-WinriftActionHistory -TargetPrefix $target}
    } -ExitKey '0' -HideKeys
}
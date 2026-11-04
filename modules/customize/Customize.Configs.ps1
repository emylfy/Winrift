function Copy-ConfigFiles {
    param([string]$SourceDir,[string[]]$FileNames,[string]$TargetDir,[string[]]$TargetFileNames,[string]$ConfigName,[switch]$Reviewed)
    $script:LastConfigResults=@()
    $operations=@()
    for($i=0;$i -lt $FileNames.Count;$i++){
        $name=if($TargetFileNames -and $i -lt $TargetFileNames.Count){$TargetFileNames[$i]}else{$FileNames[$i]}
        $source=[IO.Path]::GetFullPath((Join-Path $SourceDir $FileNames[$i]))
        $target=[IO.Path]::GetFullPath((Join-Path $TargetDir $name))
        $sourceRoot=[IO.Path]::GetFullPath($SourceDir).TrimEnd('\')+'\'
        $targetRoot=[IO.Path]::GetFullPath($TargetDir).TrimEnd('\')+'\'
        if(-not $source.StartsWith($sourceRoot,[StringComparison]::OrdinalIgnoreCase) -or -not $target.StartsWith($targetRoot,[StringComparison]::OrdinalIgnoreCase)){throw 'Configuration path escapes its selected directory.'}
        if(-not(Test-Path -LiteralPath $source -PathType Leaf)){throw "Missing configuration source: $source"}
        $operations+=@{Source=$source;Target=$target}
    }
    if(-not $Reviewed -and $env:WINRIFT_NO_CONFIRM -ne '1'){
        $choice=Show-InteractiveMenu -Title "Review $ConfigName Configuration" -Items (@($operations|ForEach-Object{"$($_.Source) -> $($_.Target)"})+@('Versioned backups are created before replacement.','---','Y › Apply','N › Back'))
        if($choice -ne 'Y'){return}
    }
    foreach($operation in $operations){Copy-WinriftJournaledFile -Source $operation.Source -Destination $operation.Target -Label "$ConfigName configuration";$script:LastConfigResults+=@{File=$operation.Target;Status=$script:LastFileResult.Status}}
}
function Set-VSCodeConfig {
    param (
        [string]$targetPath,
        [string]$EditorCli,
        [switch]$IncludeProductJson
    )

    $files = @("settings.json")
    if ($IncludeProductJson) {
        $files += "product.json"
    }

    Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\vscode" `
                     -FileNames $files `
                     -TargetDir $targetPath `
                     -ConfigName "VSCode"

    # Offer to install extensions
    $extFile = Join-Path $PSScriptRoot "config\vscode\extensions.txt"
    if (Test-Path $extFile) {
        # Bind extensions to the selected editor; never fall back to another CLI.
        if (-not $EditorCli) {
            $EditorCli = switch -Regex ($targetPath) {
                '\\Code\\User$' {'code';break}
                '\\Cursor\\User$' {'cursor';break}
                '\\Windsurf\\User$' {'windsurf';break}
                '\\VSCodium\\User$' {'codium';break}
                '\\Trae\\User$' {'trae';break}
            }
        }
        if ($EditorCli -and -not (Test-Path -LiteralPath $EditorCli)) { $EditorCli=Resolve-WinriftEditorCli $EditorCli }
        if ($editorCli) {
            $ans = Show-InteractiveMenu -Title "Install extensions via $editorCli?" -HideKeys -Items @(
                "Y › Yes",
                "N › No"
            )
            if ($ans -eq "Y") {
                $extensions = Get-Content $extFile | Where-Object { $_.Trim() -ne "" }
                foreach ($ext in $extensions) {
                    Write-Host -NoNewline "  $Dim$ext$Reset..."
                    if ($env:WINRIFT_DRY_RUN -eq '1') { Write-Host ' [DRY-RUN]'; continue }
                    & $editorCli --install-extension $ext --force 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) { Write-Host " $Green ok$Reset" } else { Write-Host " $Red failed ($LASTEXITCODE)$Reset" }
                }
                Write-Log -Message "Extension operations finished ($($extensions.Count) requested). Check individual results." -Level INFO
            }
        }
    }
    Wait-ForUser
}

function Set-OtherVSCodeConfig {
    Write-Host ""
    Write-Host "Please specify the path to your VSCode-based editor's user directory:"
    $editorPath = Read-Host "Enter path"
    if (-not $editorPath -or -not (Test-Path $editorPath)) {
        Write-Log -Message "Path does not exist: $editorPath" -Level ERROR
        Wait-ForUser
        return
    }
    Set-VSCodeConfig $editorPath
}

function Set-WinTermConfig {
    $choice = Show-InteractiveMenu -Title "Windows Terminal Config" -Items @(
        "1 › Install font + apply config",
        "2 › Install font only",
        "3 › Apply config only (font already installed)",
        "4 › Cancel"
    )

    $installFont = $choice -in @("1", "2")
    $applyConfig = $choice -in @("1", "3")

    if (-not $installFont -and -not $applyConfig) { return }

    $fontChoice = $null
    $fontInstalled = $false

    if ($installFont) {
        $fontChoice = Show-InteractiveMenu -Title "Font Installation" -Items @(
            "1 › FiraCode Nerd Font (download in browser)",
            "2 › Maple Mono NF (install via scoop)",
            "3 › Cancel"
        )

        switch ($fontChoice) {
            "1" {
                $downloadUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
                $sourceUrl = "https://github.com/ryanoasis/nerd-fonts"
                Write-Log -Message "Source: $sourceUrl" -Level INFO
                if($env:WINRIFT_DRY_RUN -eq '1'){Write-Log '[DRY-RUN] Hand off font download';Wait-ForUser;return}
                Start-Process $downloadUrl
                Write-Log -Message "Download started in browser." -Level INFO
                Write-Log -Message "After download: extract zip, select all .ttf files, right-click > Install." -Level INFO
                Write-Log -Message "Then restart Windows Terminal." -Level INFO
                $fontInstalled = $false
                Write-Log 'Font download handed off. Installation has not been verified; return after installing the font.'
            }
            "2" {
                if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                    Write-Log -Message "Scoop is required but not installed." -Level WARNING
                    Write-Log -Message "Install scoop first: https://scoop.sh" -Level INFO
                    Write-Log -Message "Run: irm get.scoop.sh | iex" -Level INFO
                    Wait-ForUser
                    return
                }
                Write-Log -Message "Adding nerd-fonts bucket..." -Level INFO
                if ($env:WINRIFT_DRY_RUN -eq '1') { Write-Log '[DRY-RUN] Install Maple Mono NF using scoop'; return }
                & scoop bucket add nerd-fonts 2>$null
                Write-Log -Message "Installing Maple Mono NF..." -Level INFO
                & scoop install nerd-fonts/Maple-Mono-NF
                if ($LASTEXITCODE -eq 0) {
                    Write-Log -Message "Maple Mono NF installed. Restart Windows Terminal." -Level SUCCESS
                    $fontInstalled = $true
                } else {
                    Write-Log -Message "Failed to install Maple Mono NF." -Level ERROR
                }
            }
            default {
                # User cancelled font selection — skip config if it was a combo choice
                if ($choice -eq "1") {
                    Wait-ForUser
                    return
                }
            }
        }
    }

    if ($applyConfig) {
        $configSource = "$PSScriptRoot\config\cli\terminal.json"
        $configTarget = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"

        if ($fontChoice -eq "2" -and $fontInstalled) {
            # Patch font face to Maple Mono NF before copying
            $tempConfig = Join-Path $env:TEMP "terminal_patched.json"
            (Get-Content $configSource -Raw) -replace 'FiraCode Nerd Font', 'Maple Mono NF' | Set-Content $tempConfig -Force
            Copy-ConfigFiles -SourceDir $env:TEMP `
                             -FileNames @("terminal_patched.json") `
                             -TargetDir $configTarget `
                             -TargetFileNames @("settings.json") `
                             -ConfigName "Windows Terminal"
            Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
        } else {
            if (-not $fontInstalled -and $installFont) {
                Write-Log -Message "Font installation is unverified. Configuration was not applied." -Level WARNING
                Wait-ForUser
                return
            }
            if (-not $installFont) {
                Write-Log -Message "Config uses FiraCode Nerd Font. Make sure it is installed." -Level WARNING
            }
            Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\cli" `
                             -FileNames @("terminal.json") `
                             -TargetDir $configTarget `
                             -TargetFileNames @("settings.json") `
                             -ConfigName "Windows Terminal"
        }
    }

    Wait-ForUser
}

function Set-PwshConfig {
    $review=Show-InteractiveMenu -Title 'Review PowerShell Profile' -Items @('Replace the PowerShell 7 and Windows PowerShell profiles with bundled configuration.','Versioned backups are preserved. Terminal-Icons is offered if missing.','---','Y › Apply','N › Back')
    if($review -ne 'Y'){return}
    if ($env:WINRIFT_DRY_RUN -ne '1' -and -not (Get-Module -ListAvailable -Name Terminal-Icons)) {
        try {
            Write-Log -Message "Installing Terminal-Icons module..." -Level INFO
            $offer=Show-InteractiveMenu -Title 'Terminal-Icons Dependency' -Items @('Y › Install Terminal-Icons','N › Continue without installing','B › Back')
            if($offer -eq 'B'){return}
            if($offer -eq 'Y'){Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -ErrorAction Stop}
        } catch {
            Write-Log -Message "Failed to install Terminal-Icons: $($_.Exception.Message)" -Level ERROR
        }
    } else {
        Write-Log -Message "Terminal-Icons is already installed." -Level INFO
    }

    $docsDir = [Environment]::GetFolderPath('MyDocuments')

    # PowerShell 7 profile (primary)
    Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\cli" `
                     -FileNames @("Microsoft.PowerShell_profile.ps1") `
                     -TargetDir "$docsDir\PowerShell" `
                     -ConfigName "PowerShell 7"

    # PowerShell 5.1 profile (copy for users who also use legacy shell)
    Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\cli" `
                     -FileNames @("Microsoft.PowerShell_profile.ps1") `
                     -TargetDir "$docsDir\WindowsPowerShell" `
                     -ConfigName "PowerShell 5.1"

    Wait-ForUser
}

function Set-OhMyPoshConfig {
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        $choice = Show-InteractiveMenu -Title "Oh My Posh" -Items @(
            "Oh My Posh is not installed.",
            "---",
            "1 › Install Oh My Posh (winget)",
            "2 › Skip install and apply config only",
            "3 › Cancel"
        )

        switch ($choice) {
            "1" {
                $installed = Install-WingetPackage "JanDeDobbeleer.OhMyPosh" "Oh My Posh"
                if (-not $installed) {
                    Wait-ForUser
                    return
                }
            }
            "2" {
                Write-Log -Message "Skipping Oh My Posh installation." -Level SKIP
            }
            default {
                return
            }
        }
    }

    Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\cli" `
                     -FileNames @("zen.toml") `
                     -TargetDir "$env:USERPROFILE\.config\ohmyposh" `
                     -ConfigName "Oh My Posh"
    if($script:LastConfigResults.Count -gt 0 -and -not @($script:LastConfigResults|Where-Object Status -EQ Failed).Count){Set-WinriftPromptProfile -Engine OhMyPosh}
    Wait-ForUser
}

function Install-Starship {
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Clear-Host
        Write-Log -Message "Starship is already installed." -Level INFO
    } else {
        $choice = Show-InteractiveMenu -Title "Starship Prompt" -Items @(
            "Cross-platform shell prompt (Rust-based)",
            "---",
            "1 › Install Starship (winget)",
            "2 › Cancel"
        )

        switch ($choice) {
            "1" {
                $installed = Install-WingetPackage "Starship.Starship" "Starship"
                if (-not $installed) {
                    Wait-ForUser
                    return
                }
            }
            default { return }
        }
    }

    Set-WinriftPromptProfile -Engine Starship
    Wait-ForUser
}

function Set-WinriftPromptProfile {
    param([ValidateSet('Starship','OhMyPosh')][string]$Engine,[string]$DocumentsRoot=[Environment]::GetFolderPath('MyDocuments'))
    $profiles=@((Join-Path $DocumentsRoot 'PowerShell\Microsoft.PowerShell_profile.ps1'),(Join-Path $DocumentsRoot 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'))
    $choice=Show-InteractiveMenu -Title 'Review Prompt Configuration' -Items (@("Prompt: $Engine",'Update the managed prompt block; preserve other profile content.')+$profiles+@('---','Y > Apply','N > Back'))
    if($choice -ne 'Y'){return}
    if($env:WINRIFT_DRY_RUN -eq '1'){Write-Log "[DRY-RUN] Configure $Engine in PowerShell profiles";return}
    $body=if($Engine -eq 'Starship'){
@'
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
'@
    }else{
@'
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$env:USERPROFILE\.config\ohmyposh\zen.toml" | Invoke-Expression
}
'@
    }
    $known=@'
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$env:USERPROFILE\.config\ohmyposh\zen.toml" | Invoke-Expression
}
'@
    $newline=[Environment]::NewLine
    foreach($profilePath in $profiles){
        $content=if(Test-Path -LiteralPath $profilePath){[IO.File]::ReadAllText($profilePath)}else{''}
        $content=$content -replace '(?ms)^# Winrift prompt begin\r?\n.*?^# Winrift prompt end\r?\n?',''
        $content=$content.Replace(($known -replace '\r?\n',$newline),'').Replace(($known -replace '\r?\n',[string][char]10),'')
        $new=$content.TrimEnd()+$newline+$newline+'# Winrift prompt begin'+$newline+($body -replace '\r?\n',$newline)+$newline+'# Winrift prompt end'+$newline
        $stage=Join-Path (Get-WinriftStateRoot) ('staging\prompt-'+[guid]::NewGuid().ToString('N')+'.ps1')
        [IO.Directory]::CreateDirectory((Split-Path $stage -Parent))|Out-Null
        try{[IO.File]::WriteAllText($stage,$new,[Text.UTF8Encoding]::new($false));Copy-WinriftJournaledFile $stage $profilePath "$Engine prompt"}
        finally{if(Test-Path -LiteralPath $stage){Remove-Item -LiteralPath $stage}}
    }
}

function Set-FastFetchConfig {
    if (-not (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
        $choice = Show-InteractiveMenu -Title "FastFetch" -Items @(
            "FastFetch is not installed.",
            "---",
            "1 › Install FastFetch (winget)",
            "2 › Skip install and apply config only",
            "3 › Cancel"
        )

        switch ($choice) {
            "1" {
                $installed = Install-WingetPackage "Fastfetch-cli.Fastfetch" "FastFetch"
                if (-not $installed) {
                    Wait-ForUser
                    return
                }
            }
            "2" {
                Write-Log -Message "Skipping FastFetch installation." -Level SKIP
            }
            default {
                return
            }
        }
    }

    Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\cli" `
                     -FileNames @("fastfetch.txt", "fastfetch.jsonc") `
                     -TargetDir "$env:USERPROFILE\.config\fastfetch" `
                     -TargetFileNames @("fastfetch.txt", "config.jsonc") `
                     -ConfigName "FastFetch"
    Wait-ForUser
}

function Invoke-ShellSetup {
    . "$PSScriptRoot\AppConfiguration.ps1"
    Show-WinriftShellSetup
}
function Restore-ConfigBackup {
    . "$PSScriptRoot\..\profile\Profile.ps1"
    $map=Get-WinriftConfigMap
    $items=@();$candidates=@()
    foreach($key in $map.Keys){
        $definition=$map[$key]
        for($i=0;$i -lt $definition.Files.Count;$i++){
            $name=if($definition.TargetNames){$definition.TargetNames[$i]}else{$definition.Files[$i]}
            $target=Join-Path $definition.Target $name;$backup="$target.bak";$source=Join-Path $definition.SourceDir $definition.Files[$i]
            if(Test-Path -LiteralPath $backup){$candidates+=@{Target=$target;Backup=$backup;Expected=$source;Name=$definition.Name}}
        }
    }
    if(-not $candidates.Count){Write-Log 'No legacy configuration backups found. New backups are in Action History.';Wait-ForUser;return}
    for($i=0;$i -lt $candidates.Count;$i++){$items+="$i › $($candidates[$i].Name) — legacy .bak"}
    $choice=Show-InteractiveMenu -Title 'Legacy Configuration Backups' -Items ($items+@('---','B › Back'))
    $index=0;if(-not[int]::TryParse($choice,[ref]$index) -or $index -lt 0 -or $index -ge $candidates.Count){return}
    $candidate=$candidates[$index]
    $current=Get-WinriftFileSnapshot $candidate.Target;$expected=Get-WinriftFileSnapshot $candidate.Expected;$previous=Get-WinriftFileSnapshot $candidate.Backup
    if(-not $current.Exists -or $current.Hash -ne $expected.Hash){Show-InfoBox 'Legacy Backup Conflict' @($candidate.Target,'Current file differs from the known bundled configuration. Its expected post-Winrift state cannot be verified.','The current file and legacy backup are preserved.');Wait-ForUser;return}
    $confirm=Show-InteractiveMenu -Title 'Review Legacy Configuration Restore' -Items @($candidate.Target,"Current hash: $($current.Hash)","Backup hash: $($previous.Hash)",'---','Y › Restore Previous State','N › Back')
    if($confirm -ne 'Y'){return}
    $record=New-WinriftActionRecord -Kind File -Label ('Legacy '+$candidate.Name) -Target @{Path=$candidate.Target} -Before @{Exists=$true;Hash=$previous.Hash;BackupPath=$candidate.Backup} -Proposed $current
    if($env:WINRIFT_DRY_RUN -eq '1'){Write-Log '[DRY-RUN] Restore legacy configuration';Wait-ForUser;return}
    Save-WinriftActionRecord $record
    try{$result=Restore-WinriftFileAction $record;Write-Log "Legacy configuration restore: $result"}catch{Write-Log $_.Exception.Message -Level ERROR}
    Wait-ForUser
}
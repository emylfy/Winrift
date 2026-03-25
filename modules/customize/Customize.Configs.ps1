function Copy-ConfigFiles {
    param (
        [string]$SourceDir,
        [string[]]$FileNames,
        [string]$TargetDir,
        [string[]]$TargetFileNames,
        [string]$ConfigName
    )

    try {
        if (-not (Test-Path $TargetDir)) {
            New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
        }
        $backedUp = $false
        for ($i = 0; $i -lt $FileNames.Count; $i++) {
            $src = Join-Path $SourceDir $FileNames[$i]
            if ($TargetFileNames -and $i -lt $TargetFileNames.Count) {
                $dst = Join-Path $TargetDir $TargetFileNames[$i]
            } else {
                $dst = Join-Path $TargetDir $FileNames[$i]
            }
            if (Test-Path $dst) {
                # Preserve the original backup — only create .bak if one doesn't already exist
                if (-not (Test-Path "$dst.bak")) {
                    Copy-Item -Path $dst -Destination "$dst.bak" -Force
                }
                $backedUp = $true
            }
            Copy-Item -Path $src -Destination $dst -Force
        }
        $backupNote = if ($backedUp) { " Previous config backed up as .bak." } else { "" }
        Write-Log -Message "$ConfigName configuration applied.$backupNote" -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to copy $ConfigName configuration: $($_.Exception.Message)" -Level ERROR
    }
}

function Set-VSCodeConfig {
    param (
        [string]$targetPath,
        [switch]$IncludeProductJson
    )

    if (-not (Test-Path $targetPath)) {
        Write-Log -Message "Target directory not found: $targetPath" -Level ERROR
        Write-Log -Message "Make sure the editor is installed before applying configs." -Level WARNING
        Wait-ForUser
        return
    }

    $files = @("settings.json")
    if ($IncludeProductJson) {
        $files += "product.json"
    }

    Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\vscode" `
                     -FileNames $files `
                     -TargetDir $targetPath `
                     -ConfigName "VSCode"
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
    Clear-Host
    Show-MenuBox -Title "Windows Terminal Config" -Items @(
        "1 › Install font + apply config",
        "2 › Install font only",
        "3 › Apply config only (font already installed)",
        "4 › Cancel"
    )

    $choice = Read-Host ">"

    $installFont = $choice -in @("1", "2")
    $applyConfig = $choice -in @("1", "3")

    if (-not $installFont -and -not $applyConfig) { return }

    $fontChoice = $null
    $fontInstalled = $false

    if ($installFont) {
        Clear-Host
        Show-MenuBox -Title "Font Installation" -Items @(
            "1 › FiraCode Nerd Font (download in browser)",
            "2 › Maple Mono NF (install via scoop)",
            "3 › Cancel"
        )

        $fontChoice = Read-Host ">"

        switch ($fontChoice) {
            "1" {
                $downloadUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
                $sourceUrl = "https://github.com/ryanoasis/nerd-fonts"
                Write-Log -Message "Source: $sourceUrl" -Level INFO
                Start-Process $downloadUrl
                Write-Log -Message "Download started in browser." -Level INFO
                Write-Log -Message "After download: extract zip, select all .ttf files, right-click > Install." -Level INFO
                Write-Log -Message "Then restart Windows Terminal." -Level INFO
                $fontInstalled = $true
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
                Write-Log -Message "Font installation was cancelled. Skipping config." -Level WARNING
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
    if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
        try {
            Write-Log -Message "Installing Terminal-Icons module..." -Level INFO
            Install-Module -Name Terminal-Icons -Scope CurrentUser -Force
        } catch {
            Write-Log -Message "Failed to install Terminal-Icons: $($_.Exception.Message)" -Level ERROR
        }
    } else {
        Write-Log -Message "Terminal-Icons is already installed." -Level INFO
    }

    $docsDir = [Environment]::GetFolderPath('MyDocuments')

    # PowerShell 5.1 profile
    Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\cli" `
                     -FileNames @("Microsoft.PowerShell_profile.ps1") `
                     -TargetDir "$docsDir\WindowsPowerShell" `
                     -ConfigName "PowerShell 5.1"

    # PowerShell 7+ profile
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\cli" `
                         -FileNames @("Microsoft.PowerShell_profile.ps1") `
                         -TargetDir "$docsDir\PowerShell" `
                         -ConfigName "PowerShell 7"
    }

    Wait-ForUser
}

function Set-OhMyPoshConfig {
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        Clear-Host
        Show-MenuBox -Title "Oh My Posh" -Items @(
            "Oh My Posh is not installed.",
            "---",
            "1 › Install Oh My Posh (winget)",
            "2 › Skip install and apply config only",
            "3 › Cancel"
        )

        $choice = Read-Host ">"

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
    Wait-ForUser
}

function Install-Starship {
    Clear-Host
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Write-Log -Message "Starship is already installed." -Level INFO
    } else {
        Show-MenuBox -Title "Starship Prompt" -Items @(
            "Cross-platform shell prompt (Rust-based)",
            "---",
            "1 › Install Starship (winget)",
            "2 › Cancel"
        )

        $choice = Read-Host ">"

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

    $docsDir = [Environment]::GetFolderPath('MyDocuments')
    Write-Host ""
    Write-Log -Message "To activate Starship, add this to your PowerShell profile:" -Level INFO
    Write-Host "  Invoke-Expression (&starship init powershell)"
    Write-Host ""
    Write-Log -Message "PS 5.1 profile: $docsDir\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Level INFO
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        Write-Log -Message "PS 7+  profile: $docsDir\PowerShell\Microsoft.PowerShell_profile.ps1" -Level INFO
    }
    Wait-ForUser
}

function Set-FastFetchConfig {
    if (-not (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
        Clear-Host
        Show-MenuBox -Title "FastFetch" -Items @(
            "FastFetch is not installed.",
            "---",
            "1 › Install FastFetch (winget)",
            "2 › Skip install and apply config only",
            "3 › Cancel"
        )

        $choice = Read-Host ">"

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
                     -FileNames @("cat.txt", "fastfetch.jsonc") `
                     -TargetDir "$env:USERPROFILE\.config\fastfetch" `
                     -TargetFileNames @("cat.txt", "config.jsonc") `
                     -ConfigName "FastFetch"
    Wait-ForUser
}

function Restore-ConfigBackup {
    Clear-Host

    $docsDir = [Environment]::GetFolderPath('MyDocuments')
    $editorNames = @("Code", "Aide", "Cursor", "Windsurf", "VSCodium", "Trae")

    $locations = @(
        @{ Name = "Windows Terminal"; Path = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json.bak" }
        @{ Name = "PowerShell 5.1 Profile"; Path = "$docsDir\WindowsPowerShell\Microsoft.PowerShell_profile.ps1.bak" }
        @{ Name = "PowerShell 7 Profile"; Path = "$docsDir\PowerShell\Microsoft.PowerShell_profile.ps1.bak" }
        @{ Name = "Oh My Posh"; Path = "$env:USERPROFILE\.config\ohmyposh\zen.toml.bak" }
        @{ Name = "FastFetch"; Path = "$env:USERPROFILE\.config\fastfetch\config.jsonc.bak" }
        @{ Name = "GlazeWM"; Path = "$env:USERPROFILE\.glzr\glazewm\config.yaml.bak" }
    )

    foreach ($editor in $editorNames) {
        $bakPath = "$env:USERPROFILE\AppData\Roaming\$editor\User\settings.json.bak"
        $locations += @{ Name = "$editor (settings.json)"; Path = $bakPath }
    }

    $found = @()
    foreach ($loc in $locations) {
        if (Test-Path $loc.Path) {
            $found += $loc
        }
    }

    if ($found.Count -eq 0) {
        Write-Log -Message "No config backups found." -Level INFO
        Wait-ForUser
        return
    }

    $menuItems = @()
    for ($i = 0; $i -lt $found.Count; $i++) {
        $bakInfo = Get-Item $found[$i].Path
        $size = '{0:N1} KB' -f ($bakInfo.Length / 1KB)
        $date = $bakInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
        $menuItems += "$($i + 1) › $($found[$i].Name)  ($date, $size)"
    }
    $allIdx = $found.Count + 1
    $cancelIdx = $found.Count + 2
    $menuItems += "---"
    $menuItems += "$allIdx › Restore all"
    $menuItems += "$cancelIdx › Cancel"

    Show-MenuBox -Title "Restore Config Backups" -Items $menuItems
    $choice = Read-Host ">"

    if ($choice -eq "$cancelIdx" -or $choice -eq "") { return }

    $toRestore = @()
    if ($choice -eq "$allIdx") {
        $toRestore = $found
    } else {
        $idx = 0
        if ([int]::TryParse($choice, [ref]$idx) -and $idx -ge 1 -and $idx -le $found.Count) {
            $toRestore = @($found[$idx - 1])
        } else {
            return
        }
    }

    foreach ($item in $toRestore) {
        $original = $item.Path -replace '\.bak$', ''
        try {
            Copy-Item -Path $item.Path -Destination $original -Force
            Write-Log -Message "Restored: $($item.Name)" -Level SUCCESS
        } catch {
            Write-Log -Message "Failed to restore $($item.Name): $($_.Exception.Message)" -Level ERROR
        }
    }
    Wait-ForUser
}

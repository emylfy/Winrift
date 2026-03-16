function Copy-ConfigFiles {
    param (
        [string]$SourceDir,
        [string[]]$FileNames,
        [string]$TargetDir,
        [string]$ConfigName
    )

    try {
        if (-not (Test-Path $TargetDir)) {
            New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
        }
        foreach ($file in $FileNames) {
            Copy-Item -Path (Join-Path $SourceDir $file) -Destination $TargetDir -Force
        }
        Write-Log -Message "$ConfigName configuration copied successfully." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to copy $ConfigName configuration: $($_.Exception.Message)" -Level ERROR
    }
    Read-Host "Press Enter to continue"
}

function Set-VSCodeConfig {
    param (
        [string]$targetPath
    )

    if (-not (Test-Path $targetPath)) {
        Write-Log -Message "Target directory not found: $targetPath" -Level ERROR
        Write-Log -Message "Make sure the editor is installed before applying configs." -Level WARNING
        Read-Host "Press Enter to continue"
        return
    }

    Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\vscode" `
                     -FileNames @("settings.json", "product.json") `
                     -TargetDir $targetPath `
                     -ConfigName "VSCode"
}

function Set-OtherVSCConfig {
    Write-Host ""
    Write-Host "Please specify the path to your VSCode-based editor's user directory:"
    $editorPath = Read-Host "Enter path"
    Set-VSCodeConfig $editorPath
}

function Set-WinTermConfig {
    Clear-Host
    Show-MenuBox -Title "Fira Code Font Installation" -Items @(
        "[1] Install Fira Code via Chocolatey",
        "[2] Manual installation (open website)",
        "[3] Skip (I already have Fira Code)"
    )

    $choice = Read-Host ">"

    switch ($choice) {
        "1" {
            if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
                Write-Log -Message "Chocolatey not found. Installing Chocolatey..." -Level INFO
                try {
                    Set-ExecutionPolicy Bypass -Scope Process -Force
                    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                    Write-Log -Message "Chocolatey installed successfully." -Level SUCCESS
                } catch {
                    Write-Log -Message "Failed to install Chocolatey: $($_.Exception.Message)" -Level ERROR
                    Write-Log -Message "Opening Nerd Fonts releases page for manual installation..." -Level INFO
                    Start-Process "https://github.com/ryanoasis/nerd-fonts/releases/"
                }
            }

            try {
                Write-Log -Message "Installing Fira Code font..." -Level INFO
                Start-Process -FilePath "choco.exe" -ArgumentList "install FiraCode -y --no-progress" -Wait -NoNewWindow
                Write-Log -Message "Fira Code font installed successfully." -Level SUCCESS
            } catch {
                Write-Log -Message "Failed to install Fira Code font." -Level ERROR
                Write-Log -Message "Opening Nerd Fonts releases page for manual installation..." -Level INFO
                Start-Process "https://github.com/ryanoasis/nerd-fonts/releases/"
            }
        }
        "2" {
            Write-Log -Message "Opening Nerd Fonts releases page for manual Fira Code installation..." -Level INFO
            Start-Process "https://github.com/ryanoasis/nerd-fonts/releases/"
        }
        "3" {
            Write-Log -Message "Skipping Fira Code installation." -Level SKIP
        }
    }

    Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\cli\terminal" `
                     -FileNames @("settings.json") `
                     -TargetDir "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState" `
                     -ConfigName "Windows Terminal"
}

function Set-PwshConfig {
    try {
        Write-Log -Message "Installing Terminal-Icons module..." -Level INFO
        Install-Module -Name Terminal-Icons -Scope CurrentUser -Force
    } catch {
        Write-Log -Message "Failed to install Terminal-Icons: $($_.Exception.Message)" -Level ERROR
    }

    Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\cli\WindowsPowershell" `
                     -FileNames @("Microsoft.PowerShell_profile.ps1") `
                     -TargetDir "$env:USERPROFILE\Documents\WindowsPowerShell" `
                     -ConfigName "PowerShell"
}

function Set-OhMyPoshConfig {
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        Clear-Host
        Write-Log -Message "Oh My Posh is not installed." -Level WARNING
        Show-MenuBox -Title "Oh My Posh Not Found" -Items @(
            "[1] Install Oh My Posh (winget)",
            "[2] Skip install and apply config only",
            "[3] Cancel"
        )

        $choice = Read-Host ">"

        switch ($choice) {
            "1" {
                Write-Log -Message "Installing Oh My Posh..." -Level INFO
                try {
                    Start-Process winget -ArgumentList "install JanDeDobbeleer.OhMyPosh --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
                    Write-Log -Message "Oh My Posh installed successfully." -Level SUCCESS
                } catch {
                    Write-Log -Message "Failed to install Oh My Posh: $($_.Exception.Message)" -Level ERROR
                    Read-Host "Press Enter to continue"
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

    Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\cli\ohmyposh" `
                     -FileNames @("zen.toml") `
                     -TargetDir "$env:USERPROFILE\.config\ohmyposh" `
                     -ConfigName "Oh My Posh"
}

function Set-FastFetchConfig {
    if (-not (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
        Clear-Host
        Write-Log -Message "FastFetch is not installed." -Level WARNING
        Show-MenuBox -Title "FastFetch Not Found" -Items @(
            "[1] Install FastFetch (winget)",
            "[2] Skip install and apply config only",
            "[3] Cancel"
        )

        $choice = Read-Host ">"

        switch ($choice) {
            "1" {
                Write-Log -Message "Installing FastFetch..." -Level INFO
                try {
                    Start-Process winget -ArgumentList "install Fastfetch-cli.Fastfetch --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
                    Write-Log -Message "FastFetch installed successfully." -Level SUCCESS
                } catch {
                    Write-Log -Message "Failed to install FastFetch: $($_.Exception.Message)" -Level ERROR
                    Read-Host "Press Enter to continue"
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

    Copy-ConfigFiles -SourceDir "$PSScriptRoot\config\cli\fastfetch" `
                     -FileNames @("cat.txt", "config.jsonc") `
                     -TargetDir "$env:USERPROFILE\.config\fastfetch" `
                     -ConfigName "FastFetch"
}

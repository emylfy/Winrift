function Set-VSCodeConfig {
    param (
        [string]$targetPath
    )

    try {
        Copy-Item -Path "$PSScriptRoot\config\vscode\settings.json" -Destination $targetPath -Force
        Copy-Item -Path "$PSScriptRoot\config\vscode\product.json" -Destination $targetPath -Force
        Write-Log -Message "Configuration copied successfully to $targetPath." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to copy configuration to $targetPath." -Level ERROR
    }

    Read-Host "Press Enter to continue"
}

function Set-OtherVSCConfig {
    Write-Host ""
    Write-Host "Please specify the path to your VSCode-based editor's user directory:"
    $editorPath = Read-Host "Enter path"

    try {
        Copy-Item -Path "$PSScriptRoot\config\vscode\settings.json" -Destination $editorPath -Force
        Copy-Item -Path "$PSScriptRoot\config\vscode\product.json" -Destination $editorPath -Force
        Write-Log -Message "Configuration copied successfully to $editorPath." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to copy configuration to $editorPath." -Level ERROR
    }

    Read-Host "Press Enter to continue"
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

    try {
        Copy-Item -Path "$PSScriptRoot\config\cli\terminal\settings.json" `
                  -Destination "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\" `
                  -Force
        Write-Log -Message "Windows Terminal settings copied successfully." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to copy Windows Terminal settings." -Level ERROR
    }

    Read-Host "Press Enter to continue"
}

function Set-PwshConfig {
    try {
        Write-Log -Message "Installing Terminal-Icons module..." -Level INFO
        Install-Module -Name Terminal-Icons -Scope CurrentUser -Force
        Copy-Item -Path "$PSScriptRoot\config\cli\WindowsPowershell\Microsoft.PowerShell_profile.ps1" `
                  -Destination "$env:USERPROFILE\Documents\WindowsPowerShell" `
                  -Force
        Write-Log -Message "PowerShell profile copied successfully." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to copy PowerShell profile: $($_.Exception.Message)" -Level ERROR
    }

    Read-Host "Press Enter to continue"
}

function Set-OhMyPoshConfig {
    try {
        if (-not (Test-Path "$env:USERPROFILE\.config\ohmyposh")) {
            New-Item -Path "$env:USERPROFILE\.config\ohmyposh" -ItemType Directory -Force | Out-Null
        }
        Copy-Item -Path "$PSScriptRoot\config\cli\ohmyposh\zen.toml" `
                  -Destination "$env:USERPROFILE\.config\ohmyposh" `
                  -Force
        Write-Log -Message "Oh My Posh configuration copied successfully." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to copy Oh My Posh configuration: $($_.Exception.Message)" -Level ERROR
    }

    Read-Host "Press Enter to continue"
}

function Set-FastFetchConfig {
    try {
        if (-not (Test-Path "$env:USERPROFILE\.config\fastfetch")) {
            New-Item -Path "$env:USERPROFILE\.config\fastfetch" -ItemType Directory -Force | Out-Null
        }
        Copy-Item -Path "$PSScriptRoot\config\cli\fastfetch\cat.txt" `
                  -Destination "$env:USERPROFILE\.config\fastfetch" `
                  -Force
        Copy-Item -Path "$PSScriptRoot\config\cli\fastfetch\config.jsonc" `
                  -Destination "$env:USERPROFILE\.config\fastfetch" `
                  -Force
        Write-Log -Message "FastFetch configuration copied successfully." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to copy FastFetch configuration: $($_.Exception.Message)" -Level ERROR
    }

    Read-Host "Press Enter to continue"
}

Export-ModuleMember -Function `
    Set-VSCodeConfig, `
    Set-OtherVSCConfig, `
    Set-WinTermConfig, `
    Set-PwshConfig, `
    Set-OhMyPoshConfig, `
    Set-FastFetchConfig

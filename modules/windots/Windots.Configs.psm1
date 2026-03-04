function Configure-VSCode {
    param (
        [string]$targetPath
    )
    
    try {
        Copy-Item -Path "$PSScriptRoot\config\vscode\settings.json" -Destination $targetPath -Force
        Copy-Item -Path "$PSScriptRoot\config\vscode\product.json" -Destination $targetPath -Force
        Write-Host "$Green Configuration copied successfully to $targetPath.$Reset"
    } catch {
        Write-Host "$Red Failed to copy configuration to $targetPath.$Reset"
    }

    Read-Host "Press Enter to continue"
    Show-VSCodeMenu
}

function Configure-OtherVSC {
    Write-Host ""
    Write-Host "Please specify the path to your VSCode-based editor's user directory:"
    $editorPath = Read-Host "Enter path"
    
    try {
        Copy-Item -Path "$PSScriptRoot\config\vscode\settings.json" -Destination $editorPath -Force
        Copy-Item -Path "$PSScriptRoot\config\vscode\product.json" -Destination $editorPath -Force
        Write-Host "$Green Configuration copied successfully to $editorPath.$Reset"
    } catch {
        Write-Host "$Red Failed to copy configuration to $editorPath.$Reset"
    }
    
    Read-Host "Press Enter to continue"
    Show-VSCodeMenu
}

function Configure-WinTerm {
    Clear-Host
    Write-Host "$Purple +-----------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Install Fira Code via Chocolatey    $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] Manual installation (open website)  $Purple'$Reset"
    Write-Host "$Purple '$Reset [3] Skip (I already have Fira Code)     $Purple'$Reset"
    Write-Host "$Purple +-----------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" {
            if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
                Write-Host "Chocolatey not found. Installing Chocolatey..."
                try {
                    Set-ExecutionPolicy Bypass -Scope Process -Force
                    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                    Write-Host "$Green Chocolatey installed successfully.$Reset"
                } catch {
                    Write-Host "$Red Failed to install Chocolatey: $($_.Exception.Message)$Reset"
                    Write-Host "Opening Nerd Fonts releases page for manual installation..."
                    Start-Process "https://github.com/ryanoasis/nerd-fonts/releases/"
                }
            }
            
            try {
                Write-Host "Installing Fira Code font..."
                Start-Process -FilePath "choco.exe" -ArgumentList "install FiraCode -y --no-progress" -Wait -NoNewWindow
                Write-Host "$Green Fira Code font installed successfully.$Reset"
            } catch {
                Write-Host "$Red Failed to install Fira Code font.$Reset"
                Write-Host "Opening Nerd Fonts releases page for manual installation..."
                Start-Process "https://github.com/ryanoasis/nerd-fonts/releases/"
            }
        }
        "2" {
            Write-Host "Opening Nerd Fonts releases page for manual Fira Code installation..."
            Start-Process "https://github.com/ryanoasis/nerd-fonts/releases/"
        }
        "3" {
            Write-Host "Skipping Fira Code installation..."
        }
    }
    
    try {
        Copy-Item -Path "$PSScriptRoot\config\cli\terminal\settings.json" -Destination "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\" -Force
        Write-Host "$Green Windows Terminal settings copied successfully.$Reset"
    } catch {
        Write-Host "$Red Failed to copy Windows Terminal settings.$Reset"
    }
    
    Read-Host "Press Enter to continue"
    Show-ConfigsMenu
}

function Configure-Pwsh {
    try {
        Write-Host "Installing Terminal-Icons module..."
        Install-Module -Name Terminal-Icons -Scope CurrentUser -Force
        Copy-Item -Path "$PSScriptRoot\config\cli\WindowsPowershell\Microsoft.PowerShell_profile.ps1" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell" -Force
        Write-Host "$Green PowerShell profile copied successfully.$Reset"
    } catch {
        Write-Host "$Red Failed to copy PowerShell profile.$Reset"
    }
    
    Read-Host "Press Enter to continue"
    Show-ConfigsMenu
}

function Configure-OhMyPosh {
    try {
        if (-not (Test-Path "$env:USERPROFILE\.config\ohmyposh")) {
            New-Item -Path "$env:USERPROFILE\.config\ohmyposh" -ItemType Directory -Force | Out-Null
        }
        Copy-Item -Path "$PSScriptRoot\config\cli\ohmyposh\zen.toml" -Destination "$env:USERPROFILE\.config\ohmyposh" -Force
        Write-Host "$Green Oh My Posh configuration copied successfully.$Reset"
    } catch {
        Write-Host "$Red Failed to copy Oh My Posh configuration.$Reset"
    }
    
    Read-Host "Press Enter to continue"
    Show-ConfigsMenu
}

function Configure-FastFetch {
    try {
        if (-not (Test-Path "$env:USERPROFILE\.config\fastfetch")) {
            New-Item -Path "$env:USERPROFILE\.config\fastfetch" -ItemType Directory -Force | Out-Null
        }
        Copy-Item -Path "$PSScriptRoot\config\cli\fastfetch\cat.txt" -Destination "$env:USERPROFILE\.config\fastfetch" -Force
        Copy-Item -Path "$PSScriptRoot\config\cli\fastfetch\config.jsonc" -Destination "$env:USERPROFILE\.config\fastfetch" -Force
        Write-Host "$Green FastFetch configuration copied successfully.$Reset"
    } catch {
        Write-Host "$Red Failed to copy FastFetch configuration.$Reset"
    }
    
    Read-Host "Press Enter to continue"
    Show-ConfigsMenu
}

Export-ModuleMember -Function `
    Configure-VSCode, `
    Configure-OtherVSC, `
    Configure-WinTerm, `
    Configure-Pwsh, `
    Configure-OhMyPosh, `
    Configure-FastFetch


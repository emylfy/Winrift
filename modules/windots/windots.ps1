. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-MainMenu {
    cls
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [1] Configs Installer               $Purple'$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [2] Download Rectify11              $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] Install Spotify Tools           $Purple'$Reset"
    Write-Host "$Purple '$Grey [4] Install Steam Millenium + Theme $Purple'$Reset"
    Write-Host "$Purple '$Grey [5] Apply macOS Cursor              $Purple'$Reset"
    Write-Host "$Purple '$Grey [6] Customization tweaks            $Purple'$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [7] Back to Simplify11              $Purple'$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" { Show-ConfigsMenu }
        "2" { Invoke-Rectify11 }
        "3" { Show-SpotifyToolsMenu }
        "4" { Install-Steam }
        "5" { Apply-Cursor }
        "6" { Show-WindowsCustomizationMenu }
        "7" { Simplify11 }
        default { Show-MainMenu }
    }
}

function Invoke-Rectify11 {
    Start-Process "https://rectify11.net/home"
    Show-MainMenu
}

function Show-SpotifyToolsMenu {
    cls
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [1] Install SpotX                   $Purple'$Reset"
    Write-Host "$Purple '$Grey [2] Install Spicetify               $Purple'$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [3] Return to Main Menu             $Purple'$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" { Install-SpotX }
        "2" { Install-Spicetify }
        "3" { Show-MainMenu }
        default { Show-SpotifyToolsMenu }
    }
}

function Install-SpotX {
    cls
    Write-Host ""
    Write-Host "Installing SpotX..."
    Invoke-Expression (Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/SpotX-Official/spotx-official.github.io/main/run.ps1)
    Read-Host "Press Enter to continue"
    Show-SpotifyToolsMenu
}

function Install-Spicetify {
    Clear-Host
    Write-Host ""
    Write-Host "Installing Spicetify..."
    try {
        Invoke-Expression (Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/spicetify/cli/main/install.ps1)
        Write-Host "$Green Spicetify installed successfully.$Reset"
    } catch {
        Write-Host "$Red Failed to install Spicetify.$Reset"
    }
    Read-Host "Press Enter to continue"
    Show-SpotifyToolsMenu
}

function Install-Steam {
    Clear-Host
    Write-Host ""
    Write-Host "Installing Steam Millenium..."
    try {
        Invoke-Expression (Invoke-WebRequest -UseBasicParsing 'https://steambrew.app/install.ps1')
        Write-Host "$Green Steam Millenium installed successfully.$Reset"
    } catch {
        Write-Host "$Red Failed to install Steam Millenium. Make sure steam installed$Reset"
    }
    Read-Host "Press Enter to continue"

    Clear-Host
    Write-Host ""
    Write-Host "$Purple +-------------------------+$Reset"
    Write-Host "$Purple '$Grey Space Theme Installation $Purple'$Reset"
    Write-Host "$Purple +-------------------------+$Reset"
    Write-Host "Would you like to install Space Theme for Steam?"
    $installChoice = Read-Host "Install Space Theme? (y/n)"
    
    if ($installChoice -eq 'y') {
        Write-Host "Installing Space Theme..."
        try {
            Invoke-Expression (Invoke-WebRequest -UseBasicParsing 'https://spacetheme.de/steam.ps1')
            Write-Host "$Green Space Theme installed successfully.$Reset"
        } catch {
            Write-Host "$Red Failed to install Space Theme through the main method.$Reset"
                Start-Process "https://github.com/SpaceTheme/Steam/releases"
        }
    }
    Read-Host "Press Enter to continue"
    Show-MainMenu
}

function Apply-Cursor {
    Write-Host "Opening macOS cursor download link in browser..."
    Start-Process "https://github.com/ful1e5/apple_cursor/releases/download/v2.0.1/macOS-Windows.zip"
    Read-Host "Press Enter to continue"
    Show-MainMenu
}

function Simplify11 {
    & "$PSScriptRoot\..\..\simplify11.ps1"
    Show-MainMenu
}

function Show-ConfigsMenu {
    Clear-Host
    Write-Host "$Purple +-------------------------+$Reset"
    Write-Host "$Purple '$Grey [1] VSCode Based        $Purple'$Reset"
    Write-Host "$Purple +-------------------------+$Reset"
    Write-Host "$Purple '$Grey [2] Windows Terminal    $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] PowerShell          $Purple'$Reset"
    Write-Host "$Purple '$Grey [4] Oh My Posh          $Purple'$Reset"
    Write-Host "$Purple '$Grey [5] FastFetch           $Purple'$Reset"
    Write-Host "$Purple +-------------------------+$Reset"
    Write-Host "$Purple '$Grey [6] Return              $Purple'$Reset"
    Write-Host "$Purple +-------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" { Show-VSCodeMenu }
        "2" { Configure-WinTerm }
        "3" { Configure-Pwsh }
        "4" { Configure-OhMyPosh }
        "5" { Configure-FastFetch }
        "6" { Show-MainMenu }
        default { Show-ConfigsMenu }
    }
}

function Show-VSCodeMenu {
    Clear-Host
    Write-Host "$Purple +-------------------------+$Reset"
    Write-Host "$Purple '$Grey [1] Visual Studio Code  $Purple'$Reset"
    Write-Host "$Purple '$Grey [2] Aide                $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] Cursor              $Purple'$Reset"
    Write-Host "$Purple '$Grey [4] Windsurf            $Purple'$Reset"
    Write-Host "$Purple '$Grey [5] VSCodium            $Purple'$Reset"
    Write-Host "$Purple '$Grey [6] Trae                $Purple'$Reset"
    Write-Host "$Purple '$Grey [7] Other               $Purple'$Reset"
    Write-Host "$Purple +-------------------------+$Reset"
    Write-Host "$Purple '$Grey [8] Return              $Purple'$Reset"
    Write-Host "$Purple +-------------------------+$Reset"
    
    $choice = Read-Host "Select VSCode-based editor"
    
    switch ($choice) {
        "1" { Configure-VSCode "$env:USERPROFILE\AppData\Roaming\Code\User" }
        "2" { Configure-VSCode "$env:USERPROFILE\AppData\Roaming\Aide\User" }
        "3" { Configure-VSCode "$env:USERPROFILE\AppData\Roaming\Cursor\User" }
        "4" { Configure-VSCode "$env:USERPROFILE\AppData\Roaming\Windsurf\User" }
        "5" { Configure-VSCode "$env:USERPROFILE\AppData\Roaming\VSCodium\User" }
        "6" { Configure-VSCode "$env:USERPROFILE\AppData\Roaming\Trae\User" }
        "7" { Configure-OtherVSC }
        "8" { Show-ConfigsMenu }
        default { Show-VSCodeMenu }
    }
}

function Configure-VSCode {
    param (
        [string]$targetPath
    )
    
    try {
        Copy-Item -Path "$PSScriptRoot\..\..\config\vscode\settings.json" -Destination $targetPath -Force
        Copy-Item -Path "$PSScriptRoot\..\..\config\vscode\product.json" -Destination $targetPath -Force
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
        Copy-Item -Path "$PSScriptRoot\..\..\config\vscode\settings.json" -Destination $editorPath -Force
        Copy-Item -Path "$PSScriptRoot\..\..\config\vscode\product.json" -Destination $editorPath -Force
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
    Write-Host "$Purple '$Grey [1] Install Fira Code via Chocolatey    $Purple'$Reset"
    Write-Host "$Purple '$Grey [2] Manual installation (open website)  $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] Skip (I already have Fira Code)     $Purple'$Reset"
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
                    Write-Host "$Red Failed to install Chocolatey. Please try manual installation.$Reset"
                    Start-Process "https://github.com/ryanoasis/nerd-fonts/releases/"
                }
            }
            
            try {
                Write-Host "Installing Fira Code font..."
                Start-Process -FilePath "choco.exe" -ArgumentList "install FiraCode -y --no-progress" -Wait -NoNewWindow
                Write-Host "$Green Fira Code font installed successfully.$Reset"
            } catch {
                Write-Host "$Red Failed to install Fira Code font. Please try manual installation.$Reset"
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
        Copy-Item -Path "$PSScriptRoot\..\..\config\cli\terminal\settings.json" -Destination "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\" -Force
        Write-Host "$Green Windows Terminal settings copied successfully.$Reset"
    } catch {
        Write-Host "$Red Failed to copy Windows Terminal settings.$Reset"
    }
    
    Read-Host "Press Enter to continue"
    Show-ConfigsMenu
}

function Configure-Pwsh {
    try {
        Install-Module -Name Terminal-Icons -Scope CurrentUser -Force
        Copy-Item -Path "$PSScriptRoot\..\..\config\cli\WindowsPowershell\Microsoft.PowerShell_profile.ps1" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell" -Force
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
        Copy-Item -Path "$PSScriptRoot\..\..\config\cli\ohmyposh\zen.toml" -Destination "$env:USERPROFILE\.config\ohmyposh" -Force
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
        Copy-Item -Path "$PSScriptRoot\..\..\config\cli\fastfetch\cat.txt" -Destination "$env:USERPROFILE\.config\fastfetch" -Force
        Copy-Item -Path "$PSScriptRoot\..\..\config\cli\fastfetch\config.jsonc" -Destination "$env:USERPROFILE\.config\fastfetch" -Force
        Write-Host "$Green FastFetch configuration copied successfully.$Reset"
    } catch {
        Write-Host "$Red Failed to copy FastFetch configuration.$Reset"
    }
    
    Read-Host "Press Enter to continue"
    Show-ConfigsMenu
}

function Show-WindowsCustomizationMenu {
    Clear-Host
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [1] Set Short Date and Hours Format - Feb 17, 17:57    $Purple'$Reset"
    Write-Host "$Purple '$Grey [2] Disable automatic pin of folders to Quick Access   $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] Selectively pull icons from folders in start menu  $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [4] Return to Main Menu                               $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"

    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" { Set-ShortDateHours }
        "2" { Disable-QuickAccess }
        "3" { Extract-StartFolders }
        "4" { Show-MainMenu }
        default { Show-WindowsCustomizationMenu }
    }
}

function Set-ShortDateHours {
    Clear-Host
    Write-Host "${Grey}Setting short date and hours format...$Reset"
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sShortDate -Value "dd MMM yyyy"
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sShortTime -Value "HH:mm"
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sTimeFormat -Value "HH:mm:ss"
    Write-Host "${Grey}Date and time format updated successfully. Changes will take effect after restart.$Reset"
    pause
    Show-WindowsCustomizationMenu
}

function Disable-QuickAccess {
    Clear-Host
    Write-Host "${Grey}Disabling automatic addition of folders to Quick Access...$Reset"
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowFrequent' -Type DWord -Value 0
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowRecent' -Type DWord -Value 0
    $quickAccess = (New-Object -ComObject shell.application).Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}').Items()
    $quickAccess | ForEach-Object { $_.InvokeVerb('remove') }
    Stop-Process -Name explorer -Force
    Start-Process explorer
    Write-Host "${Green}Quick Access settings updated successfully. Explorer will restart to apply changes.$Reset"
    pause
    Show-WindowsCustomizationMenu
}

function Extract-StartFolders {
    Clear-Host
    $scriptDir = Split-Path -Parent $PSScriptRoot
    $organizerPath = Join-Path -Path $scriptDir -ChildPath "tweaks\Organizer.ps1"
    Start-Process powershell -ArgumentList "-NoExit -File `"$organizerPath`""
    Show-WindowsCustomizationMenu
}

Show-MainMenu
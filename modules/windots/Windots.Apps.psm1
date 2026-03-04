function Invoke-Rectify11 {
    Start-Process "https://rectify11.net/home"
    Show-MainMenu
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
        Write-Host "$Red Failed to install Steam Millenium. Make sure Steam is installed.$Reset"
    }
    
    Read-Host "Press Enter to continue"

    Clear-Host
    Write-Host ""
    Write-Host "$Purple +-------------------------+$Reset"
    Write-Host "$Purple '$Reset Space Theme Installation $Purple'$Reset"
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
            Write-Host "Opening GitHub releases page for manual download..."
            Start-Process "https://github.com/SpaceTheme/Steam/releases"
        }
    }
    Read-Host "Press Enter to continue"
    Show-MainMenu
}

function Apply-Cursor {
    Clear-Host
    Write-Host "\nOpening macOS cursor download link in browser..."
    try {
        Start-Process "https://github.com/ful1e5/apple_cursor/releases/download/v2.0.1/macOS-Windows.zip"
        Write-Host "$Green Download link opened successfully.$Reset"
        Write-Host "\n$Yellow Installation Instructions:$Reset"
        Write-Host "1. Extract the downloaded ZIP file"
        Write-Host "2. Right-click on each .inf file and select 'Install'"
        Write-Host "3. Go to Settings > Personalization > Themes > Mouse cursor"
        Write-Host "4. Select the installed macOS cursor theme"
    } catch {
        Write-Host "$Red Failed to open download link: $($_.Exception.Message)$Reset"
    }
    Read-Host "Press Enter to continue"
    Show-MainMenu
}

Export-ModuleMember -Function `
    Invoke-Rectify11, `
    Install-SpotX, `
    Install-Spicetify, `
    Install-Steam, `
    Apply-Cursor


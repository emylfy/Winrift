function Invoke-Rectify11 {
    Start-Process "https://rectify11.net/home"
}

function Install-SpotX {
    Clear-Host
    Write-Log -Message "Installing SpotX..." -Level INFO
    try {
        $scriptContent = (Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/SpotX-Official/spotx-official.github.io/main/run.ps1 -ErrorAction Stop).Content
        Invoke-Expression $scriptContent
        Write-Log -Message "SpotX installed successfully." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to install SpotX: $($_.Exception.Message)" -Level ERROR
    }
    Read-Host "Press Enter to continue"
}

function Install-Spicetify {
    Clear-Host
    Write-Log -Message "Installing Spicetify..." -Level INFO
    try {
        Invoke-Expression (Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/spicetify/cli/main/install.ps1)
        Write-Log -Message "Spicetify installed successfully." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to install Spicetify: $($_.Exception.Message)" -Level ERROR
    }
    Read-Host "Press Enter to continue"
}

function Install-Steam {
    Clear-Host
    Write-Log -Message "Installing Steam Millennium..." -Level INFO
    try {
        Invoke-Expression (Invoke-WebRequest -UseBasicParsing 'https://steambrew.app/install.ps1')
        Write-Log -Message "Steam Millennium installed successfully." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to install Steam Millennium. Make sure Steam is installed." -Level ERROR
    }

    Read-Host "Press Enter to continue"

    Clear-Host
    Show-MenuBox -Title "Space Theme Installation" -Items @(
        "Would you like to install Space Theme for Steam?",
        "[y] Yes   [n] No"
    )
    $installChoice = Read-Host "Install Space Theme? (y/n)"

    if ($installChoice -eq 'y') {
        Write-Log -Message "Installing Space Theme..." -Level INFO
        try {
            Invoke-Expression (Invoke-WebRequest -UseBasicParsing 'https://spacetheme.de/steam.ps1')
            Write-Log -Message "Space Theme installed successfully." -Level SUCCESS
        } catch {
            Write-Log -Message "Failed to install Space Theme through the main method." -Level ERROR
            Write-Log -Message "Opening GitHub releases page for manual download..." -Level INFO
            Start-Process "https://github.com/SpaceTheme/Steam/releases"
        }
    }
    Read-Host "Press Enter to continue"
}

function Set-Cursor {
    Clear-Host
    Write-Log -Message "Opening macOS cursor download link in browser..." -Level INFO
    try {
        Start-Process "https://github.com/ful1e5/apple_cursor/releases/download/v2.0.1/macOS-Windows.zip"
        Write-Log -Message "Download link opened successfully." -Level SUCCESS
        Write-Host ""
        Write-Log -Message "Installation Instructions:" -Level INFO
        Write-Host "  1. Extract the downloaded ZIP file"
        Write-Host "  2. Right-click on each .inf file and select 'Install'"
        Write-Host "  3. Go to Settings > Personalization > Themes > Mouse cursor"
        Write-Host "  4. Select the installed macOS cursor theme"
    } catch {
        Write-Log -Message "Failed to open download link: $($_.Exception.Message)" -Level ERROR
    }
    Read-Host "Press Enter to continue"
}

Export-ModuleMember -Function `
    Invoke-Rectify11, `
    Install-SpotX, `
    Install-Spicetify, `
    Install-Steam, `
    Set-Cursor

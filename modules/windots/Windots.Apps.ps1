function Invoke-Rectify11 {
    Start-Process "https://rectify11.net/home"
}

function Install-SpotX {
    Clear-Host
    Invoke-Tool "spotx"
    Read-Host "Press Enter to continue"
}

function Install-Spicetify {
    Clear-Host
    Invoke-Tool "spicetify"
    Read-Host "Press Enter to continue"
}

function Install-Steam {
    Clear-Host
    Invoke-Tool "steam-millennium" -Wait -ErrorMessage "Failed to install Steam Millennium. Make sure Steam is installed"
    Read-Host "Press Enter to continue"

    Clear-Host
    Show-MenuBox -Title "Space Theme Installation" -Items @(
        "Would you like to install Space Theme for Steam?",
        "[y] Yes   [n] No"
    )
    $installChoice = Read-Host "Install Space Theme? (y/n)"

    if ($installChoice -eq 'y') {
        Invoke-Tool "spacetheme"
    }
    Read-Host "Press Enter to continue"
}

function Set-Cursor {
    Clear-Host
    Invoke-Tool "macos-cursor" -OnSuccess {
        Write-Host ""
        Write-Log -Message "Installation Instructions:" -Level INFO
        Write-Host "  1. Extract the downloaded ZIP file"
        Write-Host "  2. Right-click on each .inf file and select 'Install'"
        Write-Host "  3. Go to Settings > Personalization > Themes > Mouse cursor"
        Write-Host "  4. Select the installed macOS cursor theme"
    }
    Read-Host "Press Enter to continue"
}

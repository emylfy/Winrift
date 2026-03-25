function Invoke-Rectify11 {
    $null = Invoke-Tool "rectify11"
}

function Install-SpotX {
    Clear-Host
    $null = Invoke-Tool "spotx"
    Wait-ForUser
}

function Install-Spicetify {
    Clear-Host
    $null = Invoke-Tool "spicetify"
    Wait-ForUser
}

function Install-SteamMillennium {
    Clear-Host
    $result = Invoke-Tool "steam-millennium" -Wait -ErrorMessage "Failed to install Steam Millennium. Make sure Steam is installed"
    if (-not $result) {
        Wait-ForUser
        return
    }

    Clear-Host
    Show-MenuBox -Title "Space Theme Installation" -Items @(
        "Would you like to install Space Theme for Steam?",
        "Y › Yes   N › No"
    )
    $installChoice = Read-Host "Install Space Theme? (Y/N)"

    if ($installChoice -eq 'y') {
        $null = Invoke-Tool "spacetheme"
    }
    Wait-ForUser
}


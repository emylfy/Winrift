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

    $installChoice = Show-InteractiveMenu -Title "Space Theme Installation" -HideKeys -Items @(
        "Install Space Theme for Steam?",
        "---",
        "Y › Yes",
        "N › No"
    )

    if ($installChoice -eq 'Y') {
        $null = Invoke-Tool "spacetheme"
    }
    Wait-ForUser
}


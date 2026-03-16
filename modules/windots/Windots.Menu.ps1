function Show-MainMenu {
    Invoke-MenuLoop -Title "Windots - Rice & Customize Windows" -Items @(
        "[1] Configs Installer",
        "---",
        "[2] Download Rectify11",
        "[3] Install Spotify Tools",
        "[4] Install Steam Millennium + Theme",
        "[5] Apply macOS Cursor",
        "[6] Customization tweaks",
        "---",
        "[7] Back to Simplify11"
    ) -Actions @{
        "1" = { Show-ConfigsMenu }
        "2" = { Invoke-Rectify11 }
        "3" = { Show-SpotifyToolsMenu }
        "4" = { Install-Steam }
        "5" = { Set-Cursor }
        "6" = { Show-WindowsCustomizationMenu }
    } -ExitKey "7" -OnExit { Invoke-ReturnToMenu }
}

function Show-SpotifyToolsMenu {
    Invoke-MenuLoop -Title "Spotify Tools" -Items @(
        "[1] Install SpotX",
        "[2] Install Spicetify",
        "---",
        "[3] Back to menu"
    ) -Actions @{
        "1" = { Install-SpotX }
        "2" = { Install-Spicetify }
    } -ExitKey "3"
}

function Show-ConfigsMenu {
    Invoke-MenuLoop -Title "Configs Installer" -Items @(
        "[1] VSCode Based",
        "---",
        "[2] Windows Terminal",
        "[3] PowerShell",
        "[4] Oh My Posh",
        "[5] FastFetch",
        "---",
        "[6] Back to menu"
    ) -Actions @{
        "1" = { Show-VSCodeMenu }
        "2" = { Set-WinTermConfig }
        "3" = { Set-PwshConfig }
        "4" = { Set-OhMyPoshConfig }
        "5" = { Set-FastFetchConfig }
    } -ExitKey "6"
}

function Show-VSCodeMenu {
    Invoke-MenuLoop -Title "VSCode-Based Editor Config" -Items @(
        "[1] Visual Studio Code",
        "[2] Aide",
        "[3] Cursor",
        "[4] Windsurf",
        "[5] VSCodium",
        "[6] Trae",
        "[7] Other",
        "---",
        "[8] Back to menu"
    ) -Prompt "Select VSCode-based editor" -Actions @{
        "1" = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Code\User" }
        "2" = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Aide\User" }
        "3" = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Cursor\User" }
        "4" = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Windsurf\User" }
        "5" = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\VSCodium\User" }
        "6" = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Trae\User" }
        "7" = { Set-OtherVSCConfig }
    } -ExitKey "8"
}

function Show-WindowsCustomizationMenu {
    Invoke-MenuLoop -Title "Windows Customization Tweaks" -Items @(
        "[1] Set Short Date and Hours Format - Feb 17, 17:57",
        "[2] Disable automatic pin of folders to Quick Access",
        "[3] Selectively pull icons from folders in start menu",
        "---",
        "[4] Back to menu"
    ) -Actions @{
        "1" = { Set-ShortDateHours }
        "2" = { Disable-QuickAccess }
        "3" = { Expand-StartFolders }
    } -ExitKey "4"
}

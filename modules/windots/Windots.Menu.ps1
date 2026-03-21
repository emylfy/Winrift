function Show-MainMenu {
    Invoke-MenuLoop -Title "Windots - Rice & Customize Windows" -Items @(
        "[1] Terminal Setup",
        "[2] VSCode Configs",
        "[3] Third-party Apps",
        "[4] Customization Tweaks",
        "---",
        "[5] Back to Winrift"
    ) -Actions @{
        "1" = { Show-TerminalMenu }
        "2" = { Show-VSCodeMenu }
        "3" = { Show-AppsMenu }
        "4" = { Show-WindowsCustomizationMenu }
    } -ExitKey "5" -OnExit { Invoke-ReturnToMenu }
}

function Show-TerminalMenu {
    Invoke-MenuLoop -Title "Terminal Setup" -Items @(
        "[1] Windows Terminal",
        "[2] PowerShell Profile",
        "[3] Oh My Posh",
        "[4] FastFetch",
        "---",
        "[5] Back to menu"
    ) -Actions @{
        "1" = { Set-WinTermConfig }
        "2" = { Set-PwshConfig }
        "3" = { Set-OhMyPoshConfig }
        "4" = { Set-FastFetchConfig }
    } -ExitKey "5"
}

function Show-AppsMenu {
    Invoke-MenuLoop -Title "Third-party Apps" -Items @(
        "[1] Download Rectify11",
        "[2] Spotify Tools",
        "[3] Install Steam Millennium + Theme",
        "[4] Apply macOS Cursor",
        "--- Third-party tools below run via web scripts ---",
        "[5] Back to menu"
    ) -Actions @{
        "1" = { Invoke-Rectify11 }
        "2" = { Show-SpotifyToolsMenu }
        "3" = { Install-Steam }
        "4" = { Set-Cursor }
    } -ExitKey "5"
}

function Show-SpotifyToolsMenu {
    Invoke-MenuLoop -Title "Spotify Tools" -Items @(
        "[1] Install SpotX",
        "[2] Install Spicetify",
        "--- Third-party scripts fetched from the web ---",
        "[3] Back to menu"
    ) -Actions @{
        "1" = { Install-SpotX }
        "2" = { Install-Spicetify }
    } -ExitKey "3"
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

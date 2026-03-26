function Show-CustomizeMenu {
    Invoke-MenuLoop -Title "Customize" -Items @(
        "1 › Desktop - GlazeWM, status bar, launcher",
        "2 › Terminal - WT config, PS profile, prompts",
        "3 › Apps - Themes, editors, Spotify",
        "4 › Windows - Date format, Start Menu, misc",
        "5 › Restore Config Backups",
        "---",
        "6 › Back to Winrift"
    ) -Actions @{
        "1" = { Show-DesktopMenu }
        "2" = { Show-TerminalMenu }
        "3" = { Show-AppsMenu }
        "4" = { Show-WindowsMenu }
        "5" = { Restore-ConfigBackup }
    } -ExitKey "6"
}

function Show-DesktopMenu {
    Invoke-MenuLoop -Title "Desktop" -Items @(
        "1 › GlazeWM - Tiling window manager (i3wm)",
        "2 › Zebar / YASB - Status bar",
        "3 › Flow Launcher - App launcher (Alfred)",
        "4 › Windhawk - Reversible UI mods",
        "5 › Rainmeter - Desktop widgets",
        "6 › Wallpaper - Browse wallpaper collections",
        "---",
        "7 › Back"
    ) -Actions @{
        "1" = { Install-GlazeWM }
        "2" = { Install-StatusBar }
        "3" = { Install-FlowLauncher }
        "4" = { Install-Windhawk }
        "5" = { Install-Rainmeter }
        "6" = { Open-WallpaperBrowser }
    } -ExitKey "7"
}

function Show-TerminalMenu {
    Invoke-MenuLoop -Title "Terminal" -Items @(
        "1 › Windows Terminal config + Nerd Font",
        "2 › PowerShell Profile + Terminal-Icons",
        "3 › Oh My Posh - Shell prompt theme",
        "4 › FastFetch - System info display",
        "5 › Starship - Cross-platform prompt",
        "---",
        "6 › Back"
    ) -Actions @{
        "1" = { Set-WinTermConfig }
        "2" = { Set-PwshConfig }
        "3" = { Set-OhMyPoshConfig }
        "4" = { Set-FastFetchConfig }
        "5" = { Install-Starship }
    } -ExitKey "6"
}

function Show-AppsMenu {
    Invoke-MenuLoop -Title "Apps" -Items @(
        "1 › Import VSCode config (settings.json)",
        "--- Themes ---",
        "2 › Rectify11 - Windows 11 UI fixes",
        "3 › Spotify Tools",
        "4 › Steam Millennium + Theme",
        "---",
        "5 › Back"
    ) -Actions @{
        "1" = { Show-VSCodeConfigMenu }
        "2" = { Invoke-Rectify11 }
        "3" = { Show-SpotifyToolsMenu }
        "4" = { Install-SteamMillennium }
    } -ExitKey "5"
}

function Show-VSCodeConfigMenu {
    Show-MenuBox -Title "Import VSCode Config" -Items @(
        "Applies Winrift settings.json to your editor.",
        "Preview: github.com/emylfy/winrift/tree/main/modules/customize/config/vscode",
        "",
        "Select target editor:",
        "1 › Visual Studio Code",
        "2 › Cursor",
        "3 › Windsurf",
        "4 › VSCodium",
        "5 › Aide",
        "6 › Trae",
        "7 › Other (enter path)",
        "---",
        "8 › Back"
    )
    $choice =  Read-Host " "
    switch ($choice) {
        "1" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Code\User" }
        "2" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Cursor\User" }
        "3" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Windsurf\User" }
        "4" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\VSCodium\User" -IncludeProductJson }
        "5" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Aide\User" }
        "6" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Trae\User" }
        "7" { Set-OtherVSCodeConfig }
    }
}

function Show-SpotifyToolsMenu {
    Invoke-MenuLoop -Title "Spotify Tools" -Items @(
        "1 › Install SpotX",
        "2 › Install Spicetify",
        "---",
        "3 › Back"
    ) -Actions @{
        "1" = { Install-SpotX }
        "2" = { Install-Spicetify }
    } -ExitKey "3"
}

function Show-WindowsMenu {
    Invoke-MenuLoop -Title "Windows" -Items @(
        "1 › Set Date & Time format (MMM dd, HH:mm)",
        "2 › Disable Quick Access auto-pin",
        "3 › Organize Start Menu folders",
        "---",
        "4 › Back"
    ) -Actions @{
        "1" = { Set-ShortDateHours }
        "2" = { Disable-QuickAccess }
        "3" = { Expand-StartFolders }
    } -ExitKey "4"
}

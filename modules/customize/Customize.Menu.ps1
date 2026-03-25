function Show-CustomizeMenu {
    Invoke-MenuLoop -Title "Customize" -Items @(
        "1 › Desktop Environment",
        "2 › Terminal & Shell",
        "3 › Editor Configs",
        "4 › App Themes",
        "5 › Windows Look & Feel",
        "6 › Restore Config Backups",
        "---",
        "7 › Back to Winrift"
    ) -Actions @{
        "1" = { Show-DesktopMenu }
        "2" = { Show-TerminalMenu }
        "3" = { Show-VSCodeMenu }
        "4" = { Show-AppsMenu }
        "5" = { Show-WindowsLookMenu }
        "6" = { Restore-ConfigBackup }
    } -ExitKey "7"
}

function Show-DesktopMenu {
    Invoke-MenuLoop -Title "Desktop Environment" -Items @(
        "1 › GlazeWM - Tiling window manager (i3wm)",
        "2 › Zebar / YASB - Status bar",
        "3 › Flow Launcher - App launcher (Alfred)",
        "4 › Windhawk - Reversible UI mods",
        "5 › Rainmeter - Desktop widgets",
        "6 › Wallpaper - Browse wallpaper collections",
        "---",
        "7 › Back to Customize"
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
    Invoke-MenuLoop -Title "Terminal & Shell" -Items @(
        "1 › Windows Terminal config + Nerd Font",
        "2 › PowerShell Profile + Terminal-Icons",
        "3 › Oh My Posh - Shell prompt theme",
        "4 › FastFetch - System info display",
        "5 › Starship - Cross-platform prompt",
        "---",
        "6 › Back to Customize"
    ) -Actions @{
        "1" = { Set-WinTermConfig }
        "2" = { Set-PwshConfig }
        "3" = { Set-OhMyPoshConfig }
        "4" = { Set-FastFetchConfig }
        "5" = { Install-Starship }
    } -ExitKey "6"
}

function Show-AppsMenu {
    Invoke-MenuLoop -Title "App Themes" -Items @(
        "1 › Rectify11 - Windows 11 UI fixes",
        "2 › Spotify Tools",
        "3 › Steam Millennium + Theme",
        "4 › macOS Cursor",
        "--- Third-party tools fetched from the web ---",
        "5 › Back to Customize"
    ) -Actions @{
        "1" = { Invoke-Rectify11 }
        "2" = { Show-SpotifyToolsMenu }
        "3" = { Install-SteamMillennium }
        "4" = { Install-MacOSCursor }
    } -ExitKey "5"
}

function Show-SpotifyToolsMenu {
    Invoke-MenuLoop -Title "Spotify Tools" -Items @(
        "1 › Install SpotX",
        "2 › Install Spicetify",
        "--- Third-party scripts fetched from the web ---",
        "3 › Back to Customize"
    ) -Actions @{
        "1" = { Install-SpotX }
        "2" = { Install-Spicetify }
    } -ExitKey "3"
}

function Show-VSCodeMenu {
    Invoke-MenuLoop -Title "VSCode-Based Editor Config" -Items @(
        "1 › Visual Studio Code",
        "2 › Aide",
        "3 › Cursor",
        "4 › Windsurf",
        "5 › VSCodium",
        "6 › Trae",
        "7 › Other",
        "---",
        "8 › Back to Customize"
    ) -Prompt "Select VSCode-based editor" -Actions @{
        "1" = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Code\User" }
        "2" = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Aide\User" }
        "3" = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Cursor\User" }
        "4" = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Windsurf\User" }
        "5" = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\VSCodium\User" -IncludeProductJson }
        "6" = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Trae\User" }
        "7" = { Set-OtherVSCodeConfig }
    } -ExitKey "8"
}

function Show-WindowsLookMenu {
    Invoke-MenuLoop -Title "Windows Look & Feel" -Items @(
        "1 › Set Date & Time format (MMM dd, HH:mm)",
        "2 › Disable Quick Access auto-pin",
        "3 › Organize Start Menu folders",
        "---",
        "4 › Back to Customize"
    ) -Actions @{
        "1" = { Set-ShortDateHours }
        "2" = { Disable-QuickAccess }
        "3" = { Expand-StartFolders }
    } -ExitKey "4"
}

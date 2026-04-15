. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "Winrift - Customize"

Initialize-Logging -ModuleName "customize"

# Load sub-modules
. "$PSScriptRoot\Customize.Desktop.ps1"
. "$PSScriptRoot\Customize.Apps.ps1"
. "$PSScriptRoot\Customize.Configs.ps1"
. "$PSScriptRoot\Customize.Windows.ps1"
. "$PSScriptRoot\Customize.Profile.ps1"

function Show-ProfileBackupsMenu {
    Invoke-MenuLoop -Title "Profile & Backups" -Items @(
        "1 › Restore Config Backups",
        "---",
        "2 › Export Profile",
        "3 › Import Profile",
        "---",
        "4 › Back"
    ) -Actions @{
        "1" = { Restore-ConfigBackup }
        "2" = { Export-WinriftProfile }
        "3" = { Import-WinriftProfile }
    } -ExitKey "4"
}

function Show-CustomizeMenu {
    Invoke-MenuLoop -Title "Customize" -Items @(
        "1 › Desktop - GlazeWM, status bar, launcher",
        "2 › Terminal - WT config, PS profile, prompts",
        "3 › Apps - Themes, editors, Spotify",
        "4 › Windows - Date format, Start Menu, misc",
        "---",
        "5 › Profile & Backups",
        "---",
        "6 › Back to Winrift"
    ) -Actions @{
        "1" = { Show-DesktopMenu }
        "2" = { Show-TerminalMenu }
        "3" = { Show-AppsMenu }
        "4" = { Show-WindowsMenu }
        "5" = { Show-ProfileBackupsMenu }
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
        "0 › Full Shell Setup - Install & configure everything",
        "---",
        "1 › Windows Terminal config + Nerd Font",
        "2 › PowerShell Profile + Terminal-Icons",
        "3 › Oh My Posh - Shell prompt theme",
        "4 › FastFetch - System info display",
        "5 › Starship - Cross-platform prompt",
        "---",
        "6 › Back"
    ) -Actions @{
        "0" = { Invoke-ShellSetup }
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
        "2 › Spotify Tools",
        "3 › Steam Millennium + Theme",
        "---",
        "4 › Back"
    ) -Actions @{
        "1" = { Show-VSCodeConfigMenu }
        "2" = { Show-SpotifyToolsMenu }
        "3" = { Install-SteamMillennium }
    } -ExitKey "4"
}

function Show-VSCodeConfigMenu {
    $choice = Show-InteractiveMenu -Title "Import VSCode Config" -Items @(
        "Applies Winrift settings.json to your editor.",
        "Preview: github.com/emylfy/winrift/tree/main/modules/customize/config/vscode",
        "---",
        "1 › Visual Studio Code",
        "2 › Cursor",
        "3 › Windsurf",
        "4 › VSCodium",
        "5 › Trae",
        "6 › Other (enter path)",
        "---",
        "7 › Back"
    )
    switch ($choice) {
        "1" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Code\User" }
        "2" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Cursor\User" }
        "3" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Windsurf\User" }
        "4" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\VSCodium\User" -IncludeProductJson }
        "5" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Trae\User" }
        "6" { Set-OtherVSCodeConfig }
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

# Entry point
try {
    Show-CustomizeMenu
} finally {
    Stop-Transcript -ErrorAction SilentlyContinue
}

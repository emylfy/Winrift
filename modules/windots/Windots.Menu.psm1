function Show-MainMenu {
    Show-Menu -Title "Windots - Windows Customization" -Options @(
        @{ Key = "1"; Label = "Configs Installer"; Action = { Show-ConfigsMenu } },
        @{ Key = "2"; Label = "Download Rectify11"; Action = { Invoke-Rectify11 } },
        @{ Key = "3"; Label = "Install Spotify Tools"; Action = { Show-SpotifyToolsMenu } },
        @{ Key = "4"; Label = "Install Steam Millenium + Theme"; Action = { Install-Steam } },
        @{ Key = "5"; Label = "Apply macOS Cursor"; Action = { Set-Cursor } },
        @{ Key = "6"; Label = "Customization tweaks"; Action = { Show-WindowsCustomizationMenu } }
    ) -BackLabel "Back to Simplify11" -BackAction { & "$PSScriptRoot\..\..\simplify11.ps1" }
}

function Show-SpotifyToolsMenu {
    Show-Menu -Title "Spotify Tools" -Options @(
        @{ Key = "1"; Label = "Install SpotX"; Action = { Install-SpotX } },
        @{ Key = "2"; Label = "Install Spicetify"; Action = { Install-Spicetify } }
    ) -BackLabel "Return to Main Menu"
}

function Show-ConfigsMenu {
    Show-Menu -Title "Configs Installer" -Options @(
        @{ Key = "1"; Label = "VSCode Based"; Action = { Show-VSCodeMenu } },
        @{ Key = "2"; Label = "Windows Terminal"; Action = { Set-WinTermConfig } },
        @{ Key = "3"; Label = "PowerShell"; Action = { Set-PwshConfig } },
        @{ Key = "4"; Label = "Oh My Posh"; Action = { Set-OhMyPoshConfig } },
        @{ Key = "5"; Label = "FastFetch"; Action = { Set-FastFetchConfig } }
    ) -BackLabel "Return"
}

function Show-VSCodeMenu {
    Show-Menu -Title "VSCode-Based Editor" -Options @(
        @{ Key = "1"; Label = "Visual Studio Code"; Action = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Code\User" } },
        @{ Key = "2"; Label = "Aide"; Action = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Aide\User" } },
        @{ Key = "3"; Label = "Cursor"; Action = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Cursor\User" } },
        @{ Key = "4"; Label = "Windsurf"; Action = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Windsurf\User" } },
        @{ Key = "5"; Label = "VSCodium"; Action = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\VSCodium\User" } },
        @{ Key = "6"; Label = "Trae"; Action = { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Trae\User" } },
        @{ Key = "7"; Label = "Other"; Action = { Set-OtherVSCConfig } }
    ) -BackLabel "Return"
}

function Show-WindowsCustomizationMenu {
    Show-Menu -Title "Windows Customization" -Options @(
        @{ Key = "1"; Label = "Set Short Date and Hours Format - Feb 17, 17:57"; Action = { Set-ShortDateHours } },
        @{ Key = "2"; Label = "Disable automatic pin of folders to Quick Access"; Action = { Disable-QuickAccess } },
        @{ Key = "3"; Label = "Selectively pull icons from folders in start menu"; Action = { Expand-StartFolders } }
    ) -BackLabel "Return to Main Menu"
}

Export-ModuleMember -Function `
    Show-MainMenu, `
    Show-SpotifyToolsMenu, `
    Show-ConfigsMenu, `
    Show-VSCodeMenu, `
    Show-WindowsCustomizationMenu

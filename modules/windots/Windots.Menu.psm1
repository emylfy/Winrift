function Show-MainMenu {
    while ($true) {
        Clear-Host
        Show-MenuBox -Title "Windots - Rice & Customize Windows" -Items @(
            "[1] Configs Installer",
            "---",
            "[2] Download Rectify11",
            "[3] Install Spotify Tools",
            "[4] Install Steam Millennium + Theme",
            "[5] Apply macOS Cursor",
            "[6] Customization tweaks",
            "---",
            "[7] Back to Simplify11"
        )

        $choice = Read-Host ">"

        switch ($choice) {
            "1" { Show-ConfigsMenu; break }
            "2" { Invoke-Rectify11; break }
            "3" { Show-SpotifyToolsMenu; break }
            "4" { Install-Steam; break }
            "5" { Set-Cursor; break }
            "6" { Show-WindowsCustomizationMenu; break }
            "7" { Simplify11; return }
            default { }
        }
    }
}

function Show-SpotifyToolsMenu {
    while ($true) {
        Clear-Host
        Show-MenuBox -Title "Spotify Tools" -Items @(
            "[1] Install SpotX",
            "[2] Install Spicetify",
            "---",
            "[3] Return to Main Menu"
        )

        $choice = Read-Host ">"

        switch ($choice) {
            "1" { Install-SpotX; break }
            "2" { Install-Spicetify; break }
            "3" { return }
            default { }
        }
    }
}

function Show-ConfigsMenu {
    while ($true) {
        Clear-Host
        Show-MenuBox -Title "Configs Installer" -Items @(
            "[1] VSCode Based",
            "---",
            "[2] Windows Terminal",
            "[3] PowerShell",
            "[4] Oh My Posh",
            "[5] FastFetch",
            "---",
            "[6] Return"
        )

        $choice = Read-Host ">"

        switch ($choice) {
            "1" { Show-VSCodeMenu; break }
            "2" { Set-WinTermConfig; break }
            "3" { Set-PwshConfig; break }
            "4" { Set-OhMyPoshConfig; break }
            "5" { Set-FastFetchConfig; break }
            "6" { return }
            default { }
        }
    }
}

function Show-VSCodeMenu {
    while ($true) {
        Clear-Host
        Show-MenuBox -Title "VSCode-Based Editor Config" -Items @(
            "[1] Visual Studio Code",
            "[2] Aide",
            "[3] Cursor",
            "[4] Windsurf",
            "[5] VSCodium",
            "[6] Trae",
            "[7] Other",
            "---",
            "[8] Return"
        )

        $choice = Read-Host "Select VSCode-based editor"

        switch ($choice) {
            "1" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Code\User"; break }
            "2" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Aide\User"; break }
            "3" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Cursor\User"; break }
            "4" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Windsurf\User"; break }
            "5" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\VSCodium\User"; break }
            "6" { Set-VSCodeConfig "$env:USERPROFILE\AppData\Roaming\Trae\User"; break }
            "7" { Set-OtherVSCConfig; break }
            "8" { return }
            default { }
        }
    }
}

function Show-WindowsCustomizationMenu {
    while ($true) {
        Clear-Host
        Show-MenuBox -Title "Windows Customization Tweaks" -Items @(
            "[1] Set Short Date and Hours Format - Feb 17, 17:57",
            "[2] Disable automatic pin of folders to Quick Access",
            "[3] Selectively pull icons from folders in start menu",
            "---",
            "[4] Return to Main Menu"
        )

        $choice = Read-Host ">"

        switch ($choice) {
            "1" { Set-ShortDateHours; break }
            "2" { Disable-QuickAccess; break }
            "3" { Expand-StartFolders; break }
            "4" { return }
            default { }
        }
    }
}

function Simplify11 {
    return
}

Export-ModuleMember -Function `
    Show-MainMenu, `
    Show-SpotifyToolsMenu, `
    Show-ConfigsMenu, `
    Show-VSCodeMenu, `
    Show-WindowsCustomizationMenu, `
    Simplify11

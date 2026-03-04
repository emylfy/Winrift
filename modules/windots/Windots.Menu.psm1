function Show-MainMenu {
    Clear-Host
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Configs Installer               $Purple'$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [2] Download Rectify11              $Purple'$Reset"
    Write-Host "$Purple '$Reset [3] Install Spotify Tools           $Purple'$Reset"
    Write-Host "$Purple '$Reset [4] Install Steam Millenium + Theme $Purple'$Reset"
    Write-Host "$Purple '$Reset [5] Apply macOS Cursor              $Purple'$Reset"
    Write-Host "$Purple '$Reset [6] Customization tweaks            $Purple'$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [7] Back to Simplify11              $Purple'$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" { Show-ConfigsMenu }
        "2" { Invoke-Rectify11 }
        "3" { Show-SpotifyToolsMenu }
        "4" { Install-Steam }
        "5" { Apply-Cursor }
        "6" { Show-WindowsCustomizationMenu }
        "7" { Simplify11 }
        default { Show-MainMenu }
    }
}

function Show-SpotifyToolsMenu {
    cls
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Install SpotX                   $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] Install Spicetify               $Purple'$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [3] Return to Main Menu             $Purple'$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" { Install-SpotX }
        "2" { Install-Spicetify }
        "3" { Show-MainMenu }
        default { Show-SpotifyToolsMenu }
    }
}

function Show-ConfigsMenu {
    Clear-Host
    Write-Host "$Purple +-------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] VSCode Based        $Purple'$Reset"
    Write-Host "$Purple +-------------------------+$Reset"
    Write-Host "$Purple '$Reset [2] Windows Terminal    $Purple'$Reset"
    Write-Host "$Purple '$Reset [3] PowerShell          $Purple'$Reset"
    Write-Host "$Purple '$Reset [4] Oh My Posh          $Purple'$Reset"
    Write-Host "$Purple '$Reset [5] FastFetch           $Purple'$Reset"
    Write-Host "$Purple +-------------------------+$Reset"
    Write-Host "$Purple '$Reset [6] Return              $Purple'$Reset"
    Write-Host "$Purple +-------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" { Show-VSCodeMenu }
        "2" { Configure-WinTerm }
        "3" { Configure-Pwsh }
        "4" { Configure-OhMyPosh }
        "5" { Configure-FastFetch }
        "6" { Show-MainMenu }
        default { Show-ConfigsMenu }
    }
}

function Show-VSCodeMenu {
    Clear-Host
    Write-Host "$Purple +-------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Visual Studio Code  $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] Aide                $Purple'$Reset"
    Write-Host "$Purple '$Reset [3] Cursor              $Purple'$Reset"
    Write-Host "$Purple '$Reset [4] Windsurf            $Purple'$Reset"
    Write-Host "$Purple '$Reset [5] VSCodium            $Purple'$Reset"
    Write-Host "$Purple '$Reset [6] Trae                $Purple'$Reset"
    Write-Host "$Purple '$Reset [7] Other               $Purple'$Reset"
    Write-Host "$Purple +-------------------------+$Reset"
    Write-Host "$Purple '$Reset [8] Return              $Purple'$Reset"
    Write-Host "$Purple +-------------------------+$Reset"
    
    $choice = Read-Host "Select VSCode-based editor"
    
    switch ($choice) {
        "1" { Configure-VSCode "$env:USERPROFILE\AppData\Roaming\Code\User" }
        "2" { Configure-VSCode "$env:USERPROFILE\AppData\Roaming\Aide\User" }
        "3" { Configure-VSCode "$env:USERPROFILE\AppData\Roaming\Cursor\User" }
        "4" { Configure-VSCode "$env:USERPROFILE\AppData\Roaming\Windsurf\User" }
        "5" { Configure-VSCode "$env:USERPROFILE\AppData\Roaming\VSCodium\User" }
        "6" { Configure-VSCode "$env:USERPROFILE\AppData\Roaming\Trae\User" }
        "7" { Configure-OtherVSC }
        "8" { Show-ConfigsMenu }
        default { Show-VSCodeMenu }
    }
}

function Show-WindowsCustomizationMenu {
    Clear-Host
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Set Short Date and Hours Format - Feb 17, 17:57    $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] Disable automatic pin of folders to Quick Access   $Purple'$Reset"
    Write-Host "$Purple '$Reset [3] Selectively pull icons from folders in start menu  $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [4] Return to Main Menu                               $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"

    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" { Set-ShortDateHours }
        "2" { Disable-QuickAccess }
        "3" { Extract-StartFolders }
        "4" { Show-MainMenu }
        default { Show-WindowsCustomizationMenu }
    }
}

function Simplify11 {
    & "$PSScriptRoot\..\..\simplify11.ps1"
    Show-MainMenu
}

Export-ModuleMember -Function `
    Show-MainMenu, `
    Show-SpotifyToolsMenu, `
    Show-ConfigsMenu, `
    Show-VSCodeMenu, `
    Show-WindowsCustomizationMenu, `
    Simplify11


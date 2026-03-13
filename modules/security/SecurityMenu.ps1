. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-SecurityMenu {
    $Host.UI.RawUI.WindowTitle = "Security & Privacy Tools"
    Show-Menu -Title "Security & Privacy Tools" -Options @(
        @{ Key = "1"; Label = "DefendNot - Disable Windows Defender"; Action = {
            . "$PSScriptRoot\..\..\scripts\AdminLaunch.ps1"
            Start-AdminProcess -ScriptPath "$PSScriptRoot\DefendNot.ps1" -NoExit
        }},
        @{ Key = "2"; Label = "RemoveWindowsAI - Remove Copilot & Recall"; Action = {
            . "$PSScriptRoot\..\..\scripts\AdminLaunch.ps1"
            Start-AdminProcess -ScriptPath "$PSScriptRoot\RemoveWindowsAI.ps1" -NoExit
        }},
        @{ Key = "3"; Label = "Privacy.sexy - Enforce privacy and security"; Action = {
            . "$PSScriptRoot\..\..\scripts\AdminLaunch.ps1"
            Start-AdminProcess -ScriptPath "$PSScriptRoot\PrivacySexy.ps1" -NoExit
        }}
    ) -BackLabel "Return to Main Menu" -BackAction { & "$PSScriptRoot\..\..\simplify11.ps1" }
}

Show-SecurityMenu

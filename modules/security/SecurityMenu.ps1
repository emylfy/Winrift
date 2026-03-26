. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "Security & Privacy Tools"

Initialize-Logging -ModuleName "security"

function Show-SecurityMenu {
    $menuRoot = $PSScriptRoot
    Invoke-MenuLoop -Title "Security & Privacy Tools" -Items @(
        "1 › DefendNot - Disable Windows Defender",
        "2 › RemoveWindowsAI - Remove Copilot & Recall",
        "3 › Privacy.sexy - Enforce privacy and security",
        "---",
        "4 › Back to menu"
    ) -Actions @{
        "1" = { Start-AdminProcess -ScriptPath "$menuRoot\DefendNot.ps1" }
        "2" = { Start-AdminProcess -ScriptPath "$menuRoot\RemoveWindowsAI.ps1" }
        "3" = { Start-AdminProcess -ScriptPath "$menuRoot\PrivacySexy.ps1" }
    } -ExitKey "4"
}

Show-SecurityMenu

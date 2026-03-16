. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "RemoveWindowsAI - Remove Windows AI Features"

function Show-RemoveWindowsAIMenu {
    $tool = Get-ToolConfig "removewindowsai"
    Invoke-MenuLoop -Title "RemoveWindowsAI - Remove Copilot, Recall & More" -Items @(
        "[1] Launch RemoveWindowsAI",
        "[2] Open documentation / project source",
        "---",
        "[3] Back to menu"
    ) -Actions @{
        "1" = {
            Clear-Host
            Invoke-Tool "removewindowsai"
            Read-Host "Press Enter to continue"
        }
        "2" = { Start-Process $tool.docs }
    } -ExitKey "3" -OnExit { & "$PSScriptRoot\SecurityMenu.ps1" }
}

Show-RemoveWindowsAIMenu

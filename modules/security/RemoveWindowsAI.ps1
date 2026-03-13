. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-RemoveWindowsAIMenu {
    $Host.UI.RawUI.WindowTitle = "RemoveWindowsAI - Remove Windows AI Features"
    Show-Menu -Title "RemoveWindowsAI - Remove Copilot, Recall & More" -Options @(
        @{ Key = "1"; Label = "Launch RemoveWindowsAI"; Action = {
            Clear-Host
            try {
                & ([scriptblock]::Create((irm "https://raw.githubusercontent.com/zoicware/RemoveWindowsAI/main/RemoveWindowsAi.ps1")))
            } catch {
                Write-Host "$Red Failed to launch RemoveWindowsAI: $($_.Exception.Message)$Reset"
                Read-Host "Press Enter to continue"
            }
        }},
        @{ Key = "2"; Label = "Open documentation / project source"; Action = {
            Start-Process "https://github.com/zoicware/RemoveWindowsAI"
        }}
    ) -BackLabel "Return to Menu"
}

Show-RemoveWindowsAIMenu

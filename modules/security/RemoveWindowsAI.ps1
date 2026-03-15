. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "RemoveWindowsAI - Remove Windows AI Features"

function Show-RemoveWindowsAIMenu {
    while ($true) {
        Clear-Host
        Show-MenuBox -Title "RemoveWindowsAI - Remove Copilot, Recall & More" -Items @(
            "[1] Launch RemoveWindowsAI",
            "[2] Open documentation / project source",
            "---",
            "[3] Back to Menu"
        )

        $choice = Read-Host ">"

        switch ($choice) {
            "1" {
                Clear-Host
                try {
                    & ([scriptblock]::Create((irm "https://raw.githubusercontent.com/zoicware/RemoveWindowsAI/main/RemoveWindowsAi.ps1")))
                } catch {
                    Write-Log -Message "Failed to launch RemoveWindowsAI: $($_.Exception.Message)" -Level ERROR
                    Read-Host "Press Enter to continue"
                }
                break
            }
            "2" { Start-Process "https://github.com/zoicware/RemoveWindowsAI"; break }
            "3" { return }
            default { }
        }
    }
}

Show-RemoveWindowsAIMenu

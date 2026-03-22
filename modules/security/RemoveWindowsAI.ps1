. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "RemoveWindowsAI - Remove Windows AI Features"

$tool = Get-ToolConfig "removewindowsai"

Clear-Host
Show-MenuBox -Title "RemoveWindowsAI - Remove Copilot & Recall" -Items @(
    "This will fetch and run a script from the web.",
    "You can choose what to remove during the process.",
    "",
    "URL:    $($tool.url)",
    "Source: $($tool.docs)",
    "---",
    "[Y] Run  [N] Cancel  [R] Review source"
)

while ($true) {
    $choice = Read-Host ">"
    switch ($choice.ToUpper()) {
        "Y" {
            Invoke-Tool "removewindowsai" -SkipConfirm
            Read-Host "Press Enter to continue"
            & "$PSScriptRoot\SecurityMenu.ps1"
            return
        }
        "N" {
            & "$PSScriptRoot\SecurityMenu.ps1"
            return
        }
        "R" {
            if ($tool.docs) {
                Start-Process $tool.docs
                Write-Host "$Green  Opened project source in browser.$Reset"
            }
        }
        default { Write-Host "  Please enter Y, N, or R." }
    }
}

. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "DefendNot - Disable Windows Defender"

function Show-DefendNotMenu {
    $tool = Get-ToolConfig "defendnot"
    Invoke-MenuLoop -Title "DefendNot - Disable Windows Defender via WSC API" -Items @(
        "[1] Launch DefendNot",
        "[2] Open documentation / project source",
        "---",
        "[3] Back to menu"
    ) -Actions @{
        "1" = {
            Write-Host ""
            Write-Log -Message "Warning: Windows Defender may flag this tool." -Level WARNING
            Write-Log -Message "You may need to temporarily disable real-time and tamper protection." -Level WARNING
            Invoke-Tool "defendnot"
            Read-Host "Press Enter to continue"
        }
        "2" = { Start-Process $tool.docs }
    } -ExitKey "3" -OnExit { & "$PSScriptRoot\SecurityMenu.ps1" }
}

Show-DefendNotMenu

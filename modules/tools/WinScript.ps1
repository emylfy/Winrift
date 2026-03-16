. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-WinScriptMenu {
    $Host.UI.RawUI.WindowTitle = "WinScript Launcher"
    $tool = Get-ToolConfig "winscript"
    Invoke-MenuLoop -Title "WinScript - Make Windows Yours" -Items @(
        "[1] Open online version",
        "[2] Run portable version",
        "---",
        "[3] Back to menu"
    ) -Prompt "Select an option" -Actions @{
        "1" = { Start-Process $tool.docs }
        "2" = {
            Invoke-Tool "winscript"
            Read-Host "Press Enter to continue"
        }
    } -ExitKey "3" -OnExit { Invoke-ReturnToMenu }
}

Show-WinScriptMenu

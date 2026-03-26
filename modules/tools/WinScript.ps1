. "$PSScriptRoot\..\..\scripts\Common.ps1"
Initialize-Logging -ModuleName "winscript"

function Show-WinScriptMenu {
    $Host.UI.RawUI.WindowTitle = "WinScript Launcher"
    $tool = Get-ToolConfig "winscript"
    Invoke-MenuLoop -Title "WinScript - Make Windows Yours" -Items @(
        "1 › Open online version",
        "2 › Run portable version",
        "R › Review project source",
        "---",
        "3 › Back to menu"
    ) -Actions @{
        "1" = { Start-Process $tool.docs }
        "2" = {
            $null = Invoke-Tool "winscript"
            Read-Host "Press Enter to continue"
        }
        "R" = { Start-Process $tool.docs }
    } -ExitKey "3"
}

Show-WinScriptMenu

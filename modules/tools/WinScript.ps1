. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-WinScriptMenu {
    $Host.UI.RawUI.WindowTitle = "WinScript Launcher"
    Show-Menu -Title "Winscript - Make Windows Yours" -Options @(
        @{ Key = "1"; Label = "Open online version"; Action = {
            Start-Process "https://winscript.cc/online/"
        }},
        @{ Key = "2"; Label = "Run portable version"; Action = {
            Write-Host "$Green Running portable WinScript... $Reset"
            try {
                $scriptContent = Invoke-RestMethod -Uri "https://winscript.cc/irm" -ErrorAction Stop
                Invoke-Expression $scriptContent
            } catch {
                Write-Host "$Red Failed to launch portable WinScript: $($_.Exception.Message) $Reset"
                Read-Host "Press Enter to continue"
            }
        }}
    ) -BackLabel "Back to Simplify11" -BackAction { & "$PSScriptRoot\..\..\simplify11.ps1" }
}

Show-WinScriptMenu

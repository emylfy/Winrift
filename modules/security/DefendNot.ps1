. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-DefendNotMenu {
    $Host.UI.RawUI.WindowTitle = "DefendNot - Disable Windows Defender"
    Show-Menu -Title "DefendNot - Disable Windows Defender via WSC API" -Options @(
        @{ Key = "1"; Label = "Launch DefendNot"; Action = {
            Write-Host ""
            Write-Host "$Yellow Warning: Windows Defender may flag this tool.$Reset"
            Write-Host "$Yellow You may need to temporarily disable real-time and tamper protection.$Reset"
            Write-Host "$Green Installing DefendNot...$Reset"
            try {
                irm https://dnot.sh/ | iex
                Write-Host "$Green DefendNot installed successfully.$Reset"
            } catch {
                Write-Host "$Red Failed to install DefendNot: $($_.Exception.Message)$Reset"
            }
            Read-Host "Press Enter to continue"
        }},
        @{ Key = "2"; Label = "Open documentation / project source"; Action = {
            Start-Process "https://github.com/es3n1n/defendnot"
        }}
    ) -BackLabel "Return to Menu"
}

Show-DefendNotMenu

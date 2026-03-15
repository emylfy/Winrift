. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "DefendNot - Disable Windows Defender"

function Show-DefendNotMenu {
    while ($true) {
        Clear-Host
        Show-MenuBox -Title "DefendNot - Disable Windows Defender via WSC API" -Items @(
            "[1] Launch DefendNot",
            "[2] Open documentation / project source",
            "---",
            "[3] Return to Menu"
        )

        $choice = Read-Host ">"

        switch ($choice) {
            "1" {
                Write-Host ""
                Write-Log -Message "Warning: Windows Defender may flag this tool." -Level WARNING
                Write-Log -Message "You may need to temporarily disable real-time and tamper protection." -Level WARNING
                Write-Log -Message "Installing DefendNot..." -Level INFO
                try {
                    irm https://dnot.sh/ | iex
                    Write-Log -Message "DefendNot installed successfully." -Level SUCCESS
                } catch {
                    Write-Log -Message "Failed to install DefendNot: $($_.Exception.Message)" -Level ERROR
                }
                Read-Host "Press Enter to continue"
                break
            }
            "2" { Start-Process "https://github.com/es3n1n/defendnot"; break }
            "3" { return }
            default { }
        }
    }
}

Show-DefendNotMenu

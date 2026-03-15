. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-WinScriptMenu {
    $Host.UI.RawUI.WindowTitle = "WinScript Launcher"

    while ($true) {
        Clear-Host
        Show-MenuBox -Title "WinScript - Make Windows Yours" -Items @(
            "[1] Open online version",
            "[2] Run portable version",
            "---",
            "[3] Back to menu"
        )

        $choice = Read-Host "Select an option"

        switch ($choice) {
            "1" {
                Start-Process "https://winscript.cc/online/"
                break
            }
            "2" {
                Write-Log -Message "Running portable WinScript..." -Level INFO
                try {
                    $scriptContent = Invoke-RestMethod -Uri "https://winscript.cc/irm" -ErrorAction Stop
                    Invoke-Expression $scriptContent
                } catch {
                    Write-Log -Message "Failed to launch portable WinScript: $($_.Exception.Message)" -Level ERROR
                    Read-Host "Press Enter to continue"
                }
                break
            }
            "3" { return }
            default { }
        }
    }
}

Show-WinScriptMenu

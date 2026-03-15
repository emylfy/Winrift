. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-PrivacySexyMenu {
    $Host.UI.RawUI.WindowTitle = "Privacy.sexy Launcher"

    while ($true) {
        Clear-Host
        Show-MenuBox -Title "Privacy.sexy - Privacy & Security Hardening" -Items @(
            "[1] Build your own batch from privacy.sexy website",
            "[2] Execute latest standard preset (for most users)",
            "---",
            "[3] Back to Menu"
        )

        $choice = Read-Host ">"

        switch ($choice) {
            "1" {
                Start-Process "https://privacy.sexy"
                break
            }
            "2" {
                Write-Log -Message "Downloading and executing privacy script..." -Level INFO
                try {
                    Invoke-RestMethod 'https://privacylearn.com/downloads/windows/standard.bat' -OutFile "$env:TEMP\standard.bat"
                    Start-Process cmd -ArgumentList "/c `"$env:TEMP\standard.bat`"" -Wait
                    Write-Log -Message "Privacy script executed successfully." -Level SUCCESS
                } catch {
                    Write-Log -Message "Failed to execute privacy script." -Level ERROR
                }
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                break
            }
            "3" { return }
            default { }
        }
    }
}

Show-PrivacySexyMenu

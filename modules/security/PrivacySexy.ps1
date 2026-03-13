. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-PrivacySexyMenu {
    $Host.UI.RawUI.WindowTitle = "Privacy.sexy Launcher"
    Show-Menu -Title "Privacy.sexy - Enforce Privacy & Security" -Options @(
        @{ Key = "1"; Label = "Build your own batch from privacy.sexy website"; Action = {
            Start-Process "https://privacy.sexy"
        }},
        @{ Key = "2"; Label = "Execute latest standard preset (for most users)"; Action = {
            Write-Host "$Reset Downloading and executing privacy script...$Reset"
            try {
                Invoke-RestMethod 'https://privacylearn.com/downloads/windows/standard.bat' -OutFile "$env:TEMP\standard.bat"
                Start-Process cmd -ArgumentList "/c `"$env:TEMP\standard.bat`"" -Wait
                Write-Host "$Green Privacy script executed successfully.$Reset"
            } catch {
                Write-Host "$Red Failed to execute privacy script.$Reset"
            }
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }}
    ) -BackLabel "Return to Menu"
}

Show-PrivacySexyMenu

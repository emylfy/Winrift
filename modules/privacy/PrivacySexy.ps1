. "$PSScriptRoot\..\..\scripts\common.ps1"

function Show-PrivacySexyMenu {
    $Host.UI.RawUI.WindowTitle = "Privacy.sexy Launcher"
    Clear-Host

    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Build your own batch from privacy.sexy website     $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] Execute latest standard preset (for most users)    $Purple'$Reset"
    Write-Host "$Purple '$Reset [3] Back to Main Menu                                  $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" {
            Start-Process "https://privacy.sexy"
            Show-PrivacySexyMenu
        }
        "2" {
            Write-Host "$Reset`Downloading and executing privacy script...$Reset"
            try {
                Invoke-RestMethod 'https://privacylearn.com/downloads/windows/standard.bat' -OutFile "$env:TEMP\standard.bat"
                Start-Process cmd -ArgumentList "/c `"$env:TEMP\standard.bat`"" -Wait
                Write-Host "$Green`Privacy script executed successfully.$Reset"
            } catch {
                Write-Host "$Red`Failed to execute privacy script.$Reset"
            }
            
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            Show-PrivacySexyMenu
        }
        "3" {
            return
        }
        default {
            Write-Host "$Red`Invalid choice. Please try again.$Reset"
            Start-Sleep -Seconds 1
            Show-PrivacySexyMenu
        }
    }
}

Show-PrivacySexyMenu
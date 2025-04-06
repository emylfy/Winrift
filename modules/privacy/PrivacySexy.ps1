. "$PSScriptRoot\..\..\scripts\common.ps1"

$Purple = "$([char]0x1b)[38;5;141m"
$Grey = "$([char]0x1b)[38;5;250m"
$Reset = "$([char]0x1b)[0m"
$Red = "$([char]0x1b)[38;5;203m"
$Green = "$([char]0x1b)[38;5;120m"

function Show-PrivacySexyMenu {
    Clear-Host

    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [1] Build your own batch from privacy.sexy website     $Purple'$Reset"
    Write-Host "$Purple '$Grey [2] Download and Run Standard preset (for most users)  $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] Back to Main Menu                                  $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" {
            Start-Process "https://privacy.sexy"
            Show-PrivacySexyMenu
        }
        "2" {
            Write-Host "$Grey`Downloading and executing privacy script...$Reset"
            try {
                Invoke-RestMethod 'https://raw.githubusercontent.com/emylfy/simplify11/refs/heads/main/modules/tweaks/Privacy.bat' -OutFile "$env:TEMP\Privacy.bat"
                Start-Process cmd -ArgumentList "/c `"$env:TEMP\Privacy.bat`"" -Wait
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
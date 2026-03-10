. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "Security & Privacy Tools"

function Show-SecurityMenu {
    Clear-Host
    Write-Host
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Purple   Security & Privacy Tools                             $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] DefendNot - Disable Windows Defender                $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] RemoveWindowsAI - Remove Copilot & Recall           $Purple'$Reset"
    Write-Host "$Purple '$Reset [3] Privacy.sexy - Enforce privacy and security         $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [4] Return to Main Menu                                 $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" {
            . "$PSScriptRoot\..\..\scripts\AdminLaunch.ps1"
            Start-AdminProcess -ScriptPath "$PSScriptRoot\DefendNot.ps1" -NoExit
            Show-SecurityMenu
        }
        "2" {
            . "$PSScriptRoot\..\..\scripts\AdminLaunch.ps1"
            Start-AdminProcess -ScriptPath "$PSScriptRoot\RemoveWindowsAI.ps1" -NoExit
            Show-SecurityMenu
        }
        "3" {
            . "$PSScriptRoot\..\..\scripts\AdminLaunch.ps1"
            Start-AdminProcess -ScriptPath "$PSScriptRoot\..\privacy\PrivacySexy.ps1" -NoExit
            Show-SecurityMenu
        }
        "4" { return }
        default { Show-SecurityMenu }
    }
}

Show-SecurityMenu

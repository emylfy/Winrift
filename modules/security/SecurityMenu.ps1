. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "Security & Privacy Tools"

# Start logging
$logDir = Join-Path $env:USERPROFILE "Simplify11\logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$script:LogFile = Join-Path $logDir "security_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"

function Show-SecurityMenu {
    while ($true) {
        Clear-Host
        Show-MenuBox -Title "Security & Privacy Tools" -Items @(
            "[1] DefendNot - Disable Windows Defender",
            "[2] RemoveWindowsAI - Remove Copilot & Recall",
            "[3] Privacy.sexy - Enforce privacy and security",
            "---",
            "[4] Return to Main Menu"
        )

        $choice = Read-Host ">"

        switch ($choice) {
            "1" {
                . "$PSScriptRoot\..\..\scripts\AdminLaunch.ps1"
                Start-AdminProcess -ScriptPath "$PSScriptRoot\DefendNot.ps1" -NoExit
                break
            }
            "2" {
                . "$PSScriptRoot\..\..\scripts\AdminLaunch.ps1"
                Start-AdminProcess -ScriptPath "$PSScriptRoot\RemoveWindowsAI.ps1" -NoExit
                break
            }
            "3" {
                . "$PSScriptRoot\..\..\scripts\AdminLaunch.ps1"
                Start-AdminProcess -ScriptPath "$PSScriptRoot\..\privacy\PrivacySexy.ps1" -NoExit
                break
            }
            "4" { return }
            default { }
        }
    }
}

Show-SecurityMenu

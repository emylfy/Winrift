. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "Windots"

# Start logging
$logDir = Join-Path $env:USERPROFILE "Simplify11\logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$script:LogFile = Join-Path $logDir "windots_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"

# Import modularized functionality
Import-Module "$PSScriptRoot\Windots.Menu.psm1" -Force
Import-Module "$PSScriptRoot\Windots.Apps.psm1" -Force
Import-Module "$PSScriptRoot\Windots.Configs.psm1" -Force
Import-Module "$PSScriptRoot\Windots.Customization.psm1" -Force

# Entry point
Show-MainMenu

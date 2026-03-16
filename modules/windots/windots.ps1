. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "Windots"

# Start logging
$logDir = Join-Path $env:USERPROFILE "Simplify11\logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$script:LogFile = Join-Path $logDir "windots_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
Start-Transcript -Path $script:LogFile -Append | Out-Null
Write-Log -Message "Session log: $script:LogFile" -Level INFO

# Load sub-modules
. "$PSScriptRoot\Windots.Menu.ps1"
. "$PSScriptRoot\Windots.Apps.ps1"
. "$PSScriptRoot\Windots.Configs.ps1"
. "$PSScriptRoot\Windots.Customization.ps1"

# Entry point
Show-MainMenu
Invoke-ReturnToMenu

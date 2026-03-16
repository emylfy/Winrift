. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "Windots"

Initialize-Logging -ModuleName "windots"

# Load sub-modules
. "$PSScriptRoot\Windots.Menu.ps1"
. "$PSScriptRoot\Windots.Apps.ps1"
. "$PSScriptRoot\Windots.Configs.ps1"
. "$PSScriptRoot\Windots.Customization.ps1"

# Entry point
Show-MainMenu
Invoke-ReturnToMenu

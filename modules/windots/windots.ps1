. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "Windots"

# Import modularized functionality
Import-Module "$PSScriptRoot\Windots.Menu.psm1" -Force
Import-Module "$PSScriptRoot\Windots.Apps.psm1" -Force
Import-Module "$PSScriptRoot\Windots.Configs.psm1" -Force
Import-Module "$PSScriptRoot\Windots.Customization.psm1" -Force

# Entry point
Show-MainMenu
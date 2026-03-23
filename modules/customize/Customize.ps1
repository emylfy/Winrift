. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "Winrift - Customize"

Initialize-Logging -ModuleName "customize"

# Load sub-modules
. "$PSScriptRoot\Customize.Menu.ps1"
. "$PSScriptRoot\Customize.Desktop.ps1"
. "$PSScriptRoot\Customize.Apps.ps1"
. "$PSScriptRoot\Customize.Configs.ps1"
. "$PSScriptRoot\Customize.Windows.ps1"

# Entry point
try {
    Show-CustomizeMenu
} finally {
    Stop-Transcript -ErrorAction SilentlyContinue
}

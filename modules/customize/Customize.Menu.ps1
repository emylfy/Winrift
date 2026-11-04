. "$PSScriptRoot\..\..\scripts\Common.ps1"
. "$PSScriptRoot\Customize.Desktop.ps1"
. "$PSScriptRoot\Customize.Configs.ps1"
. "$PSScriptRoot\Customize.Windows.ps1"
. "$PSScriptRoot\Customize.Profile.ps1"
. "$PSScriptRoot\AppConfiguration.ps1"

# Compatibility entry points use the same product navigation.
function Show-CustomizeMenu { Show-WinriftAppConfiguration }
function Show-DesktopMenu { Show-WinriftDesktop }
function Show-WindowsMenu { Show-WinriftPreferences }
function Show-ProfileBackupsMenu { Show-WinriftSaveRestore }

if($MyInvocation.InvocationName -ne '.'){
    $script:Root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    . "$script:Root\scripts\Navigation.ps1"
    Show-CustomizeMenu
}
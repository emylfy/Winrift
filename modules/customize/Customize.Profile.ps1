. "$PSScriptRoot\..\profile\Profile.ps1"
. "$PSScriptRoot\..\profile\Setup.ps1"
function Export-WinriftProfile { Save-WinriftSetup }
function Import-WinriftProfile { Restore-WinriftSetup }
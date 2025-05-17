. "$PSScriptRoot\..\..\scripts\Common.ps1"

$Host.UI.RawUI.WindowTitle = "WinUtil Launcher"

Clear-Host
Write-Host ""
Write-Host "$Purple +-----------------------------------+$Reset"
Write-Host "$Purple '$Reset Launching Windows Utility Tool... $Purple'$Reset"
Write-Host "$Purple +-----------------------------------+$Reset"

try {
    Invoke-Expression (Invoke-RestMethod -Uri 'https://christitus.com/win')
} catch {
    Write-Host "$Red Failed to launch Windows Utility Tool: $_$Reset"
    pause
}

exit
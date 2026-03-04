. "$PSScriptRoot\..\..\scripts\Common.ps1"

$Host.UI.RawUI.WindowTitle = "Sparkle Launcher"

try {
    irm https://raw.githubusercontent.com/Parcoil/Sparkle/v2/get.ps1 | iex
} catch {
    Write-Host "$Red Failed to launch Sparkle: $($_.Exception.Message) $Reset"
    exit 1
}

exit

. "$PSScriptRoot\..\..\scripts\Common.ps1"
Initialize-Logging -ModuleName "justthebrowser"
$Host.UI.RawUI.WindowTitle = "Just the Browser - Browser Hardening"

$null = Invoke-Tool "justthebrowser"
Wait-ForUser

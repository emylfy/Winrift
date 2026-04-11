. "$PSScriptRoot\..\..\scripts\Common.ps1"
Initialize-Logging -ModuleName "removewindowsai"
$Host.UI.RawUI.WindowTitle = "RemoveWindowsAI - Remove Windows AI Features"

$null = Invoke-Tool "removewindowsai"
Wait-ForUser

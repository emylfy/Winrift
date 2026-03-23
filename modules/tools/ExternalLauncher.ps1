# Config-driven external tool launcher
# All tool definitions live in config/tools.json - no more per-tool wrapper files

param(
    [Parameter(Mandatory = $true)]
    [string]$ToolId
)

. "$PSScriptRoot\..\..\scripts\Common.ps1"

$tool = Get-ToolConfig $ToolId
if ($tool) {
    $Host.UI.RawUI.WindowTitle = "$($tool.name) Launcher"
}

Invoke-Tool $ToolId
Wait-ForUser

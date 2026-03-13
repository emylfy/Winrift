. "$PSScriptRoot\..\..\scripts\Common.ps1"

# Config-driven external tool launcher
# All tool definitions live in config/tools.json — no more per-tool wrapper files

param(
    [Parameter(Mandatory = $true)]
    [string]$ToolId
)

$toolsFile = Join-Path $PSScriptRoot "..\..\config\tools.json"
if (-not (Test-Path $toolsFile)) {
    Write-Host "$Red Could not find tools.json at $toolsFile$Reset"
    exit 1
}

$toolsConfig = Get-Content $toolsFile -Raw | ConvertFrom-Json
$tool = $toolsConfig.tools | Where-Object { $_.id -eq $ToolId }

if (-not $tool) {
    Write-Host "$Red Unknown tool: $ToolId$Reset"
    exit 1
}

$Host.UI.RawUI.WindowTitle = "$($tool.name) Launcher"

Write-Header -Text "Launching $($tool.name)..."

try {
    switch ($tool.type) {
        "irm" {
            $scriptContent = Invoke-RestMethod -Uri $tool.url -ErrorAction Stop
            Invoke-Expression $scriptContent
        }
        "download" {
            $downloadPath = Join-Path $env:TEMP $tool.filename
            Invoke-WebRequest -Uri $tool.url -OutFile $downloadPath -UseBasicParsing -ErrorAction Stop
            if (Test-Path $downloadPath) {
                Start-Process -FilePath $downloadPath
            } else {
                Write-Host "$Red Failed to download $($tool.name)$Reset"
                exit 1
            }
        }
        default {
            Write-Host "$Red Unknown tool type: $($tool.type)$Reset"
            exit 1
        }
    }
} catch {
    Write-Host "$Red Failed to launch $($tool.name): $($_.Exception.Message)$Reset"
    exit 1
}

exit

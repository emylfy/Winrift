. "$PSScriptRoot\..\..\scripts\Common.ps1"
# https://github.com/SysadminWorld/Win11Tweaks
# https://github.com/AlchemyTweaks/Verified-Tweaks
# https://github.com/SanGraphic/QuickBoost
# Every tweak in this script has been thoroughly tested and compared across multiple sources.
# Only the most effective values and best practices have been selected for this collection.
# Detailed information can be found in the source link provided for each tweak.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Not running as admin. Elevating..." -ForegroundColor Yellow
    . "$PSScriptRoot\..\..\scripts\AdminLaunch.ps1"
    Start-AdminProcess -ScriptPath $PSCommandPath
    exit
}

# Start logging
$logDir = Join-Path $env:USERPROFILE "Simplify11\logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$script:LogFile = Join-Path $logDir "tweaks_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
Start-Transcript -Path $script:LogFile -Append | Out-Null
Write-Log -Message "Session log: $script:LogFile" -Level INFO

# Load sub-modules
. "$PSScriptRoot\Tweaks.Universal.ps1"
. "$PSScriptRoot\Tweaks.GPU.ps1"
. "$PSScriptRoot\Tweaks.Cleanup.ps1"

function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Simplify11 - System Tweaks"

    while ($true) {
        Clear-Host
        Show-MenuBox -Title "System Tweaks" -Items @(
            "[1] Universal Tweaks",
            "[2] NVIDIA/AMD GPU Tweaks",
            "[3] Free Up Space",
            "---",
            "[4] Open Documentation",
            "[5] Back to menu"
        )

        $choice = Read-Host "Enter your choice (1-5)"

        switch ($choice) {
            "1" { Invoke-UniversalTweaks; break }
            "2" { Show-GPUMenu; break }
            "3" { Clear-SystemSpace; break }
            "4" { Start-Process "https://github.com/emylfy/simplify11/blob/main/docs/tweaks_guide.md"; break }
            "5" { Invoke-ReturnToMenu; return }
            default { }
        }
    }
}

Show-MainMenu

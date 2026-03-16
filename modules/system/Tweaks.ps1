. "$PSScriptRoot\..\..\scripts\Common.ps1"
# https://github.com/SysadminWorld/Win11Tweaks
# https://github.com/AlchemyTweaks/Verified-Tweaks
# https://github.com/SanGraphic/QuickBoost
# Every tweak in this script has been thoroughly tested and compared across multiple sources.
# Only the most effective values and best practices have been selected for this collection.
# Detailed information can be found in the source link provided for each tweak.

Assert-AdminOrElevate
Initialize-Logging -ModuleName "tweaks"

# Load sub-modules
. "$PSScriptRoot\Tweaks.Universal.ps1"
. "$PSScriptRoot\Tweaks.GPU.ps1"
. "$PSScriptRoot\Tweaks.Cleanup.ps1"

function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Simplify11 - System Tweaks"
    Invoke-MenuLoop -Title "System Tweaks" -Items @(
        "[1] Universal Tweaks",
        "[2] NVIDIA/AMD GPU Tweaks",
        "[3] Free Up Space",
        "---",
        "[4] Open Documentation",
        "[5] Back to menu"
    ) -Prompt "Enter your choice (1-5)" -Actions @{
        "1" = { Invoke-UniversalTweaks }
        "2" = { Show-GPUMenu }
        "3" = { Clear-SystemSpace }
        "4" = { Start-Process "https://github.com/emylfy/simplify11/blob/main/docs/tweaks_guide.md" }
    } -ExitKey "5" -OnExit { Invoke-ReturnToMenu }
}

Show-MainMenu

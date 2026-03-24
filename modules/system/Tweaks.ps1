. "$PSScriptRoot\..\..\scripts\Common.ps1"
# https://github.com/AlchemyTweaks/Verified-Tweaks
# https://github.com/SanGraphic/QuickBoost
# Every tweak in this script has been thoroughly tested and compared across multiple sources.
# Only the most effective values and best practices have been selected for this collection.
# Detailed information can be found in the source link provided for each tweak.

Assert-AdminOrElevate
Initialize-Logging -ModuleName "tweaks"

# Load sub-modules
. "$PSScriptRoot\Tweaks.Universal.ps1"
. "$PSScriptRoot\Tweaks.Power.ps1"
. "$PSScriptRoot\Tweaks.GPU.ps1"
. "$PSScriptRoot\Tweaks.Cleanup.ps1"
. "$PSScriptRoot\Tweaks.Drift.ps1"
function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Winrift - System Tweaks"
    Invoke-MenuLoop -Title "System Tweaks" -Items @(
        "[1] Universal Tweaks",
        "[2] Power Management",
        "[3] NVIDIA/AMD GPU Tweaks",
        "[4] Free Up Space",
        "[5] Restore Previous Tweaks",
        "[6] Drift Detection",
        "---",
        "[7] Back to menu"
    ) -Prompt "Enter your choice (1-7)" -Actions @{
        "1" = { Invoke-UniversalTweaks }
        "2" = { Invoke-PowerMenu }
        "3" = { Show-GPUMenu }
        "4" = { Clear-SystemSpace }
        "5" = { Restore-TweakBackup }
        "6" = { Show-DriftMenu }
    } -ExitKey "7"
}

Show-MainMenu

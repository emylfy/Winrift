. "$PSScriptRoot\..\..\scripts\Common.ps1"
# https://github.com/AlchemyTweaks/Verified-Tweaks
# https://github.com/SanGraphic/QuickBoost
# Detailed information can be found in the source link provided for each tweak.

Initialize-Logging -ModuleName "tweaks"

# Load sub-modules
. "$PSScriptRoot\Tweaks.Universal.ps1"
. "$PSScriptRoot\Tweaks.Power.ps1"
. "$PSScriptRoot\Tweaks.GPU.ps1"
. "$PSScriptRoot\Tweaks.Cleanup.ps1"

function Show-TweaksMenu {
    Invoke-MenuLoop -Title 'Performance Tweaks' -Items @(
        '1 › Review Recommended Preset        ›',
        '2 › All Tweaks                       ›',
        '3 › GPU Tweaks                       ›',
        '4 › Power Settings                   ›',
        '---', '0 › Back'
    ) -Actions @{
        '1' = { Invoke-RecommendedTweaks }
        '2' = { Invoke-UniversalTweaks }
        '3' = { Show-GPUMenu }
        '4' = { Invoke-PowerMenu }
    } -ExitKey '0' -HideKeys
}

if ($MyInvocation.InvocationName -ne '.') { Show-TweaksMenu }
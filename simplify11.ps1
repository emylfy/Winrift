. "$PSScriptRoot\scripts\Common.ps1"

$script:AppVersion = Get-AppVersion -RootPath $PSScriptRoot

function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Simplify11 v$script:AppVersion"
    Clear-Host
    Write-Host
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Purple   Tired of System Setup After Reinstall? Simplify It!  $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Configure Your Windows Installation Answer File    $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] System Tweaks - SSD, GPU, CPU, Storage and etc     $Purple'$Reset"
    Write-Host "$Purple '$Reset [3] Security Menu - Defender, AI Removal, Privacy      $Purple'$Reset"
    Write-Host "$Purple '$Reset [4] Install Drivers - Nvidia, AMD, Device Manufacturer $Purple'$Reset"
    Write-Host "$Purple '$Reset [5] Windots - Simpler way to rice & customize Windows  $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [6] WinUtil - Install Programs, Tweaks, Fixes, Updates $Purple'$Reset"
    Write-Host "$Purple '$Reset [7] WinScript - Build your script from scratch         $Purple'$Reset"
    Write-Host "$Purple '$Reset [8] UniGetUI - Discover, Install, Update Packages      $Purple'$Reset"
    Write-Host "$Purple '$Reset [9] Sparkle - Windows Package Manager                  $Purple'$Reset"
    Write-Host "$Purple '$Reset [10] GTweak - Tweaking tool and debloater              $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"

    $choice = Read-Host ">"

    . "$PSScriptRoot\scripts\AdminLaunch.ps1"

    $scriptPaths = @{
        "2"  = "$PSScriptRoot\modules\system\Tweaks.ps1"
        "3"  = "$PSScriptRoot\modules\security\SecurityMenu.ps1"
        "4"  = "$PSScriptRoot\modules\drivers\Drivers.ps1"
        "5"  = "$PSScriptRoot\modules\windots\windots.ps1"
        "7"  = "$PSScriptRoot\modules\tools\WinScript.ps1"
        "8"  = "$PSScriptRoot\modules\unigetui\UniGetUI.ps1"
    }

    # External tools handled by config-driven launcher
    $externalTools = @{
        "6"  = "winutil"
        "9"  = "sparkle"
        "10" = "gtweak"
    }

    switch ($choice) {
        "1" {
            Start-Process "https://github.com/emylfy/simplify11/blob/main/docs/autounattend_guide.md"
            Show-MainMenu
        }
        { $scriptPaths.ContainsKey($_) } {
            $targetScript = $scriptPaths[$choice]
            if (-not (Test-Path $targetScript)) {
                Write-Host "$Red Module not found: $targetScript$Reset"
                Write-Host "$Yellow This module may not be included in your installation.$Reset"
                Read-Host "Press Enter to continue"
                Show-MainMenu
                return
            }
            Start-AdminProcess -ScriptPath $targetScript -NoExit
            Show-MainMenu
        }
        { $externalTools.ContainsKey($_) } {
            $launcherPath = "$PSScriptRoot\modules\tools\ExternalLauncher.ps1"
            Start-AdminProcess -ScriptPath $launcherPath -Arguments "-ToolId $($externalTools[$choice])" -NoExit
            Show-MainMenu
        }
        default { Show-MainMenu }
    }
}

Show-MainMenu

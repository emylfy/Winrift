. "$PSScriptRoot\scripts\Common.ps1"

# Load version from version.json
$versionFile = Join-Path $PSScriptRoot "version.json"
if (Test-Path $versionFile) {
    $versionInfo = Get-Content $versionFile -Raw | ConvertFrom-Json
    $script:AppVersion = $versionInfo.version
} else {
    $script:AppVersion = "unknown"
}

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

    switch ($choice) {
        "1" { Start-Process "https://github.com/emylfy/simplify11/blob/main/docs/autounattend_guide.md"; Show-MainMenu }
        {"2","3","4","5","6","7","8","9","10" -contains $choice} {
            . "$PSScriptRoot\scripts\AdminLaunch.ps1"

            $scriptPaths = @{
                "2"  = "$PSScriptRoot\modules\system\Tweaks.ps1"
                "3"  = "$PSScriptRoot\modules\security\SecurityMenu.ps1"
                "4"  = "$PSScriptRoot\modules\drivers\Drivers.ps1"
                "5"  = "$PSScriptRoot\modules\windots\windots.ps1"
                "6"  = "$PSScriptRoot\modules\tools\WinUtil.ps1"
                "7"  = "$PSScriptRoot\modules\tools\WinScript.ps1"
                "8"  = "$PSScriptRoot\modules\unigetui\UniGetUI.ps1"
                "9"  = "$PSScriptRoot\modules\tools\Sparkle.ps1"
                "10" = "$PSScriptRoot\modules\tools\GTweak.ps1"
            }

            $docsUrls = @{
                # External integrations
                "6"  = "https://github.com/ChrisTitusTech/winutil"        # WinUtil
                "7"  = "https://github.com/flick9000/winscript"           # WinScript
                "8"  = "https://github.com/marticliment/UniGetUI"         # UniGetUI
                "10" = "https://github.com/Greedeks/GTweak"               # GTweak
                "9"  = "https://github.com/Parcoil/Sparkle"               # Sparkle
                # Internal modules / features
                "2"  = "https://github.com/emylfy/simplify11"             # System Tweaks (internal)
                "3"  = "https://github.com/emylfy/simplify11"             # Security Menu (internal)
                "4"  = "https://github.com/emylfy/simplify11"             # Drivers (internal)
                "5"  = "https://github.com/emylfy/windots"                # Windots
            }

            $autoStartChoices = @("4","5","7","8")
            if ($autoStartChoices -contains $choice) {
                Start-AdminProcess -ScriptPath $scriptPaths[$choice] -NoExit
                Show-MainMenu
                break
            }

            $toolNames = @{
                "2"  = "System Tweaks"
                "3"  = "Security Menu"
                "4"  = "Drivers"
                "5"  = "Windots"
                "6"  = "WinUtil"
                "7"  = "WinScript"
                "8"  = "UniGetUI"
                "9"  = "Sparkle"
                "10" = "GTweak"
            }

            $innerWidth = 44

            while ($true) {
                Write-Host
                Write-Host "$Purple +----------------------------------------------+$Reset"
                $toolName = $toolNames[$choice]
                if (-not $toolName) { $toolName = "selected tool" }
                $contentRun = "[1] Run $toolName"
                Write-Host "$Purple '$Reset $($contentRun.PadRight($innerWidth)) $Purple'$Reset"
                Write-Host "$Purple '$Reset [2] Open documentation / project source      $Purple'$Reset"
                Write-Host "$Purple '$Reset [3] Back to main menu                        $Purple'$Reset"
                Write-Host "$Purple +----------------------------------------------+$Reset"

                $toolAction = Read-Host "Select action"

                switch ($toolAction) {
                    "1" {
                        Start-AdminProcess -ScriptPath $scriptPaths[$choice] -NoExit
                        Show-MainMenu
                        break
                    }
                    "2" {
                        if ($docsUrls.ContainsKey($choice)) {
                            Clear-Host
                            Start-Process $docsUrls[$choice]
                            Show-MainMenu
                            break
                        } else {
                            Clear-Host
                            Write-Host "$Yellow No documentation URL defined for this tool.$Reset"
                            Show-MainMenu
                            break
                        }
                    }
                    "3" {
                        Show-MainMenu
                        break
                    }
                    default {
                    }
                }
            }
        }
        default { Show-MainMenu }
    }
}

Show-MainMenu

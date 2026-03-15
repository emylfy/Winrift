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

    . "$PSScriptRoot\scripts\AdminLaunch.ps1"

    $scriptPaths = @{
        "2"  = "$PSScriptRoot\modules\system\Tweaks.ps1"
        "3"  = "$PSScriptRoot\modules\security\SecurityMenu.ps1"
        "4"  = "$PSScriptRoot\modules\drivers\Drivers.ps1"
        "5"  = "$PSScriptRoot\modules\windots\windots.ps1"
        "7"  = "$PSScriptRoot\modules\tools\WinScript.ps1"
        "8"  = "$PSScriptRoot\modules\unigetui\UniGetUI.ps1"
    }

    $externalTools = @{
        "6"  = "winutil"
        "9"  = "sparkle"
        "10" = "gtweak"
    }

    $docsUrls = @{
        "2"  = "https://github.com/emylfy/simplify11"
        "3"  = "https://github.com/emylfy/simplify11"
        "4"  = "https://github.com/emylfy/simplify11"
        "5"  = "https://github.com/emylfy/windots"
        "6"  = "https://github.com/ChrisTitusTech/winutil"
        "7"  = "https://github.com/flick9000/winscript"
        "8"  = "https://github.com/marticliment/UniGetUI"
        "9"  = "https://github.com/Parcoil/Sparkle"
        "10" = "https://github.com/Greedeks/GTweak"
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

    # Auto-start choices: launch directly without sub-menu (have their own interactive menus)
    $autoStartChoices = @("4", "5", "8")

    :outerLoop while ($true) {
        Clear-Host
        Write-Host
        Write-Host "$Purple +--------------------------------------------------------+$Reset"
        Write-Host "$Purple '$Purple   Tired of System Setup After Reinstall? Simplify It!  $Purple'$Reset"
        Write-Host "$Purple +--------------------------------------------------------+$Reset"
        Write-Host "$Purple '$Reset [1]  Configure Your Windows Installation Answer File   $Purple'$Reset"
        Write-Host "$Purple '$Reset [2]  System Tweaks - SSD, GPU, CPU, Storage and etc    $Purple'$Reset"
        Write-Host "$Purple '$Reset [3]  Security Menu - Defender, AI Removal, Privacy     $Purple'$Reset"
        Write-Host "$Purple '$Reset [4]  Install Drivers - Nvidia, AMD, Device Manufacturer$Purple'$Reset"
        Write-Host "$Purple '$Reset [5]  Windots - Simpler way to rice & customize Windows $Purple'$Reset"
        Write-Host "$Purple +--------------------------------------------------------+$Reset"
        Write-Host "$Purple '$Reset [6]  WinUtil - Install Programs, Tweaks, Fixes, Updates$Purple'$Reset"
        Write-Host "$Purple '$Reset [7]  WinScript - Build your script from scratch        $Purple'$Reset"
        Write-Host "$Purple '$Reset [8]  UniGetUI - Discover, Install, Update Packages     $Purple'$Reset"
        Write-Host "$Purple '$Reset [9]  Sparkle - Windows Package Manager                 $Purple'$Reset"
        Write-Host "$Purple '$Reset [10] GTweak - Tweaking tool and debloater              $Purple'$Reset"
        Write-Host "$Purple +--------------------------------------------------------+$Reset"

        $choice = Read-Host ">"

        if ($choice -eq "1") {
            Start-Process "https://github.com/emylfy/simplify11/blob/main/docs/autounattend_guide.md"
            continue outerLoop
        }

        $isExternal = $externalTools.ContainsKey($choice)
        if (-not ($scriptPaths.ContainsKey($choice) -or $isExternal)) {
            continue outerLoop
        }

        $targetScript = if (-not $isExternal) { $scriptPaths[$choice] } else { $null }

        if (-not $isExternal) {
            if (-not (Test-Path $targetScript)) {
                Write-Log -Message "Module not found: $targetScript" -Level ERROR
                Write-Host "$Yellow This module may not be included in your installation.$Reset"
                Read-Host "Press Enter to continue"
                continue outerLoop
            }
            if ($autoStartChoices -contains $choice) {
                Start-AdminProcess -ScriptPath $targetScript -NoExit
                continue outerLoop
            }
        }

        # Show tool sub-menu for tools with Run/Docs/Back options
        $toolName = $toolNames[$choice]
        if (-not $toolName) { $toolName = "selected tool" }

        :toolLoop while ($true) {
            Clear-Host
            Show-MenuBox -Title $toolName -Items @(
                "[1] Run $toolName",
                "[2] Open documentation / project source",
                "---",
                "[3] Back to main menu"
            )

            $toolAction = Read-Host "Select action"

            switch ($toolAction) {
                "1" {
                    if ($isExternal) {
                        $launcherPath = "$PSScriptRoot\modules\tools\ExternalLauncher.ps1"
                        Start-AdminProcess -ScriptPath $launcherPath -Arguments "-ToolId $($externalTools[$choice])" -NoExit
                    } else {
                        Start-AdminProcess -ScriptPath $scriptPaths[$choice] -NoExit
                    }
                    break toolLoop
                }
                "2" {
                    if ($docsUrls.ContainsKey($choice)) {
                        Start-Process $docsUrls[$choice]
                    } else {
                        Write-Host "$Yellow No documentation URL defined for this tool.$Reset"
                        Start-Sleep -Seconds 1
                    }
                    break toolLoop
                }
                "3" { break toolLoop }
                default { }
            }
        }
    }
}

Show-MainMenu

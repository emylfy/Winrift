. "$PSScriptRoot\scripts\Common.ps1"
$PSScriptRoot | Set-Content "$env:TEMP\simplify11_launchdir.txt" -Force

# Load version from version.json
$versionFile = Join-Path $PSScriptRoot "config\version.json"
if (Test-Path $versionFile) {
    $versionInfo = Get-Content $versionFile -Raw | ConvertFrom-Json
    $script:AppVersion = $versionInfo.version
} else {
    $script:AppVersion = "unknown"
}

function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Winrift v$script:AppVersion"

    . "$PSScriptRoot\scripts\AdminLaunch.ps1"

    $scriptPaths = @{
        "1" = "$PSScriptRoot\modules\system\Benchmark.ps1"
        "2" = "$PSScriptRoot\modules\system\Tweaks.ps1"
        "3" = "$PSScriptRoot\modules\security\SecurityMenu.ps1"
        "4" = "$PSScriptRoot\modules\drivers\Drivers.ps1"
        "5" = "$PSScriptRoot\modules\windots\Windots.ps1"
        "6" = "$PSScriptRoot\modules\unigetui\UniGetUI.ps1"
    }

    $communityTools = @{
        "1" = "winutil"
        "2" = "sparkle"
        "3" = "gtweak"
    }

    $communityScripts = @{
        "4" = "$PSScriptRoot\modules\tools\WinScript.ps1"
    }

    $docsUrls = @{
        "1" = "https://github.com/emylfy/simplify11/blob/main/docs/tweaks_guide.md"
        "2" = "https://github.com/emylfy/simplify11/blob/main/docs/autounattend_guide.md"
        "3" = "https://github.com/emylfy/simplify11/blob/main/docs/tests.md"
    }

    :outerLoop while ($true) {
        Clear-Host
        Write-Host
        Show-MenuBox -Title "Winrift - Break through default Windows" -Items @(
            "[1]  Benchmark - Measure system performance",
            "[2]  System Tweaks - Optimization & power management",
            "[3]  Security & Privacy - Defender, Copilot, privacy",
            "[4]  Drivers - NVIDIA, AMD, Intel, OEM",
            "[5]  Desktop Ricing - Terminal, VSCode, themes, apps",
            "[6]  App Bundles - Install app collections",
            "---",
            "[7]  Community Tools",
            "[D]  Docs & Guides"
        )

        $choice = Read-Host ">"

        # Direct launch items
        if ($scriptPaths.ContainsKey($choice)) {
            $targetScript = $scriptPaths[$choice]
            if (-not (Test-Path $targetScript)) {
                Write-Log -Message "Module not found: $targetScript" -Level ERROR
                Write-Host "$Yellow This module may not be included in your installation.$Reset"
                Read-Host "Press Enter to continue"
                continue outerLoop
            }
            Start-AdminProcess -ScriptPath $targetScript -NoExit
            continue outerLoop
        }

        # Community Tools submenu
        if ($choice -eq "7") {
            :communityLoop while ($true) {
                Clear-Host
                Show-MenuBox -Title "Community Tools" -Items @(
                    "[1]  WinUtil - Tweaks, Apps & Fixes",
                    "[2]  Sparkle - Optimize & Debloat",
                    "[3]  GTweak - Debloat & Tweak",
                    "[4]  WinScript - Custom Script Builder",
                    "--- Third-party tools fetched from the web ---",
                    "[5]  Back to main menu"
                )

                $communityChoice = Read-Host ">"

                if ($communityChoice -eq "5" -or $communityChoice -eq "") {
                    break communityLoop
                }

                if ($communityTools.ContainsKey($communityChoice)) {
                    $launcherPath = "$PSScriptRoot\modules\tools\ExternalLauncher.ps1"
                    Start-AdminProcess -ScriptPath $launcherPath -Arguments "-ToolId $($communityTools[$communityChoice])" -NoExit
                    break communityLoop
                }

                if ($communityScripts.ContainsKey($communityChoice)) {
                    Start-AdminProcess -ScriptPath $communityScripts[$communityChoice] -NoExit
                    break communityLoop
                }
            }
            continue outerLoop
        }

        # Docs & Guides submenu
        if ($choice -eq "D" -or $choice -eq "d") {
            :docsLoop while ($true) {
                Clear-Host
                Show-MenuBox -Title "Docs & Guides" -Items @(
                    "[1]  Tweaks Guide - What each tweak does",
                    "[2]  Answer File Guide - Windows installation",
                    "[3]  Benchmark Guide - Methodology & results",
                    "---",
                    "[4]  Back to main menu"
                )

                $docsChoice = Read-Host ">"

                if ($docsChoice -eq "4" -or $docsChoice -eq "") {
                    break docsLoop
                }

                if ($docsUrls.ContainsKey($docsChoice)) {
                    Start-Process $docsUrls[$docsChoice]
                    break docsLoop
                }
            }
            continue outerLoop
        }
    }
}

Show-MainMenu

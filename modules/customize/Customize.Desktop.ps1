function Install-GlazeWM {
    $choice = Show-InteractiveMenu -Title "GlazeWM - Tiling Window Manager" -Items @(
        "i3-inspired tiling window manager for Windows.",
        "Manages window layout with keyboard shortcuts.",
        "---",
        "1 › Install GlazeWM + apply config",
        "2 › Install GlazeWM only",
        "3 › Apply config only (already installed)",
        "4 › Cancel"
    )

    switch ($choice) {
        "1" {
            $installed = Install-WingetPackage "glzr-io.glazewm" "GlazeWM"
            if ($installed) { Copy-GlazeWMConfig }
        }
        "2" {
            $null = Install-WingetPackage "glzr-io.glazewm" "GlazeWM"
        }
        "3" {
            Copy-GlazeWMConfig
        }
        default { return }
    }
    Wait-ForUser
}

function Copy-GlazeWMConfig {
    $source=Join-Path $PSScriptRoot 'config\glazewm'
    $target=Join-Path $env:USERPROFILE '.glzr\glazewm'
    $files=@(Get-ChildItem -LiteralPath $source -File -Recurse | ForEach-Object { [IO.Path]::GetRelativePath($source,$_.FullName) })
    Copy-ConfigFiles -SourceDir $source -FileNames $files -TargetDir $target -ConfigName GlazeWM
}
function Install-StatusBar {
    $choice = Show-InteractiveMenu -Title "Status Bar" -Items @(
        "Add a customizable status bar to your desktop.",
        "---",
        "1 › Zebar (Rust-based, pairs with GlazeWM)",
        "2 › YASB (Python/Qt6, Polybar for Windows)",
        "3 › Cancel"
    )

    switch ($choice) {
        "1" {
            $null = Install-WingetPackage "glzr-io.zebar" "Zebar"
        }
        "2" {
            $null = Install-WingetPackage "AmN.yasb" "YASB"
        }
        default { return }
    }
    Wait-ForUser
}

function Install-FlowLauncher {
    Clear-Host
    Write-Log -Message "Flow Launcher - productivity app launcher (Alfred/Raycast for Windows)" -Level INFO
    $null = Install-WingetPackage "Flow-Launcher.Flow-Launcher" "Flow Launcher"
    Wait-ForUser
}

function Install-Windhawk {
    Clear-Host
    Write-Log -Message "Windhawk - marketplace for reversible Windows UI mods" -Level INFO
    $null = Install-WingetPackage "RamenSoftware.Windhawk" "Windhawk"
    Wait-ForUser
}

function Install-Rainmeter {
    Clear-Host
    Write-Log -Message "Rainmeter - desktop customization with widgets and skins" -Level INFO
    $null = Install-WingetPackage "Rainmeter.Rainmeter" "Rainmeter"
    Wait-ForUser
}

function Open-WallpaperBrowser {
    $choice = Show-InteractiveMenu -Title "Wallpaper" -Items @(
        "1 › Open Catppuccin wallpapers (GitHub)",
        "2 › Open Gruvbox wallpapers (GitHub)",
        "3 › Open wallhaven.cc (browse wallpapers)",
        "4 › Cancel"
    )

    switch ($choice) {
        "1" { Start-Process "https://github.com/catppuccin/wallpapers" }
        "2" { Start-Process "https://github.com/AngelJumworWorlds/gruvbox-wallpapers" }
        "3" { Start-Process "https://wallhaven.cc/search?categories=100&purity=100&sorting=toplist&order=desc" }
        default { return }
    }
    Wait-ForUser
}


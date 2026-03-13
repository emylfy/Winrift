. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Simplify11 - UniGetUI"
    Show-Menu -Title "UniGetUI (formerly WingetUI)" -Options @(
        @{ Key = "1"; Label = "Install and Launch"; Action = { Install-UniGetUI } },
        @{ Key = "2"; Label = "Open List of Apps by Category"; Action = { Show-AppCategoryMenu } },
        @{ Key = "3"; Label = "Try Fixing Winget if something wrong"; Action = { Test-Winget } }
    ) -BackLabel "Back to Simplify11" -BackAction { & "$PSScriptRoot\..\..\simplify11.ps1" }
}

function Install-UniGetUI {
    Clear-Host
    Write-Header -Text "Install UniGetUI"

    & winget source update

    $isInstalled = & winget list --id MartiCliment.UniGetUI --accept-source-agreements | Select-String "MartiCliment.UniGetUI"

    if ($isInstalled) {
        Write-Host "$Reset UniGetUI is already installed. Launching...$Reset"
        Start-Process "unigetui:"
    } else {
        Write-Host "$Reset Installing UniGetUI...$Reset"
        $result = & winget install MartiCliment.UniGetUI --accept-package-agreements --accept-source-agreements

        if ($LASTEXITCODE -eq 0) {
            Write-Host "$Green Successfully installed UniGetUI.$Reset"
            Start-Process "unigetui:"
        } else {
            Write-Host "$Red Failed to install UniGetUI. Opening website for manual download...$Reset"
            Start-Process "https://www.marticliment.com/unigetui/"
            Test-Winget
        }
    }

    Read-Host "Press Enter to continue"
}

function Test-Winget {
    $wingetExists = Get-Command winget -ErrorAction SilentlyContinue

    if (-not $wingetExists) {
        Write-Host "$Red Winget is not installed. Please install Windows App Installer from Microsoft Store.$Reset"
        Start-Process "ms-windows-store://pdp/?ProductId=9nblggh4nns1"
    } else {
        Write-Host "$Green Winget is installed and available.$Reset"
    }

    Read-Host "Press Enter to continue"
}

function Show-AppCategoryMenu {
    $bundleDir = Join-Path $PSScriptRoot "..\..\config\bundles"

    Show-Menu -Title "App Categories" -Options @(
        @{ Key = "1"; Label = "Development"; Action = { Open-Bundle $bundleDir "Development" } },
        @{ Key = "2"; Label = "Web Browsers"; Action = { Open-Bundle $bundleDir "Browsers" } },
        @{ Key = "3"; Label = "Utilities, Microsoft tools"; Action = { Open-Bundle $bundleDir "Utilities" } },
        @{ Key = "4"; Label = "Productivity Suite"; Action = { Open-Bundle $bundleDir "Productivity" } },
        @{ Key = "5"; Label = "Gaming Essentials"; Action = { Open-Bundle $bundleDir "Games" } },
        @{ Key = "6"; Label = "Communications"; Action = { Open-Bundle $bundleDir "Communications" } }
    ) -BackLabel "Back to UniGetUI"
}

function Open-Bundle {
    param(
        [string]$BundleDir,
        [string]$BundleName
    )

    $bundlePath = Join-Path $BundleDir "$BundleName.ubundle"
    Write-Host "Opening bundle: $bundlePath"

    try {
        Start-Process "$env:LOCALAPPDATA\Programs\UniGetUI\UniGetUI.exe" -ArgumentList "/launch", "`"$bundlePath`"" -ErrorAction Stop
    }
    catch {
        try {
            Start-Process $bundlePath -ErrorAction Stop
        }
        catch {
            Write-Host "$Yellow Make sure that UniGetUI is installed.$Reset"
            Read-Host "Press Enter to continue"
            return
        }
    }

    Read-Host "Press Enter to continue"
}

Show-MainMenu

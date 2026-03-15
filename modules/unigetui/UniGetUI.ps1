. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Simplify11 - UniGetUI"

    while ($true) {
        Clear-Host
        Show-MenuBox -Title "UniGetUI (formerly WingetUI)" -Items @(
            "[1] Install and Launch",
            "[2] Open List of Apps by Category",
            "[3] Try Fixing Winget if something wrong"
        )

        $choice = Read-Host "Select an option"

        switch ($choice) {
            "1" { Install-UniGetUI; break }
            "2" { Show-AppCategoryMenu; break }
            "3" { Test-Winget; break }
            default { }
        }
    }
}

function Install-UniGetUI {
    Clear-Host
    Write-Log -Message "Checking UniGetUI installation..." -Level INFO

    & winget source update

    $isInstalled = & winget list --id MartiCliment.UniGetUI --accept-source-agreements | Select-String "MartiCliment.UniGetUI"

    if ($isInstalled) {
        Write-Log -Message "UniGetUI is already installed. Launching..." -Level SUCCESS
        Start-Process "unigetui:"
    } else {
        Write-Log -Message "Installing UniGetUI..." -Level INFO
        & winget install MartiCliment.UniGetUI --accept-package-agreements --accept-source-agreements

        if ($LASTEXITCODE -eq 0) {
            Write-Log -Message "Successfully installed UniGetUI." -Level SUCCESS
            Start-Process "unigetui:"
        } else {
            Write-Log -Message "Failed to install UniGetUI. Opening website for manual download..." -Level ERROR
            Start-Process "https://www.marticliment.com/unigetui/"
            Test-Winget
        }
    }
}

function Test-Winget {
    $wingetExists = Get-Command winget -ErrorAction SilentlyContinue

    if (-not $wingetExists) {
        Write-Log -Message "Winget is not installed. Please install Windows App Installer from Microsoft Store." -Level ERROR
        Start-Process "ms-windows-store://pdp/?ProductId=9nblggh4nns1"
        Read-Host "Press Enter to continue"
    } else {
        Write-Log -Message "Winget is installed and available." -Level SUCCESS
        Read-Host "Press Enter to continue"
    }
}

function Show-AppCategoryMenu {
    while ($true) {
        Clear-Host
        Show-MenuBox -Title "App Categories" -Items @(
            "[1] Development",
            "[2] Web Browsers",
            "[3] Utilities, Microsoft tools",
            "[4] Productivity Suite",
            "[5] Gaming Essentials",
            "[6] Communications",
            "---",
            "[7] Back to Menu"
        )

        $choice = Read-Host "Select a category"

        $bundleName = switch ($choice) {
            "1" { "development" }
            "2" { "browsers" }
            "3" { "utilities" }
            "4" { "productivity" }
            "5" { "games" }
            "6" { "communications" }
            "7" { return }
            default { continue }
        }

        $scriptPath = if ($PSScriptRoot) {
            $PSScriptRoot
        } elseif ($MyInvocation.MyCommand.Path) {
            Split-Path -Parent $MyInvocation.MyCommand.Path
        } else {
            $PWD.Path
        }

        $bundlePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "unigetui\ubundle\$bundleName.ubundle"

        Write-Log -Message "Opening bundle: $bundlePath" -Level INFO

        try {
            Start-Process "$env:LOCALAPPDATA\Programs\UniGetUI\UniGetUI.exe" -ArgumentList "/launch", "`"$bundlePath`"" -ErrorAction Stop
            Read-Host "Press Enter to continue"
        } catch {
            try {
                Start-Process $bundlePath -ErrorAction Stop
            } catch {
                Write-Log -Message "Make sure that UniGetUI is installed." -Level WARNING
                Install-UniGetUI
            }
        }
    }
}

Show-MainMenu

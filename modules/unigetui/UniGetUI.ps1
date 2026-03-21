. "$PSScriptRoot\..\..\scripts\Common.ps1"

Initialize-Logging -ModuleName "unigetui"

function Show-InstallPrompt {
    Clear-Host
    Show-MenuBox -Title "UniGetUI" -Items @(
        "A package manager UI for Windows that lets you",
        "discover, install, and update apps using winget,",
        "Chocolatey, and other sources.",
        "---",
        "[1] Install UniGetUI",
        "[2] Back to menu"
    )

    $choice = Read-Host "Select an option"

    switch ($choice) {
        "1" { Install-UniGetUI }
        "2" { Invoke-ReturnToMenu; return }
        default { Invoke-ReturnToMenu; return }
    }
}

function Install-UniGetUI {
    Clear-Host
    Write-Log -Message "Checking UniGetUI installation..." -Level INFO

    try {
        & winget source update 2>$null
    } catch {
        Write-Log -Message "Failed to update winget sources: $($_.Exception.Message)" -Level WARNING
    }

    $isInstalled = & winget list --id MartiCliment.UniGetUI --accept-source-agreements 2>$null | Select-String "MartiCliment.UniGetUI"

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
        }
    }
}

function Show-AppCategoryMenu {
    while ($true) {
        Clear-Host
        Show-MenuBox -Title "App Categories" -Items @(
            "[1] Development",
            "[2] Web Browsers",
            "[3] Utilities",
            "[4] Productivity",
            "[5] Creative & Media",
            "[6] Gaming",
            "[7] Communications",
            "---",
            "[8] Back to menu"
        )

        $choice = Read-Host "Select a category"

        $bundleName = switch ($choice) {
            "1" { "Development" }
            "2" { "Browsers" }
            "3" { "Utilities" }
            "4" { "Productivity" }
            "5" { "CreativeMedia" }
            "6" { "Games" }
            "7" { "Communications" }
            "8" { return }
            default { continue }
        }

        if ($PSScriptRoot) {
            $scriptPath = $PSScriptRoot
        } elseif ($MyInvocation.MyCommand.Path) {
            $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        } else {
            $scriptPath = $PWD.Path
        }

        $projectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
        $bundlePath = Join-Path -Path $projectRoot -ChildPath "config\bundles\$bundleName.ubundle"

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

$Host.UI.RawUI.WindowTitle = "Winrift - App Bundles"

if (-not (Assert-WingetAvailable)) {
    Invoke-ReturnToMenu
    return
}

$isInstalled = & winget list --id MartiCliment.UniGetUI --accept-source-agreements 2>$null |
    Select-String "MartiCliment.UniGetUI"

if (-not $isInstalled) {
    Show-InstallPrompt
}

Show-AppCategoryMenu
Invoke-ReturnToMenu

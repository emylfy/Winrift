$Purple = "$([char]0x1b)[38;5;141m"
$Grey = "$([char]0x1b)[38;5;250m"
$Reset = "$([char]0x1b)[0m"
$Red = "$([char]0x1b)[38;5;203m"
$Green = "$([char]0x1b)[38;5;120m"

function Show-MainMenu {
    Clear-Host
    Write-Host "$Purple +------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey UniGetUI (formerly WingetUI)             $Purple'$Reset"
    Write-Host "$Purple +------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [1] Install and Launch                   $Purple'$Reset"
    Write-Host "$Purple '$Grey [2] Open List of Apps by Category        $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] Try Fixing Winget if something wrong $Purple'$Reset"
    Write-Host "$Purple +------------------------------------------+$Reset"
    
    $choice = Read-Host "Select an option"
    
    switch ($choice) {
        "1" { Install-UniGetUI }
        "2" { Show-AppCategoryMenu }
        "3" { Check-Winget }
        default { Show-MainMenu }
    }
}

function Install-UniGetUI {
    Clear-Host
    Write-Host "$Purple +---                    ---+$Reset"
    Write-Host "$Purple  '$Grey    Install UniGetUI    $Purple'$Reset"
    Write-Host "$Purple +---                    ---+$Reset"

    & winget source update
    
    $isInstalled = & winget list --id MartiCliment.UniGetUI --accept-source-agreements | Select-String "MartiCliment.UniGetUI"
    
    if ($isInstalled) {
        Write-Host "$Grey UniGetUI is already installed. Launching...$Reset"
        Start-Process "unigetui:"
    } else {
        Write-Host "$Grey Installing UniGetUI...$Reset"
        $result = & winget install MartiCliment.UniGetUI --accept-package-agreements --accept-source-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$Green Successfully installed UniGetUI.$Reset"
            Start-Process "unigetui:"
        } else {
            Write-Host "$Red Failed to install UniGetUI. Opening website for manual download...$Reset"
            Start-Process "https://www.marticliment.com/unigetui/"
            Check-Winget
        }
    }
    
    Show-MainMenu
}

function Check-Winget {
    $wingetExists = Get-Command winget -ErrorAction SilentlyContinue
    
    if (-not $wingetExists) {
        Write-Host "$Red Winget is not installed. Please install Windows App Installer from Microsoft Store.$Reset"
        Start-Process "ms-windows-store://pdp/?ProductId=9nblggh4nns1"
        Read-Host "Press Enter to continue"
    }
    
    Show-MainMenu
}

function Show-AppCategoryMenu {
    Clear-Host
    Write-Host "$Purple +--------------------------------+$Reset"
    Write-Host "$Purple '$Grey App Categories                 $Purple'$Reset"
    Write-Host "$Purple +--------------------------------+$Reset"
    Write-Host "$Purple '$Grey [1] Development                $Purple'$Reset"
    Write-Host "$Purple '$Grey [2] Web Browsers               $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] Utilities, Microsoft tools $Purple'$Reset"
    Write-Host "$Purple '$Grey [4] Productivity Suite         $Purple'$Reset"
    Write-Host "$Purple '$Grey [5] Gaming Essentials          $Purple'$Reset"
    Write-Host "$Purple '$Grey [6] Communications             $Purple'$Reset"
    Write-Host "$Purple +--------------------------------+$Reset"
    
    $choice = Read-Host "Select a category"
    
    $bundleName = switch ($choice) {
        "1" { "development" }
        "2" { "browsers" }
        "3" { "utilities" }
        "4" { "productivity" }
        "5" { "games" }
        "6" { "communications" }
        default { Show-AppCategoryMenu; return }
    }
    
    # Fix for getting the script path reliably
    $scriptPath = if ($PSScriptRoot) {
        $PSScriptRoot
    } elseif ($MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $PWD.Path
    }
    
    $bundlePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ubundle\$bundleName.ubundle"
    
    Write-Host "Opening bundle: $bundlePath"
    
    try {
        Start-Process "$env:LOCALAPPDATA\Programs\UniGetUI\UniGetUI.exe" -ArgumentList "/launch", "`"$bundlePath`"" -ErrorAction Stop
        Read-Host "Press Enter to continue"
    }
    catch {
        try {
            Start-Process $bundlePath -ErrorAction Stop
        }
        catch {
            Write-Host "Make sure that you installed UniGetUI."
            Install-UniGetUI
            return
        }
    }
    
    Show-AppCategoryMenu
}

Show-MainMenu
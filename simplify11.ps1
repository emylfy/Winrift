# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Not running as admin. Elevating..."
    
    # Check if Windows Terminal is available
    $wtExists = Get-Command wt.exe -ErrorAction SilentlyContinue
    
    if ($wtExists) {
        Start-Process -FilePath 'wt.exe' -ArgumentList "powershell -NoExit -File `"$PSCommandPath`"" -Verb RunAs
    } else {
        Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoExit -File `"$PSCommandPath`"" -Verb RunAs
    }
    exit
}

# Define colors
$Purple = "$([char]0x1b)[38;5;141m"
$Grey = "$([char]0x1b)[38;5;250m"
$Reset = "$([char]0x1b)[0m"
$Red = "$([char]0x1b)[38;5;203m"
$Green = "$([char]0x1b)[38;5;120m"

function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Simplify11 v25.02"
    Clear-Host
    
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Purple   Tired of System Setup After Reinstall? Simplify It!  $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [0] Configure Your Windows Installation Answer File    $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [1] WinUtil - Install Programs, Tweaks, Fixes, Updates $Purple'$Reset"
    Write-Host "$Purple '$Grey [2] WinScript - Build your script from scratch         $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] Privacy.sexy - Enforce privacy and security        $Purple'$Reset"
    Write-Host "$Purple '$Grey [4] UniGetUI - Discover, Install, Update Packages      $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [5] System Tweaks - SSD, GPU, CPU, Storage and etc     $Purple'$Reset"
    Write-Host "$Purple '$Grey [6] Install Drivers - Nvidia, AMD, Device Manufacturer $Purple'$Reset"
    Write-Host "$Purple '$Grey [7] Customization stuff, Windots                       $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "0" { Start-Process "https://github.com/emylfy/simplify11/blob/main/src/docs/autounattend_guide.md"; Show-MainMenu }
        "1" { Start-Process powershell -ArgumentList "-NoExit -File `"$PSScriptRoot\modules\launch\WinUtil.ps1`""; Show-MainMenu }
        "2" { Start-Process powershell -ArgumentList "-NoExit -File `"$PSScriptRoot\modules\launch\WinScript.ps1`""; Show-MainMenu }
        "3" { Start-Process powershell -ArgumentList "-NoExit -File `"$PSScriptRoot\modules\launch\PrivacySexy.ps1`""; Show-MainMenu }
        "4" { Start-Process powershell -ArgumentList "-NoExit -File `"$PSScriptRoot\modules\launch\UniGetUI.ps1`""; Show-MainMenu }
        "5" { Start-Process cmd -ArgumentList "/c `"$PSScriptRoot\modules\menu\Tweaks.bat`""; Show-MainMenu }
        "6" { Start-Process powershell -ArgumentList "-NoExit -File `"$PSScriptRoot\modules\menu\Drivers.ps1`""; Show-MainMenu }
        "7" { Start-Process cmd -ArgumentList "/c `"$PSScriptRoot\modules\menu\Customization.bat`""; Show-MainMenu }
        default { Show-MainMenu }
    }
}

# Start the main menu
Show-MainMenu
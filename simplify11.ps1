. "$PSScriptRoot\scripts\Common.ps1"

function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Simplify11 v25.05.2"
    Clear-Host
    Write-Host
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Purple   Tired of System Setup After Reinstall? Simplify It!  $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [0] Configure Your Windows Installation Answer File    $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [1] WinUtil - Install Programs, Tweaks, Fixes, Updates $Purple'$Reset"
    Write-Host "$Purple '$Grey [2] WinScript - Build your script from scratch         $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] GTweak - Tweaking tool and debloater               $Purple'$Reset"
    Write-Host "$Purple '$Grey [4] Privacy.sexy - Enforce privacy and security        $Purple'$Reset"
    Write-Host "$Purple '$Grey [5] UniGetUI - Discover, Install, Update Packages      $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [6] System Tweaks - SSD, GPU, CPU, Storage and etc     $Purple'$Reset"
    Write-Host "$Purple '$Grey [7] Install Drivers - Nvidia, AMD, Device Manufacturer $Purple'$Reset"
    Write-Host "$Purple '$Grey [8] Windots - Simpler way to rice & customize Windows  $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "0" { Start-Process "https://github.com/emylfy/simplify11/blob/main/docs/autounattend_guide.md"; Show-MainMenu }
        "1" { Start-Process powershell -ArgumentList "-NoExit -File `"$PSScriptRoot\modules\tools\WinUtil.ps1`""; Show-MainMenu }
        "2" { Start-Process powershell -ArgumentList "-NoExit -File `"$PSScriptRoot\modules\tools\WinScript.ps1`""; Show-MainMenu }
        "3" { Start-Process powershell -ArgumentList "-NoExit -File `"$PSScriptRoot\modules\tools\GTweak.ps1`""; Show-MainMenu }
        "4" { Start-Process powershell -ArgumentList "-NoExit -File `"$PSScriptRoot\modules\privacy\PrivacySexy.ps1`""; Show-MainMenu }
        "5" { Start-Process powershell -ArgumentList "-NoExit -File `"$PSScriptRoot\modules\unigetui\UniGetUI.ps1`""; Show-MainMenu }
        "6" { Start-Process powershell -ArgumentList "-NoExit -File `"$PSScriptRoot\modules\system\Tweaks.ps1`""; Show-MainMenu }
        "7" { Start-Process powershell -ArgumentList "-NoExit -File `"$PSScriptRoot\modules\drivers\Drivers.ps1`""; Show-MainMenu }
        "8" { Start-Process powershell -ArgumentList "-NoExit -File `"$PSScriptRoot\modules\windots\Windots.ps1`""; Show-MainMenu }
        default { Show-MainMenu }
    }
}

Show-MainMenu
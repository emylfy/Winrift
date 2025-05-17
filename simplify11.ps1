. "$PSScriptRoot\scripts\Common.ps1"

function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Simplify11 v25.05.1"
    Clear-Host
    Write-Host
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Purple   Tired of System Setup After Reinstall? Simplify It!  $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [0] Configure Your Windows Installation Answer File    $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] WinUtil - Install Programs, Tweaks, Fixes, Updates $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] WinScript - Build your script from scratch         $Purple'$Reset"
    Write-Host "$Purple '$Reset [3] GTweak - Tweaking tool and debloater               $Purple'$Reset"
    Write-Host "$Purple '$Reset [4] Privacy.sexy - Enforce privacy and security        $Purple'$Reset"
    Write-Host "$Purple '$Reset [5] UniGetUI - Discover, Install, Update Packages      $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [6] System Tweaks - SSD, GPU, CPU, Storage and etc     $Purple'$Reset"
    Write-Host "$Purple '$Reset [7] Install Drivers - Nvidia, AMD, Device Manufacturer $Purple'$Reset"
    Write-Host "$Purple '$Reset [8] Windots - Simpler way to rice & customize Windows  $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "0" { Start-Process "https://github.com/emylfy/simplify11/blob/main/docs/autounattend_guide.md"; Show-MainMenu }
        {"1","2","3","4","5","6","7","8" -contains $_} {
            . "$PSScriptRoot\scripts\AdminLaunch.ps1"
            
            $scriptPaths = @{
                "1" = "$PSScriptRoot\modules\tools\WinUtil.ps1"
                "2" = "$PSScriptRoot\modules\tools\WinScript.ps1"
                "3" = "$PSScriptRoot\modules\tools\GTweak.ps1"
                "4" = "$PSScriptRoot\modules\privacy\PrivacySexy.ps1"
                "5" = "$PSScriptRoot\modules\unigetui\UniGetUI.ps1"
                "6" = "$PSScriptRoot\modules\system\Tweaks.ps1"
                "7" = "$PSScriptRoot\modules\drivers\Drivers.ps1"
                "8" = "$PSScriptRoot\modules\windots\Windots.ps1"
            }
            
            Start-AdminProcess -ScriptPath $scriptPaths[$choice] -NoExit
            Show-MainMenu
        }
        default { Show-MainMenu }
    }
}

Show-MainMenu
. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-WinScriptMenu {
    Clear-Host
    Write-Host ""
    Write-Host "$Purple +-----------------------------------+$Reset"
    Write-Host "$Purple '$Grey  Winscript - Make Windows Yours   $Purple'$Reset"
    Write-Host "$Purple +-----------------------------------+$Reset"
    Write-Host "$Purple '$Grey [1] Open online version           $Purple'$Reset"
    Write-Host "$Purple '$Grey [2] Run portable version          $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] Back to menu                  $Purple'$Reset"
    Write-Host "$Purple +-----------------------------------+$Reset"
    
    $choice = Read-Host "Select an option"
    
    switch ($choice) {
        "1" { Open-OnlineVersion }
        "2" { Run-Portable }
        "3" { & "$PSScriptRoot\..\..\simplify11.ps1" }
        default { Show-WinScriptMenu }
    }
}

function Open-OnlineVersion {
    Start-Process "https://winscript.cc/online/"
    Show-WinScriptMenu
}

function Run-Portable {
    Write-Host "$Green Running portable WinScript... $Reset"
    Invoke-Expression (Invoke-RestMethod -Uri "https://winscript.cc/irm")
    Write-Host "$Green WinScript completed. $Reset"
    Show-WinScriptMenu
}

Show-WinScriptMenu
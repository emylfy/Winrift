. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-WinScriptMenu {
    $Host.UI.RawUI.WindowTitle = "WinScript Launcher"
    Clear-Host
    Write-Host ""
    Write-Host "$Purple +-----------------------------------+$Reset"
    Write-Host "$Purple '$Reset  Winscript - Make Windows Yours   $Purple'$Reset"
    Write-Host "$Purple +-----------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Open online version           $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] Run portable version          $Purple'$Reset"
    Write-Host "$Purple '$Reset [3] Back to menu                  $Purple'$Reset"
    Write-Host "$Purple +-----------------------------------+$Reset"

    $choice = Read-Host "Select an option"

    switch ($choice) {
        "1" { Open-OnlineVersion }
        "2" { Invoke-Portable }
        "3" { return }
        default { Show-WinScriptMenu }
    }
}

function Open-OnlineVersion {
    Start-Process "https://winscript.cc/online/"
    Show-WinScriptMenu
}

function Invoke-Portable {
    Write-Host "$Green Running portable WinScript... $Reset"
    try {
        $scriptContent = Invoke-RestMethod -Uri "https://winscript.cc/irm" -ErrorAction Stop
        Invoke-Expression $scriptContent
    } catch {
        Write-Host "$Red Failed to launch portable WinScript: $($_.Exception.Message) $Reset"
        Read-Host "Press Enter to continue"
    }
    Show-WinScriptMenu
}

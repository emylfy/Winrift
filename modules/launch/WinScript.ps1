$Purple = [char]0x1b + "[38;5;141m"
$Grey = [char]0x1b + "[38;5;250m"
$Reset = [char]0x1b + "[0m"
$Red = [char]0x1b + "[38;5;203m"
$Green = [char]0x1b + "[38;5;120m"

function Show-WinScriptMenu {
    Clear-Host
    Write-Host ""
    Write-Host "$Purple +-----------------------------------+$Reset"
    Write-Host "$Purple '$Grey  Winscript - Make Windows Yours   $Purple'$Reset"
    Write-Host "$Purple +-----------------------------------+$Reset"
    Write-Host "$Purple '$Grey [1] Open online version           $Purple'$Reset"
    Write-Host "$Purple '$Grey [2] Install and Launch via Winget $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] Back to menu                  $Purple'$Reset"
    Write-Host "$Purple +-----------------------------------+$Reset"
    
    $choice = Read-Host "Select an option"
    
    switch ($choice) {
        "1" { Open-OnlineVersion }
        "2" { Install-WinScript }
        "3" { return }
        default { Show-WinScriptMenu }
    }
}

function Open-OnlineVersion {
    Start-Process "https://winscript.cc/online/"
    Show-WinScriptMenu
}

function Install-WinScript {
    Write-Host "$Green Installing WinScript... This may take a moment. $Reset"
    Start-Process "winget" -ArgumentList "install --id=flick9000.WinScript" -Wait
    Start-Process "$env:ProgramFiles\WinScript\WinScript.exe"
    Write-Host "$Green Installation complete. Launching WinScript... $Reset"
    exit
}

Show-WinScriptMenu
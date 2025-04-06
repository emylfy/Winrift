. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Purple = [char]0x1b + "[38;5;141m"
$Grey = [char]0x1b + "[38;5;250m"
$Reset = [char]0x1b + "[0m"
$Red = [char]0x1b + "[38;5;203m"
$Green = [char]0x1b + "[38;5;120m"

function Show-Menu {
    Clear-Host
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey Customization Options                                  $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [1] Set Short Date and Hours Format - Feb 17, 17:57    $Purple'$Reset"
    Write-Host "$Purple '$Grey [2] Disable automatic pin of folders to Quick Access   $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] Selectively pull icons from folders in start menu  $Purple'$Reset"
    Write-Host "$Purple +-Require-Internet-Connection----------------------------+$Reset"
    Write-Host "$Purple '$Grey [4] Launch Windots - configs, cursor, wallpapers       $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [5] Back to Menu                                       $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"

    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" { Set-ShortDateHours }
        "2" { Disable-QuickAccess }
        "3" { Extract-StartFolders }
        "4" { Start-Windots }
        "5" { exit }
        default { Show-Menu }
    }
}

function Set-ShortDateHours {
    Clear-Host
    Write-Host "${Grey}Setting short date and hours format...$Reset"
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sShortDate -Value "dd MMM yyyy"
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sShortTime -Value "HH:mm"
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sTimeFormat -Value "HH:mm:ss"
    Write-Host "${Grey}Date and time format updated successfully. Changes will take effect after restart.$Reset"
    pause
    Show-Menu
}

function Disable-QuickAccess {
    Clear-Host
    Write-Host "${Grey}Disabling automatic addition of folders to Quick Access...$Reset"
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowFrequent' -Type DWord -Value 0
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowRecent' -Type DWord -Value 0
    $quickAccess = (New-Object -ComObject shell.application).Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}').Items()
    $quickAccess | ForEach-Object { $_.InvokeVerb('remove') }
    Stop-Process -Name explorer -Force
    Start-Process explorer
    Write-Host "${Green}Quick Access settings updated successfully. Explorer will restart to apply changes.$Reset"
    pause
    Show-Menu
}

function Extract-StartFolders {
    Clear-Host
    $scriptDir = Split-Path -Parent $PSScriptRoot
    $organizerPath = Join-Path -Path $scriptDir -ChildPath "tweaks\Organizer.ps1"
    Start-Process powershell -ArgumentList "-NoExit -File `"$organizerPath`""
    Show-Menu
}

function Start-Windots {
    Clear-Host
    Start-Process wt -ArgumentList "powershell -Command `"iwr 'https://dub.sh/windots' |iex`""
    Show-Menu
}

Show-Menu
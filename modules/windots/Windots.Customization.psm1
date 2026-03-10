function Set-ShortDateHours {
    Clear-Host
    Write-Host "${Reset}Setting short date and hours format...$Reset"
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sShortDate -Value "dd MMM yyyy"
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sShortTime -Value "HH:mm"
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sTimeFormat -Value "HH:mm:ss"
    Write-Host "${Reset}Date and time format updated successfully. Changes will take effect after restart.$Reset"
    pause
    Show-WindowsCustomizationMenu
}

function Disable-QuickAccess {
    Clear-Host
    Write-Host "${Reset}Disabling automatic addition of folders to Quick Access...$Reset"

    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowFrequent' -Type DWord -Value 0
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowRecent' -Type DWord -Value 0

    $quickAccess = (New-Object -ComObject shell.application).Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}').Items()
    $quickAccess | ForEach-Object { $_.InvokeVerb('remove') }
    
    Write-Host "${Yellow}Restarting Explorer to apply changes...$Reset"
    Stop-Process -Name explorer -Force
    Write-Host "${Green}Quick Access settings updated successfully.$Reset"
    Read-Host "Press Enter to continue"
    Show-WindowsCustomizationMenu
}

function Expand-StartFolders {
    Clear-Host
    $scriptDir = Split-Path -Parent $PSScriptRoot
    $organizerPath = Join-Path -Path $scriptDir -ChildPath "windots\Organizer.ps1"
    Start-Process powershell -ArgumentList "-NoExit -File `"$organizerPath`""
    Show-WindowsCustomizationMenu
}

Export-ModuleMember -Function `
    Set-ShortDateHours, `
    Disable-QuickAccess, `
    Expand-StartFolders


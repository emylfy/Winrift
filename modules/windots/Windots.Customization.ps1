function Set-ShortDateHours {
    Clear-Host
    Write-Log -Message "Setting short date and hours format..." -Level INFO
    Set-RegistryValue -Path "HKCU:\Control Panel\International" -Name "sShortDate" -Type String -Value "dd MMM yyyy" -Message "Short date format set to dd MMM yyyy"
    Set-RegistryValue -Path "HKCU:\Control Panel\International" -Name "sShortTime" -Type String -Value "HH:mm" -Message "Short time format set to HH:mm"
    Set-RegistryValue -Path "HKCU:\Control Panel\International" -Name "sTimeFormat" -Type String -Value "HH:mm:ss" -Message "Time format set to HH:mm:ss"
    Write-Log -Message "Changes will take effect after restart." -Level INFO
    Read-Host "Press Enter to continue"
}

function Disable-QuickAccess {
    Clear-Host
    Write-Log -Message "Disabling automatic addition of folders to Quick Access..." -Level INFO
    Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Type DWord -Value 0 -Message "Disabled frequent folders in Quick Access"
    Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Type DWord -Value 0 -Message "Disabled recent files in Quick Access"

    try {
        $quickAccess = (New-Object -ComObject shell.application).Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}').Items()
        $quickAccess | ForEach-Object { $_.InvokeVerb('remove') }

        Write-Log -Message "Restarting Explorer to apply changes..." -Level WARNING
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 2
        if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
            Start-Process explorer
            Write-Log -Message "Explorer restarted manually." -Level INFO
        }
        Write-Log -Message "Quick Access settings updated successfully." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to update Quick Access settings: $($_.Exception.Message)" -Level ERROR
    }
    Read-Host "Press Enter to continue"
}

function Expand-StartFolders {
    Clear-Host
    $organizerPath = Join-Path -Path $PSScriptRoot -ChildPath "Organizer.ps1"
    if (Test-Path $organizerPath) {
        Start-Process powershell -ArgumentList "-NoExit -File `"$organizerPath`""
    } else {
        Write-Log -Message "Organizer.ps1 not found at: $organizerPath" -Level ERROR
        Read-Host "Press Enter to continue"
    }
}

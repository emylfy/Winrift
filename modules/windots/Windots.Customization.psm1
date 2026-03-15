function Set-ShortDateHours {
    Clear-Host
    Write-Log -Message "Setting short date and hours format..." -Level INFO
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sShortDate -Value "dd MMM yyyy"
        Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sShortTime -Value "HH:mm"
        Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sTimeFormat -Value "HH:mm:ss"
        Write-Log -Message "Date and time format updated successfully. Changes will take effect after restart." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to update date/time format: $($_.Exception.Message)" -Level ERROR
    }
    Read-Host "Press Enter to continue"
}

function Disable-QuickAccess {
    Clear-Host
    Write-Log -Message "Disabling automatic addition of folders to Quick Access..." -Level INFO
    try {
        Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowFrequent' -Type DWord -Value 0
        Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowRecent' -Type DWord -Value 0

        $quickAccess = (New-Object -ComObject shell.application).Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}').Items()
        $quickAccess | ForEach-Object { $_.InvokeVerb('remove') }

        Write-Log -Message "Restarting Explorer to apply changes..." -Level WARNING
        Stop-Process -Name explorer -Force
        Write-Log -Message "Quick Access settings updated successfully." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to update Quick Access settings: $($_.Exception.Message)" -Level ERROR
    }
    Read-Host "Press Enter to continue"
}

function Expand-StartFolders {
    Clear-Host
    $scriptDir = Split-Path -Parent $PSScriptRoot
    $organizerPath = Join-Path -Path $scriptDir -ChildPath "windots\Organizer.ps1"
    if (Test-Path $organizerPath) {
        Start-Process powershell -ArgumentList "-NoExit -File `"$organizerPath`""
    } else {
        Write-Log -Message "Organizer.ps1 not found at: $organizerPath" -Level ERROR
        Read-Host "Press Enter to continue"
    }
}

Export-ModuleMember -Function `
    Set-ShortDateHours, `
    Disable-QuickAccess, `
    Expand-StartFolders

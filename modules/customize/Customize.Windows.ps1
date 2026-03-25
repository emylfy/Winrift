function Set-ShortDateHours {
    Clear-Host
    Write-Log -Message "Setting short date and hours format..." -Level INFO
    Set-RegistryValue -Path "HKCU:\Control Panel\International" -Name "sShortDate" -Type String -Value "MMM dd yyyy" -Message "Short date format set to MMM dd yyyy"
    Set-RegistryValue -Path "HKCU:\Control Panel\International" -Name "sShortTime" -Type String -Value "HH:mm" -Message "Short time format set to HH:mm"
    Set-RegistryValue -Path "HKCU:\Control Panel\International" -Name "sTimeFormat" -Type String -Value "HH:mm:ss" -Message "Time format set to HH:mm:ss"
    Write-Log -Message "Changes will take effect after restart." -Level INFO
    Wait-ForUser
}

function Disable-QuickAccess {
    Clear-Host
    Write-Log -Message "Disabling automatic addition of folders to Quick Access..." -Level INFO
    Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Type DWord -Value 0 -Message "Disabled frequent folders in Quick Access"
    Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Type DWord -Value 0 -Message "Disabled recent files in Quick Access"

    $shell = $null
    try {
        $shell = New-Object -ComObject shell.application
        $namespace = $shell.Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}')
        if ($namespace) {
            $items = $namespace.Items()
            if ($items) {
                $removeErrors = 0
                $items | ForEach-Object {
                    try { $_.InvokeVerb('remove') } catch { $removeErrors++ }
                }
                if ($removeErrors -gt 0) {
                    Write-Log -Message "Could not remove $removeErrors Quick Access items." -Level WARNING
                }
            }
        }

        Write-Log -Message "Explorer needs to restart to apply changes." -Level WARNING
        Write-Log -Message "Save any open file operations before continuing." -Level WARNING
        $confirm = Read-Host "Restart Explorer now? (Y/N)"
        if ($confirm -eq 'y') {
            Stop-Process -Name explorer -Force
            # Wait for Explorer to fully terminate, then ensure it restarts
            $timeout = 0
            while ((Get-Process explorer -ErrorAction SilentlyContinue) -and $timeout -lt 10) {
                Start-Sleep -Milliseconds 500
                $timeout++
            }
            Start-Sleep -Seconds 1
            if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
                Start-Process explorer
            }
            Write-Log -Message "Explorer restarted." -Level INFO
        } else {
            Write-Log -Message "Skipped restart. Changes will apply on next login." -Level INFO
        }
        Write-Log -Message "Quick Access settings updated." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to update Quick Access settings: $($_.Exception.Message)" -Level ERROR
    } finally {
        if ($null -ne $shell) {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
        }
    }
    Wait-ForUser
}

function Expand-StartFolders {
    Clear-Host
    $organizerPath = Join-Path -Path $PSScriptRoot -ChildPath "Organizer.ps1"
    if (Test-Path $organizerPath) {
        . "$PSScriptRoot\..\..\scripts\AdminLaunch.ps1"
        Start-AdminProcess -ScriptPath $organizerPath
    } else {
        Write-Log -Message "Organizer.ps1 not found at: $organizerPath" -Level ERROR
        Wait-ForUser
    }
}

function Set-ShortDateHours {
    Clear-Host
    $confirm = Show-InteractiveMenu -Title "Set Date & Time Format" -HideKeys -Items @(
        "Sets short date to 'MMM dd yyyy' and time to 'HH:mm'. Example: Nov 04 2026, 23:30.",
        "---",
        "Y › Apply",
        "N › Cancel"
    )
    if ($confirm -ne "Y") { return }
    Write-Log -Message "Setting short date and hours format..." -Level INFO
    Set-RegistryValue -Path "HKCU:\Control Panel\International" -Name "sShortDate" -Type String -Value "MMM dd yyyy" -Message "Short date format set to MMM dd yyyy"
    Set-RegistryValue -Path "HKCU:\Control Panel\International" -Name "sShortTime" -Type String -Value "HH:mm" -Message "Short time format set to HH:mm"
    Set-RegistryValue -Path "HKCU:\Control Panel\International" -Name "sTimeFormat" -Type String -Value "HH:mm:ss" -Message "Time format set to HH:mm:ss"
    Write-Log -Message "Changes will take effect after restart." -Level INFO
    Wait-ForUser
}

function Disable-QuickAccess {
    Invoke-MenuLoop -Title 'Recent Files & Frequent Folders' -Items @(
        '1 › Disable Recent / Frequent Visibility ›',
        '2 › Clear Current Quick Access Contents ›', '---', '0 › Back'
    ) -Actions @{
        '1' = {
            $choice = Show-InteractiveMenu -Title 'Review Changes' -Items @('Hide recent files and frequent folders. Existing Quick Access items will be retained.', '---', 'Y › Apply', 'N › Back')
            if ($choice -eq 'Y') {
                Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name ShowFrequent -Type DWord -Value 0 -Message 'Hide frequent folders'
                Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name ShowRecent -Type DWord -Value 0 -Message 'Hide recent files'
                Write-Log 'Review individual results. Explorer may need to be reopened.'
                Wait-ForUser
            }
        }
        '2' = { Clear-WinriftQuickAccess }
    } -ExitKey '0' -HideKeys
}

function Clear-WinriftQuickAccess {
    $choice = Show-InteractiveMenu -Title 'Review Quick Access Cleanup' -Items @(
        'Remove current Quick Access entries. Personal files are not deleted.',
        'This cleanup cannot be restored by Winrift Undo.', '---', 'Y › Clear Entries', 'N › Back'
    )
    if ($choice -ne 'Y') { return }
    if ($env:WINRIFT_DRY_RUN -eq '1') { Write-Log '[DRY-RUN] Clear Quick Access entries'; Wait-ForUser; return }
    $shell = $null
    try {
        $shell = New-Object -ComObject shell.application
        $namespace = $shell.Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}')
        if (-not $namespace) { throw 'Quick Access shell namespace unavailable.' }
        $count = 0; $failed = 0
        foreach ($item in @($namespace.Items())) { try { $item.InvokeVerb('remove'); $count++ } catch { $failed++ } }
        Write-Log "Removal requests: $count. Failed: $failed. Reopen Explorer to check the result."
    } catch { Write-Log $_.Exception.Message -Level ERROR }
    finally { if ($shell) { [Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null } }
    Wait-ForUser
}
function Expand-StartFolders {
    Clear-Host
    $organizerPath = Join-Path -Path $PSScriptRoot -ChildPath "Organizer.ps1"
    if (-not (Test-Path $organizerPath)) {
        Write-Log -Message "Organizer.ps1 not found at: $organizerPath" -Level ERROR
        Wait-ForUser
        return
    }
    # Use pwsh.exe -Verb RunAs directly — bypasses Windows Terminal
    # so the admin token is always correctly applied to the PowerShell process.
    & $organizerPath
}

# https://github.com/ancel1x/Ancels-Performance-Batch

function Invoke-PowerMenu {
    Invoke-MenuLoop -Title 'Power Settings' -Items @(
        '1 › Enable Ultimate Performance      ›',
        '2 › Background Throttling & Energy Tracking ›',
        '3 › Advanced Standby / Idle / CPPC / PEP / ASPM ›',
        '4 › Open Windows Power Plans         ↗', '---', '0 › Back'
    ) -Actions @{
        '1' = { Enable-WinriftUltimatePerformance }
        '2' = { Show-WinriftTweakSelection 'Background Throttling & Energy Tracking' { Invoke-PowerTweaks } }
        '3' = { Show-WinriftTweakSelection 'Experimental Power — heat and battery trade-offs' { Invoke-AggressivePowerTweaks } }
        '4' = {
            if ($env:WINRIFT_DRY_RUN -eq '1') { Write-Log '[DRY-RUN] Open Windows Power Plans' -Quiet; return }
            Start-Process control.exe -ArgumentList '/name Microsoft.PowerOptions'
        }
    } -ExitKey '0' -HideKeys
}

function Enable-WinriftUltimatePerformance {
    $output = & powercfg.exe /list 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Log 'Power plan list unavailable.' -Level ERROR; Wait-ForUser; return }
    $template = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
    $guid = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'
    $available = @($output | ForEach-Object {
        if ($_ -match '\b([a-fA-F0-9-]{36})\s+\(') { $Matches[1] }
    })
    if ($guid -notin $available -and $template -in $available) { $guid = $template }

    $before = Get-WinriftSystemValue 'PowerPlan'
    if ($before -eq $guid) {
        Clear-Host
        Show-InfoBox -Title 'Ultimate Performance' -Items @('This power plan is already active.')
        Wait-ForUser
        return
    }

    $confirm = Show-InteractiveMenu -Title 'Ultimate Performance' -HideKeys -Items @(
        'This plan can increase power use.', '---', 'Y › Enable', 'N › Back'
    )
    if ($confirm -ne 'Y') { return }
    if ($env:WINRIFT_DRY_RUN -eq '1') { Write-Log '[DRY-RUN] Enable Ultimate Performance'; Wait-ForUser; return }
    Clear-Host
    $record = New-WinriftActionRecord -Kind System -Label 'Enable Ultimate Performance' -Target @{Id='PowerPlan'} -Before $before -Proposed $guid
    Save-WinriftActionRecord $record
    try {
        if ($guid -notin $available) {
            & powercfg.exe /duplicatescheme $template $guid | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'Ultimate Performance is unavailable on this system.' }
        }
        Set-WinriftSystemValue 'PowerPlan' $guid
        if ((Get-WinriftSystemValue 'PowerPlan') -ne $guid) { throw 'Active power plan verification failed.' }
        $record.status='Applied'; $record.verification='Active plan queried.'
        Save-WinriftActionRecord $record
        Write-Log 'Ultimate Performance is active.' -Level SUCCESS
    } catch { $record.status='Failed'; $record.error=$_.Exception.Message; Save-WinriftActionRecord $record; Write-Log $record.error -Level ERROR }
    Wait-ForUser
}
function Invoke-AggressivePowerTweaks {
    $chassis = (Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue).ChassisTypes
    # ChassisTypes 9,10,14 = Laptop/Notebook/Sub Notebook
    if ($chassis | Where-Object { $_ -in @(9, 10, 14) }) {
        Write-Log -Message "WARNING: Laptop detected. These tweaks disable sleep/idle states and ASPM, which increases heat and battery drain. Skip if not on AC power." -Level WARNING
    }

    # source - https://github.com/ancel1x/Ancels-Performance-Batch
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "CsEnabled" -Type "DWord" -Value "0" -Message "Disable connected standby"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PlatformAoAcOverride" -Type "DWord" -Value "0" -Message "Disable AC/DC platform power behavior override"

    # CPU Throttling - prevents idle C-states
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Throttle" -Name "PerfEnablePackageIdle" -Type "DWord" -Value "0" -Message "Disable CPU package idle states"

    # Processor Power Management
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Processor" -Name "CPPCEnable" -Type "DWord" -Value "0" -Message "Disable Collaborative Processor Performance Control"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Processor" -Name "AllowPepPerfStates" -Type "DWord" -Value "0" -Message "Disable Platform Energy Provider performance states"

    # PCIe Power Saving (ASPM)
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\pci\Parameters" -Name "ASPMOptOut" -Type "DWord" -Value "1" -Message "Disable PCIe ASPM power saving"
}

function Invoke-PowerPlanActivation { Enable-WinriftUltimatePerformance }

# https://github.com/ancel1x/Ancels-Performance-Batch

function Invoke-PowerMenu {
    Invoke-MenuLoop -Title 'Power Settings' -Items @(
        '1 › Select Power Plan                ›',
        '2 › Background Throttling & Energy Tracking ›',
        '3 › Advanced Standby / Idle / CPPC / PEP / ASPM ›',
        '4 › Open Windows Power Mode          ↗', '---', '0 › Back'
    ) -Actions @{
        '1' = { Show-WinriftPowerPlans }
        '2' = { Show-WinriftTweakSelection 'Background Throttling & Energy Tracking' { Invoke-PowerTweaks } }
        '3' = { Show-WinriftTweakSelection 'Advanced Power — heat and battery trade-offs' { Invoke-AggressivePowerTweaks } }
        '4' = { if ($env:WINRIFT_DRY_RUN -eq '1') { Write-Log '[DRY-RUN] Open Windows Power Mode'; Wait-ForUser } else { Start-Process 'ms-settings:powersleep' } }
    } -ExitKey '0' -HideKeys
}

function Show-WinriftPowerPlans {
    $output = & powercfg.exe /list 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Log 'Power plan list unavailable.' -Level ERROR; Wait-ForUser; return }
    $plans = @()
    foreach ($line in $output) {
        if ($line -match '([a-fA-F0-9-]{36})\s+\((.+)\)') { $plans += @{ Id=$Matches[1]; Name=$Matches[2] } }
    }
    $items = @()
    for ($i=0; $i -lt $plans.Count; $i++) { $items += "$i › $($plans[$i].Name)" }
    $items += @('U › Ultimate Performance', '---', 'B › Back')
    $choice = Show-InteractiveMenu -Title 'Select Power Plan' -Items $items
    if ($null -eq $choice -or $choice -eq 'B') { return }
    $guid = $null
    if ($choice -eq 'U') { $guid = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee' }
    else { $i=0; if ([int]::TryParse($choice,[ref]$i) -and $i -ge 0 -and $i -lt $plans.Count) { $guid=$plans[$i].Id } }
    if (-not $guid) { return }
    $confirm = Show-InteractiveMenu -Title 'Review Power Plan' -Items @("Proposed plan: $guid", 'Power mode and power plan are distinct.', '---', 'Y › Apply', 'N › Back')
    if ($confirm -ne 'Y') { return }
    if ($env:WINRIFT_DRY_RUN -eq '1') { Write-Log "[DRY-RUN] Activate power plan $guid"; Wait-ForUser; return }
    $before = Get-WinriftSystemValue 'PowerPlan'
    $record = New-WinriftActionRecord -Kind System -Label 'Select power plan' -Target @{Id='PowerPlan'} -Before $before -Proposed $guid
    Save-WinriftActionRecord $record
    try {
        if ($choice -eq 'U' -and $guid -notin $plans.Id) {
            & powercfg.exe /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 $guid | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'Ultimate Performance is unavailable on this system.' }
        }
        Set-WinriftSystemValue 'PowerPlan' $guid
        if ((Get-WinriftSystemValue 'PowerPlan') -ne $guid) { throw 'Active power plan verification failed.' }
        $record.status='Applied'; $record.verification='Active plan queried.'
        Save-WinriftActionRecord $record
        Write-Log 'Active power plan verified.' -Level SUCCESS
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
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "CsEnabled" -Type "DWord" -Value "0" -Message "Disabled connected standby for better performance"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PlatformAoAcOverride" -Type "DWord" -Value "0" -Message "Disabled AC/DC platform power behavior override"

    # CPU Throttling - prevents idle C-states
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Throttle" -Name "PerfEnablePackageIdle" -Type "DWord" -Value "0" -Message "Disabled CPU package idle states"

    # Processor Power Management
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Processor" -Name "CPPCEnable" -Type "DWord" -Value "0" -Message "Disabled Collaborative Processor Performance Control"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Processor" -Name "AllowPepPerfStates" -Type "DWord" -Value "0" -Message "Disabled Platform Energy Provider performance states"

    # PCIe Power Saving (ASPM)
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\pci\Parameters" -Name "ASPMOptOut" -Type "DWord" -Value "1" -Message "Disabled PCIe ASPM power saving"
}

function Invoke-PowerPlanActivation { Show-WinriftPowerPlans }

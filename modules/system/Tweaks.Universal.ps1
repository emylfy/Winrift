# https://github.com/AlchemyTweaks/Verified-Tweaks
# https://github.com/SanGraphic/QuickBoost
# https://github.com/UnLovedCookie/CoutX
# https://github.com/Snowfliger/SyncOS
# https://github.com/denis-g/windows10-latency-optimization

# Named Constants
# Accessibility flag values (Windows accessibility registry format)
# Input buffer sizes (optional overrides; effect depends on workload, default is 100)
$INPUT_QUEUE_SIZE           = "20"
# Network
$NETWORK_THROTTLING_OFF     = "4294967295"  # 0xFFFFFFFF — disables network throttling
# CPU multimedia scheduler
$LAZY_MODE_TIMEOUT_100NS       = "25000"  # 25000 x 100ns = 2.5ms (MMCSS)
# Process priority — short interval, variable length, high foreground boost (2:1)
$PRIORITY_SEPARATION        = "0x00000024"
# UI timeouts (milliseconds)
$HUNG_APP_TIMEOUT_MS        = "1000"
$WAIT_KILL_APP_TIMEOUT_MS   = "2000"
$LOW_LEVEL_HOOKS_TIMEOUT_MS = "1000"
$MENU_SHOW_DELAY_MS         = "0"
$WAIT_KILL_SVC_TIMEOUT_MS   = "2000"

function Get-WinriftTweakNote {
    param([string]$Name)

    switch -Wildcard ($Name) {
        'Accessibility.*' { 'Other accessibility settings are preserved.' }
        'LastAccess' { 'Restart Windows to apply this change.' }
        'EnablePreemption' { 'Driver compatibility has not been verified.' }
        'NoLazyMode' { 'The effect of this override has not been verified.' }
        'PowerThrottlingOff' { 'This may increase power use.' }
        'AutoEndTasks' { 'Windows may close unresponsive apps and discard unsaved work.' }
        'WaitToKill*Timeout' { 'Apps and services have less time to finish work during shutdown.' }
        'PerfEnablePackageIdle' { 'Disabling CPU idle states can increase heat and battery drain.' }
        'ASPMOptOut' { 'Disabling PCIe power saving can increase power use.' }
        'LargeSystemCache' { 'The effect depends on your hardware and workload.' }
        'MaintenanceDisabled' { 'Windows stops scheduling automatic maintenance.' }
        'D3D*' { 'Driver compatibility and performance effects have not been verified.' }
    }
}

function Show-WinriftTweakSelection {
    param([string]$Title, [scriptblock]$CollectBlock)
    Clear-AuditQueue
    $script:CollectMode = $true
    try { & $CollectBlock } finally { $script:CollectMode = $false }
    $entries = @($script:AuditQueue.ToArray())
    if (-not $entries.Count) { Write-Log 'No applicable actions found.'; Wait-ForUser; return }
    $selectionId=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Title)))
    $selectionPath=Join-Path (Get-WinriftStateRoot) ("ui\tweaks-$selectionId.json")
    $saved=@()
    if(Test-Path -LiteralPath $selectionPath){try{$saved=@((Read-WinriftJson $selectionPath).selected)}catch{Write-Log 'Saved tweak selection is unreadable; original state preserved.' -Level WARNING}}
    $tokens=@($entries|ForEach-Object{if($_.Kind -eq 'System'){$_.Id}else{"$($_.Path)|$($_.Name)"}})
    $defaults=@()
    $items = @(); $disabled = @(); $markers = @(); $details = @{}
    for ($i = 0; $i -lt $entries.Count; $i++) {
        $entry = $entries[$i]
        $changed = Test-WinriftQueuedChange $entry
        $unsupported = $entry.Kind -eq 'System' -and -not $entry.Supported
        $items += "$i › $($entry.Message)"
        $disabled += (-not $changed)
        $defaults += ($changed -and $tokens[$i] -in $saved)
        $markers += $(if ($unsupported) { '–' } elseif (-not $changed) { '✓' } else { '' })
        $note = Get-WinriftTweakNote $entry.Name
        $details[$i] = @("Current: $($entry.Current)", "Proposed: $($entry.Value) ($($entry.Type))", $(if ($entry.Path) { "$($entry.Path)\$($entry.Name)" } else { $entry.Id }), $entry.Reason, $note) | Where-Object { $_ }
    }
    $changedSelection={param($keys) $values=@($keys|ForEach-Object{$tokens[[int]$_]});Write-WinriftAtomicJson -Path $selectionPath -Value @{schemaVersion=1;selected=$values}}
    $selected = @(Show-MultiSelect -Title $Title -Items $items -Disabled $disabled -Markers $markers -Descriptions $details -DetailsOnly -Defaults $defaults -OnSelectionChanged $changedSelection)
    $script:AuditQueue.Clear()
    foreach ($key in $selected) { $script:AuditQueue.Add($entries[[int]$key]) }
    if ($script:AuditQueue.Count -and (Show-AuditTable -NamesOnly -GetNote { param($name) Get-WinriftTweakNote $name })) {
        $approved = @($script:AuditQueue | ForEach-Object { [array]::IndexOf($entries, $_) })
        & $changedSelection $approved
        Invoke-WinriftTweakApplyWithResults
    } else { Clear-AuditQueue }
}

function Invoke-WinriftTweakApplyWithResults {
    param([string]$Title = 'Tweak Results', [switch]$MayRequireRestart)

    Clear-Host
    $results = @(Invoke-AuditedApply -Report 6>$null)
    $saveFailed = $false
    try {
        Save-TweakBackup 6>$null
        Save-DesiredState 6>$null
    } catch {
        $saveFailed = $true
        Write-Log "Could not save tweak backup or state: $($_.Exception.Message)" -Level ERROR -Quiet
    }

    $summary = @()
    if ($results.Count -eq 0) { $summary += 'No changes needed.' }
    foreach ($status in @('Applied', 'AlreadyMatches', 'DryRun')) {
        $count = @($results | Where-Object Status -EQ $status).Count
        if (-not $count) { continue }
        $label = switch ($status) {
            'Applied' { 'Applied' }
            'AlreadyMatches' { 'Already matched' }
            'DryRun' { 'Would apply' }
        }
        $summary += "$label · $count"
    }
    $failed = @($results | Where-Object { $_.Status -notin @('Applied', 'AlreadyMatches', 'DryRun') })
    if ($failed.Count) { $summary += @('--- Could not apply ---') + @($failed.Name) }
    if ($saveFailed) { $summary += 'Could not save backup or state.' }
    if ($failed.Count -or $saveFailed) { $summary += 'See Help → Open Logs for details.' }
    if ($MayRequireRestart -and ($results.Status -contains 'Applied')) { $summary += 'A restart may be required.' }
    Show-InfoBox -Title $Title -Items $summary
    Wait-ForUser
}

function Invoke-UniversalTweaks {
    Show-WinriftTweakSelection -Title 'All Tweaks' -CollectBlock {
        Invoke-SystemLatencyTweaks; Invoke-InputDeviceTweaks; Invoke-SSDTweaks
        Invoke-GPUTweaks; Invoke-NetworkTweaks; Invoke-CPUTweaks; Invoke-PowerTweaks
        Invoke-SystemResponsivenessTweaks; Invoke-BootOptimizationTweaks
        Invoke-UIResponsivenessTweaks; Invoke-MemoryTweaks
        Invoke-SystemMaintenanceTweaks; Invoke-DirectXTweaks
    }
}

function Invoke-AccessibilityShortcutTweaks {
    foreach($part in @('StickyKeys','ToggleKeys','Keyboard Response')){
        try{
            $flags=Get-WinriftSystemValue ('Accessibility.'+$part)
            $label = switch ($part) {
                'StickyKeys' { 'Sticky Keys' }
                'ToggleKeys' { 'Toggle Keys' }
                'Keyboard Response' { 'Filter Keys' }
            }
            Add-WinriftSystemAction -Id ('Accessibility.'+$part) -Value ([int]$flags -band (-bnot 4)) -Message "Disable $label shortcut"
        }catch{Write-Log "Accessibility shortcut unavailable: $part" -Level WARNING}
    }
}
function Invoke-RecommendedTweaks {
    Show-WinriftTweakSelection -Title 'Review Recommended Preset' -CollectBlock {
        Invoke-AccessibilityShortcutTweaks
        Add-WinriftSystemAction -Id MenuDelay -Value ([int]$MENU_SHOW_DELAY_MS) -Message 'Remove menu display delay'
        Add-WinriftSystemAction -Id 'Trim.NTFS' -Value 0 -Message 'Enable NTFS TRIM notifications'
        Add-WinriftSystemAction -Id 'Trim.ReFS' -Value 0 -Message 'Enable ReFS TRIM notifications'
    }
}
function Invoke-SystemLatencyTweaks {

    # Changing Interrupts behavior for lower latency
    # source - https://youtu.be/Gazv0q3njYU
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "InterruptSteeringDisabled" -Type "DWord" -Value "1" -Message "Disable interrupt steering"

    # Serialize Timer Expiration mechanism, officially documented in Windows Internals 7th E2
    # source - https://youtu.be/wil-09_5H0M
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "SerializeTimerExpiration" -Type "DWord" -Value "1" -Message "Enable timer serialization"
}

function Invoke-InputDeviceTweaks {

    # MouseDataQueueSize and KeyboardDataQueueSize - smaller buffer = faster processing
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" -Name "MouseDataQueueSize" -Type "DWord" -Value $INPUT_QUEUE_SIZE -Message "Set mouse input queue to $INPUT_QUEUE_SIZE"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" -Name "KeyboardDataQueueSize" -Type "DWord" -Value $INPUT_QUEUE_SIZE -Message "Set keyboard input queue to $INPUT_QUEUE_SIZE"

    # Accessibility and keyboard response settings
    Invoke-AccessibilityShortcutTweaks
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "DelayBeforeAcceptance" -Type "String" -Value "0" -Message "Remove Filter Keys acceptance delay"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "AutoRepeatRate" -Type "String" -Value "0" -Message "Set Filter Keys repeat interval to 0 ms"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "AutoRepeatDelay" -Type "String" -Value "0" -Message "Remove Filter Keys repeat delay"
}

function Invoke-SSDTweaks {
    Add-WinriftSystemAction 'Trim.NTFS' 0 'Enable NTFS TRIM notifications'
    Add-WinriftSystemAction 'Trim.ReFS' 0 'Enable ReFS TRIM notifications'
    Add-WinriftSystemAction 'LastAccess' 1 'Disable NTFS last-access updates'
    Set-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name NtfsDisable8dot3NameCreation -Type DWord -Value 1 -Message "Disable 8.3 filename creation"
    Add-WinriftSystemAction 'MMAgent.ApplicationPreLaunch' $false 'Disable Application Prelaunch'
    Set-RegistryValue -Path 'HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' -Name EnablePrefetcher -Type DWord -Value 0 -Message "Disable Prefetch"
    # SfTracingState deferred pending target-version verification.
}
function Invoke-GPUTweaks {

    # HwSchMode - Hardware Accelerated GPU Scheduling, reduces latency
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Type "DWord" -Value "2" -Message "Enable hardware-accelerated GPU scheduling"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" -Name "EnablePreemption" -Type "DWord" -Value "0" -Message "Disable GPU preemption"
}

function Invoke-NetworkTweaks {

    # Disable network throttling - especially helpful with gigabit networks
    # source - https://youtu.be/EmdosMT5TtA
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Type "DWord" -Value $NETWORK_THROTTLING_OFF -Message "Disable multimedia network throttling"
}

function Invoke-CPUTweaks {
    # Existing NoLazyMode is retained; upstream currently uses LazyMode=0.
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NoLazyMode" -Type "DWord" -Value "1" -Message "Set MMCSS NoLazyMode override"

    # source - https://youtu.be/FxpRL7wheGc
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "LazyModeTimeout" -Type "DWord" -Value $LAZY_MODE_TIMEOUT_100NS -Message "Set MMCSS lazy-mode timeout to 2.5 ms"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\MMCSS" -Name "Start" -Type "DWord" -Value "2" -Message "Start MMCSS automatically"
}

function Invoke-PowerTweaks {

    # Disable Power Throttling - removes background throttling overhead
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Type "DWord" -Value "1" -Message "Disable power throttling"

    # Disable energy estimation overhead
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "EnergyEstimationEnabled" -Type "DWord" -Value "0" -Message "Disable energy estimation"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "EventProcessorEnabled" -Type "DWord" -Value "0" -Message "Disable power event processing"

    # Tagged Energy Logging - source https://www.youtube.com/watch?v=5omPOfsJNSo
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\TaggedEnergy" -Name "DisableTaggedEnergyLogging" -Type "DWord" -Value "1" -Message "Disable tagged energy logging"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\TaggedEnergy" -Name "TelemetryMaxApplication" -Type "DWord" -Value "0" -Message "Disable per-app energy telemetry"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\TaggedEnergy" -Name "TelemetryMaxTagPerApplication" -Type "DWord" -Value "0" -Message "Disable per-app energy tagging"
}

function Invoke-SystemResponsivenessTweaks {

    # Set Priority For Programs Instead Of Background Services
    # source - https://youtu.be/bqDMG1ZS-Yw
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Type "DWord" -Value $PRIORITY_SEPARATION -Message "Set foreground process scheduling"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IRQ8Priority" -Type "DWord" -Value "1" -Message "Set IRQ 8 priority"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IRQ16Priority" -Type "DWord" -Value "2" -Message "Set IRQ 16 priority"
}

function Invoke-BootOptimizationTweaks {

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "Startupdelayinmsec" -Type "DWord" -Value "0" -Message "Remove startup app delay"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DelayedDesktopSwitchTimeout" -Type "DWord" -Value "0" -Message "Remove desktop switch delay"
}

function Invoke-SystemMaintenanceTweaks {

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" -Name "MaintenanceDisabled" -Type "DWord" -Value "1" -Message "Disable automatic maintenance"

    # source - https://www.youtube.com/watch?v=5omPOfsJNSo
}

function Invoke-UIResponsivenessTweaks {
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Type "String" -Value "1" -Message "Automatically close unresponsive apps"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Type "String" -Value $HUNG_APP_TIMEOUT_MS -Message "Set unresponsive app timeout to 1 s"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Type "String" -Value $WAIT_KILL_APP_TIMEOUT_MS -Message "Set app shutdown timeout to 2 s"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "LowLevelHooksTimeout" -Type "String" -Value $LOW_LEVEL_HOOKS_TIMEOUT_MS -Message "Set low-level hook timeout to 1 s"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type "String" -Value $MENU_SHOW_DELAY_MS -Message "Remove menu display delay"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Type "String" -Value $WAIT_KILL_SVC_TIMEOUT_MS -Message "Set service shutdown timeout to 2 s"
}

function Invoke-MemoryTweaks {

    # Optional memory behavior; no RAM-size recommendation.
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Type "DWord" -Value "1" -Message "Enable large system cache"
    Add-WinriftSystemAction 'MMAgent.PageCombining' $false 'Disable memory page combining'
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Type "DWord" -Value "1" -Message "Keep pageable kernel and driver code in memory"
}

function Invoke-DirectXTweaks {

    # source - https://youtu.be/itTcqcJxtbo
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_ENABLE_UNSAFE_COMMAND_BUFFER_REUSE" -Type "DWord" -Value "1" -Message "Enable D3D12 command buffer reuse"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_ENABLE_RUNTIME_DRIVER_OPTIMIZATIONS" -Type "DWord" -Value "1" -Message "Enable D3D12 runtime optimizations"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_RESOURCE_ALIGNMENT" -Type "DWord" -Value "1" -Message "Enable D3D12 resource alignment"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D11_MULTITHREADED" -Type "DWord" -Value "1" -Message "Enable D3D11 multithreading"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_MULTITHREADED" -Type "DWord" -Value "1" -Message "Enable D3D12 multithreading"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D11_DEFERRED_CONTEXTS" -Type "DWord" -Value "1" -Message "Enable D3D11 deferred contexts"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_DEFERRED_CONTEXTS" -Type "DWord" -Value "1" -Message "Enable D3D12 deferred contexts"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D11_ALLOW_TILING" -Type "DWord" -Value "1" -Message "Enable D3D11 tiling optimization"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D11_ENABLE_DYNAMIC_CODEGEN" -Type "DWord" -Value "1" -Message "Enable D3D11 dynamic code generation"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_ALLOW_TILING" -Type "DWord" -Value "1" -Message "Enable D3D12 tiling optimization"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_CPU_PAGE_TABLE_ENABLED" -Type "DWord" -Value "1" -Message "Enable D3D12 CPU page table"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_HEAP_SERIALIZATION_ENABLED" -Type "DWord" -Value "1" -Message "Enable D3D12 heap serialization"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_MAP_HEAP_ALLOCATIONS" -Type "DWord" -Value "1" -Message "Enable D3D12 heap allocation mapping"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_RESIDENCY_MANAGEMENT_ENABLED" -Type "DWord" -Value "1" -Message "Enable D3D12 residency management"
}

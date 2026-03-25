. "$PSScriptRoot\..\..\scripts\Common.ps1"
# https://github.com/AlchemyTweaks/Verified-Tweaks
# https://github.com/SanGraphic/QuickBoost
# https://github.com/UnLovedCookie/CoutX
# https://github.com/Snowfliger/SyncOS
# https://github.com/denis-g/windows10-latency-optimization

# Named Constants
# Accessibility flag values (Windows accessibility registry format)
$STICKY_KEYS_DISABLED      = "506"  # StickyKeys off — prevents popup on 5x Shift
$TOGGLE_KEYS_DISABLED      = "58"   # ToggleKeys audio indicator off
$FILTER_KEYS_DISABLED      = "122"  # FilterKeys off with all response optimizations active
# Input buffer sizes (smaller = faster processing, default is 100)
$INPUT_QUEUE_SIZE           = "20"
# Network
$NETWORK_THROTTLING_OFF     = "4294967295"  # 0xFFFFFFFF — disables network throttling
# CPU multimedia scheduler
$LAZY_MODE_TIMEOUT_MS       = "25000"  # 25ms lazy mode timeout for MMCSS
# Process priority — short interval, variable length, high foreground boost (2:1)
$PRIORITY_SEPARATION        = "0x00000024"
# UI timeouts (milliseconds)
$HUNG_APP_TIMEOUT_MS        = "1000"
$WAIT_KILL_APP_TIMEOUT_MS   = "2000"
$LOW_LEVEL_HOOKS_TIMEOUT_MS = "1000"
$MENU_SHOW_DELAY_MS         = "0"
$WAIT_KILL_SVC_TIMEOUT_MS   = "2000"

function Invoke-UniversalTweaks {
    $sessionStarted = $false
    while ($true) {
        Clear-Host
        Show-MenuBox -Title "Select tweak categories to apply" -Items @(
            "1 › System Latency",
            "2 › Input Device Optimization",
            "3 › SSD/NVMe Performance",
            "4 › GPU Hardware Scheduling",
            "5 › Network Optimization",
            "6 › CPU Performance",
            "7 › Power Management",
            "8 › System Responsiveness",
            "9 › Boot Optimization",
            "10 › UI Responsiveness",
            "11 › Memory Optimization",
            "--- Advanced (opt-in, not included in Apply ALL) ---",
            "12 › System Maintenance",
            "13 › DirectX Enhancements",
            "---",
            "A › Apply ALL safe tweaks",
            "B › Back to menu"
        )

        Write-Host ""
        $selection = Read-Host " Select categories (e.g. 1 3 5 or A for all)"

        if ($selection -eq "B" -or $selection -eq "b") { break }

        if (-not $sessionStarted) {
            New-SafeRestorePoint
            Start-TweakSession
            $sessionStarted = $true
        }

        $tweakMap = @{
            "1"  = { Invoke-SystemLatencyTweaks }
            "2"  = { Invoke-InputDeviceTweaks }
            "3"  = { Invoke-SSDTweaks }
            "4"  = { Invoke-GPUTweaks }
            "5"  = { Invoke-NetworkTweaks }
            "6"  = { Invoke-CPUTweaks }
            "7"  = { Invoke-PowerTweaks }
            "8"  = { Invoke-SystemResponsivenessTweaks }
            "9"  = { Invoke-BootOptimizationTweaks }
            "10" = { Invoke-UIResponsivenessTweaks }
            "11" = { Invoke-MemoryTweaks }
            "12" = { Invoke-SystemMaintenanceTweaks }
            "13" = { Invoke-DirectXTweaks }
        }

        $categoryNames = @{
            "1" = "System Latency"; "2" = "Input Device Optimization"; "3" = "SSD/NVMe Performance"
            "4" = "GPU Hardware Scheduling"; "5" = "Network Optimization"; "6" = "CPU Performance"
            "7" = "Power Management"; "8" = "System Responsiveness"; "9" = "Boot Optimization"
            "10" = "UI Responsiveness"; "11" = "Memory Optimization"
            "12" = "System Maintenance"; "13" = "DirectX Enhancements"
        }

        $optInWarnings = @{
            "12" = "This disables Windows automatic maintenance, including disk optimization and security scans."
            "13" = "UNSAFE_COMMAND_BUFFER_REUSE may cause GPU artifacts or crashes on some hardware."
        }

        if ($selection -eq "A" -or $selection -eq "a") {
            $selectedKeys = @("1","2","3","4","5","6","7","8","9","10","11")
        } else {
            $selectedKeys = $selection -split '[,\s]+' | Where-Object { $_ -ne '' }
        }

        $appliedCategories = @()
        $total = ($selectedKeys | Where-Object { $tweakMap.ContainsKey($_) }).Count
        $current = 0

        foreach ($key in $selectedKeys) {
            if ($tweakMap.ContainsKey($key)) {
                $current++
                $catName = $categoryNames[$key]

                if ($optInWarnings.ContainsKey($key)) {
                    Write-Host ""
                    Write-Log -Message "$catName - $($optInWarnings[$key])" -Level WARNING
                    $confirm = Read-Host "  Apply this category? [Y/N]"
                    if ($confirm -ne "Y" -and $confirm -ne "y") {
                        Write-Log -Message "Skipped $catName" -Level SKIP
                        continue
                    }
                }

                $script:DesiredStateCategory = $catName
                Write-Progress -Activity "Applying System Tweaks" `
                    -Status "($current/$total) $catName..." `
                    -PercentComplete ([math]::Round(($current / $total) * 100))
                & $tweakMap[$key]
                $appliedCategories += $key
            } else {
                Write-Log -Message "Unknown option: $key" -Level SKIP
            }
        }

        Write-Progress -Completed -Activity "Applying System Tweaks"

        if ($appliedCategories.Count -gt 0) {
            Write-Host ""
            Write-Log -Message "Tweaks Applied Successfully" -Level SUCCESS
            Write-Host "  Categories applied:"
            foreach ($cat in $appliedCategories) {
                if ($categoryNames.ContainsKey($cat)) {
                    Write-Host "  - $($categoryNames[$cat])"
                }
            }
            Write-Host ""
            Write-Host "$Yellow  A system restart is recommended for all changes to take effect.$Reset"
        } else {
            Write-Host ""
            Write-Log -Message "No tweaks were applied." -Level INFO
        }
        Write-Host ""
        Write-Host "$Purple Press any key to return to the tweaks menu...$Reset"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    if ($sessionStarted) {
        Save-TweakBackup
        Save-DesiredState
        if ($script:LogFile) {
            Write-Host "$Green  Log saved to: $script:LogFile$Reset"
        }
    }
}

function Invoke-SystemLatencyTweaks {
    Write-Host "`nApplying System Latency tweaks...`n"

    # Changing Interrupts behavior for lower latency
    # source - https://youtu.be/Gazv0q3njYU
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "InterruptSteeringDisabled" -Type "DWord" -Value "1" -Message "Disabled interrupt steering for lower latency"

    # Serialize Timer Expiration mechanism, officially documented in Windows Internals 7th E2
    # source - https://youtu.be/wil-09_5H0M
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "SerializeTimerExpiration" -Type "DWord" -Value "1" -Message "Enabled timer serialization for better system timing"
}

function Invoke-InputDeviceTweaks {
    Write-Host "`nApplying Input Device tweaks...`n"

    # MouseDataQueueSize and KeyboardDataQueueSize - smaller buffer = faster processing
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" -Name "MouseDataQueueSize" -Type "DWord" -Value $INPUT_QUEUE_SIZE -Message "Optimized mouse input buffer size"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" -Name "KeyboardDataQueueSize" -Type "DWord" -Value $INPUT_QUEUE_SIZE -Message "Optimized keyboard input buffer size"

    # Accessibility and keyboard response settings
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility" -Name "StickyKeys" -Type "String" -Value $STICKY_KEYS_DISABLED -Message "Disabled StickyKeys for better gaming experience"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Type "String" -Value $TOGGLE_KEYS_DISABLED -Message "Modified ToggleKeys behavior"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "DelayBeforeAcceptance" -Type "String" -Value "0" -Message "Removed keyboard input delay"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "AutoRepeatRate" -Type "String" -Value "0" -Message "Optimized key repeat rate"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "AutoRepeatDelay" -Type "String" -Value "0" -Message "Removed key repeat delay"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Flags" -Type "String" -Value $FILTER_KEYS_DISABLED -Message "Modified keyboard response flags"
}

function Invoke-SSDTweaks {
    Write-Host "`nApplying SSD/NVMe tweaks...`n"

    $hasSSD = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' -or $_.BusType -eq 'NVMe' } | Measure-Object | Select-Object -ExpandProperty Count
    if ($hasSSD -gt 0) {
        try {
            fsutil behavior set DisableDeleteNotify 0 | Out-Null
            Write-Log -Message "Enabled TRIM for SSD" -Level SUCCESS
        } catch {
            Write-Log -Message "Failed to configure TRIM: $($_.Exception.Message)" -Level ERROR
        }

        try {
            Disable-ScheduledTask -TaskName "\Microsoft\Windows\Defrag\ScheduledDefrag" | Out-Null
            Write-Log -Message "Disabled defragmentation for SSDs" -Level SUCCESS
        } catch {
            Write-Log -Message "Failed to disable defrag task: $($_.Exception.Message)" -Level ERROR
        }

        try {
            fsutil behavior set disablelastaccess 1 | Out-Null
            Write-Log -Message "Disabled NTFS last access time updates" -Level SUCCESS
        } catch {
            Write-Log -Message "Failed to configure last access time: $($_.Exception.Message)" -Level ERROR
        }

        Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisable8dot3NameCreation" -Type "DWord" -Value "1" -Message "Disabled legacy 8.3 filename creation for better SSD performance"

        # Disable ApplicationPreLaunch & Prefetch - not needed on SSD
        try {
            Disable-MMAgent -ApplicationPreLaunch
            Write-Log -Message "Disabled application pre-launch" -Level SUCCESS
        } catch {
            Write-Log -Message "Failed to disable ApplicationPreLaunch: $($_.Exception.Message)" -Level WARNING
        }

        Set-RegistryValue -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Type "DWord" -Value "0" -Message "Disabled prefetcher for better SSD performance"
        Set-RegistryValue -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "SfTracingState" -Type "DWord" -Value "0" -Message "Disabled superfetch tracing"
    } else {
        Write-Host "No SSD or NVMe detected. Skipping tweaks."
    }
}

function Invoke-GPUTweaks {
    Write-Host "`nApplying GPU Performance tweaks...`n"

    # HwSchMode - Hardware Accelerated GPU Scheduling, reduces latency
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Type "DWord" -Value "2" -Message "Optimized GPU hardware scheduling"
    Set-RegistryValue -Path "HKLM:\SYSTEM\ControlSet001\Control\GraphicsDrivers\Scheduler" -Name "EnablePreemption" -Type "DWord" -Value "0" -Message "Disabled GPU preemption for better performance"
}

function Invoke-NetworkTweaks {
    Write-Host "`nApplying Network tweaks...`n"

    # Disable network throttling - especially helpful with gigabit networks
    # source - https://youtu.be/EmdosMT5TtA
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Type "DWord" -Value $NETWORK_THROTTLING_OFF -Message "Disabled network throttling for maximum network performance"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NoLazyMode" -Type "DWord" -Value "1" -Message "Disabled lazy mode for network operations"
}

function Invoke-CPUTweaks {
    Write-Host "`nApplying CPU Performance tweaks...`n"

    # source - https://youtu.be/FxpRL7wheGc
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "LazyModeTimeout" -Type "DWord" -Value $LAZY_MODE_TIMEOUT_MS -Message "Set optimal lazy mode timeout for better CPU responsiveness"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\MMCSS" -Name "Start" -Type "DWord" -Value "2" -Message "Configured Multimedia Class Scheduler Service for better performance"
}

function Invoke-PowerTweaks {
    Write-Host "`nApplying Power Management tweaks...`n"

    # Disable Power Throttling - removes background throttling overhead
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Type "DWord" -Value "1" -Message "Disabled power throttling for maximum performance"

    # Disable energy estimation overhead
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "EnergyEstimationEnabled" -Type "DWord" -Value "0" -Message "Disabled energy estimation for better performance"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "EventProcessorEnabled" -Type "DWord" -Value "0" -Message "Disabled power event processor"

    # Tagged Energy Logging - source https://www.youtube.com/watch?v=5omPOfsJNSo
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\TaggedEnergy" -Name "DisableTaggedEnergyLogging" -Type "DWord" -Value "1" -Message "Disabled tagged energy logging"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\TaggedEnergy" -Name "TelemetryMaxApplication" -Type "DWord" -Value "0" -Message "Disabled energy telemetry per application"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\TaggedEnergy" -Name "TelemetryMaxTagPerApplication" -Type "DWord" -Value "0" -Message "Disabled energy tagging per application"
}

function Invoke-SystemResponsivenessTweaks {
    Write-Host "`nApplying System Responsiveness tweaks...`n"

    # Set Priority For Programs Instead Of Background Services
    # source - https://youtu.be/bqDMG1ZS-Yw
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Type "DWord" -Value $PRIORITY_SEPARATION -Message "Optimized process priority for better responsiveness"
    Set-RegistryValue -Path "HKLM:\SYSTEM\ControlSet001\Control\PriorityControl" -Name "IRQ8Priority" -Type "DWord" -Value "1" -Message "Set IRQ8 priority for better system response"
    Set-RegistryValue -Path "HKLM:\SYSTEM\ControlSet001\Control\PriorityControl" -Name "IRQ16Priority" -Type "DWord" -Value "2" -Message "Set IRQ16 priority for better system response"
}

function Invoke-BootOptimizationTweaks {
    Write-Host "`nApplying Boot Optimization tweaks...`n"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "Startupdelayinmsec" -Type "DWord" -Value "0" -Message "Removed startup delay for faster boot"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DelayedDesktopSwitchTimeout" -Type "DWord" -Value "0" -Message "Removed desktop switch delay"
}

function Invoke-SystemMaintenanceTweaks {
    Write-Host "`nApplying System Maintenance tweaks...`n"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" -Name "MaintenanceDisabled" -Type "DWord" -Value "1" -Message "Disabled automatic maintenance for better performance"

    # source - https://www.youtube.com/watch?v=5omPOfsJNSo
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\I/O System" -Name "CountOperations" -Type "DWord" -Value "0" -Message "Disabled I/O operation counting"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\fssProv" -Name "EncryptProtocol" -Type "DWord" -Value "0" -Message "Disabled FSS provider encryption"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule" -Name "DisableRpcOver" -Type "DWord" -Value "1" -Message "Disabled RPC over Scheduler"
}

function Invoke-UIResponsivenessTweaks {
    Write-Host "`nApplying UI Responsiveness tweaks...`n"
    Write-Log -Message "WARNING: AutoEndTasks will force-close unresponsive apps after ${WAIT_KILL_APP_TIMEOUT_MS}ms. Unsaved work may be lost." -Level WARNING

    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Type "String" -Value "1" -Message "Enabled automatic ending of tasks"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Type "String" -Value $HUNG_APP_TIMEOUT_MS -Message "Reduced hung application timeout"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Type "String" -Value $WAIT_KILL_APP_TIMEOUT_MS -Message "Reduced wait time for killing applications"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "LowLevelHooksTimeout" -Type "String" -Value $LOW_LEVEL_HOOKS_TIMEOUT_MS -Message "Reduced low level hooks timeout"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type "String" -Value $MENU_SHOW_DELAY_MS -Message "Removed menu show delay"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Type "String" -Value $WAIT_KILL_SVC_TIMEOUT_MS -Message "Reduced wait time for killing services"
}

function Invoke-MemoryTweaks {
    Write-Host "`nApplying Memory Optimization tweaks...`n"

    $totalRamGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0)
    if ($totalRamGB -lt 16) {
        Write-Log -Message "WARNING: Your system has ${totalRamGB}GB RAM. DisablePagingExecutive and LargeSystemCache are risky on systems with less than 16GB and may cause instability under load." -Level WARNING
    }

    # source - https://github.com/SanGraphic/QuickBoost/blob/main/v2/MemoryTweaks.bat
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Type "DWord" -Value "1" -Message "Enabled large system cache for better performance"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingCombining" -Type "DWord" -Value "1" -Message "Disabled memory page combining"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Type "DWord" -Value "1" -Message "Disabled paging of kernel and drivers"
}

function Invoke-DirectXTweaks {
    Write-Host "`nApplying DirectX tweaks...`n"

    # source - https://youtu.be/itTcqcJxtbo
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_ENABLE_UNSAFE_COMMAND_BUFFER_REUSE" -Type "DWord" -Value "1" -Message "Enabled D3D12 command buffer reuse"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_ENABLE_RUNTIME_DRIVER_OPTIMIZATIONS" -Type "DWord" -Value "1" -Message "Enabled D3D12 runtime optimizations"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_RESOURCE_ALIGNMENT" -Type "DWord" -Value "1" -Message "Optimized D3D12 resource alignment"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D11_MULTITHREADED" -Type "DWord" -Value "1" -Message "Enabled D3D11 multithreading"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_MULTITHREADED" -Type "DWord" -Value "1" -Message "Enabled D3D12 multithreading"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D11_DEFERRED_CONTEXTS" -Type "DWord" -Value "1" -Message "Enabled D3D11 deferred contexts"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_DEFERRED_CONTEXTS" -Type "DWord" -Value "1" -Message "Enabled D3D12 deferred contexts"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D11_ALLOW_TILING" -Type "DWord" -Value "1" -Message "Enabled D3D11 tiling optimization"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D11_ENABLE_DYNAMIC_CODEGEN" -Type "DWord" -Value "1" -Message "Enabled D3D11 dynamic code generation"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_ALLOW_TILING" -Type "DWord" -Value "1" -Message "Enabled D3D12 tiling optimization"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_CPU_PAGE_TABLE_ENABLED" -Type "DWord" -Value "1" -Message "Enabled D3D12 CPU page table"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_HEAP_SERIALIZATION_ENABLED" -Type "DWord" -Value "1" -Message "Enabled D3D12 heap serialization"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_MAP_HEAP_ALLOCATIONS" -Type "DWord" -Value "1" -Message "Enabled D3D12 heap allocation mapping"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_RESIDENCY_MANAGEMENT_ENABLED" -Type "DWord" -Value "1" -Message "Enabled D3D12 residency management"
}

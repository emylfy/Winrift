. "$PSScriptRoot\..\..\scripts\Common.ps1"
# https://github.com/SysadminWorld/Win11Tweaks
# https://github.com/AlchemyTweaks/Verified-Tweaks
# https://github.com/SanGraphic/QuickBoost
# https://github.com/UnLovedCookie/CoutX
# https://github.com/Snowfliger/SyncOS
# https://github.com/denis-g/windows10-latency-optimization

function Invoke-UniversalTweaks {
    while ($true) {
        Clear-Host
        Show-MenuBox -Title "Select tweak categories to apply" -Items @(
            "[1]  System Latency",
            "[2]  Input Device Optimization",
            "[3]  SSD/NVMe Performance",
            "[4]  GPU Hardware Scheduling",
            "[5]  Network Optimization",
            "[6]  CPU Performance",
            "[7]  Power Management",
            "[8]  System Responsiveness",
            "[9]  Boot Optimization",
            "[10] System Maintenance",
            "[11] UI Responsiveness",
            "[12] Memory Optimization",
            "[13] DirectX Enhancements",
            "---",
            "[A]  Apply ALL tweaks",
            "[B]  Back to menu"
        )

        Write-Host ""
        Write-Host "$Yellow Enter numbers separated by commas (e.g. 1,3,5) or A for all:$Reset"
        $selection = Read-Host ">"

        if ($selection -eq "B" -or $selection -eq "b") { return }

        New-SafeRestorePoint

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
            "10" = { Invoke-SystemMaintenanceTweaks }
            "11" = { Invoke-UIResponsivenessTweaks }
            "12" = { Invoke-MemoryTweaks }
            "13" = { Invoke-DirectXTweaks }
        }

        $categoryNames = @{
            "1" = "System Latency"; "2" = "Input Device Optimization"; "3" = "SSD/NVMe Performance"
            "4" = "GPU Hardware Scheduling"; "5" = "Network Optimization"; "6" = "CPU Performance"
            "7" = "Power Management"; "8" = "System Responsiveness"; "9" = "Boot Optimization"
            "10" = "System Maintenance"; "11" = "UI Responsiveness"; "12" = "Memory Optimization"
            "13" = "DirectX Enhancements"
        }

        if ($selection -eq "A" -or $selection -eq "a") {
            $selectedKeys = @("1","2","3","4","5","6","7","8","9","10","11","12","13")
        } else {
            $selectedKeys = $selection -split ',' | ForEach-Object { $_.Trim() }
        }

        $appliedCategories = @()
        $total = ($selectedKeys | Where-Object { $tweakMap.ContainsKey($_) }).Count
        $current = 0

        foreach ($key in $selectedKeys) {
            if ($tweakMap.ContainsKey($key)) {
                $current++
                $catName = $categoryNames[$key]
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

        Write-Host ""
        Write-Host "$Green +---------------------------------------------+$Reset"
        Write-Host "$Green |          Tweaks Applied Successfully         |$Reset"
        Write-Host "$Green +---------------------------------------------+$Reset"
        Write-Host "$Reset  Categories applied:"
        foreach ($cat in $appliedCategories) {
            if ($categoryNames.ContainsKey($cat)) {
                Write-Host "$Reset  - $($categoryNames[$cat])"
            }
        }
        Write-Host ""
        Write-Host "$Yellow  A system restart is recommended for all changes to take effect.$Reset"
        if ($script:LogFile) {
            Write-Host "$Green  Log saved to: $script:LogFile$Reset"
        }
        Write-Host ""
        Write-Host "`n$Purple Press any key to return to the tweaks menu...$Reset"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
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
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" -Name "MouseDataQueueSize" -Type "DWord" -Value "20" -Message "Optimized mouse input buffer size"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" -Name "KeyboardDataQueueSize" -Type "DWord" -Value "20" -Message "Optimized keyboard input buffer size"

    # Accessibility and keyboard response settings
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility" -Name "StickyKeys" -Type "String" -Value "506" -Message "Disabled StickyKeys for better gaming experience"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Type "String" -Value "58" -Message "Modified ToggleKeys behavior"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "DelayBeforeAcceptance" -Type "String" -Value "0" -Message "Removed keyboard input delay"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "AutoRepeatRate" -Type "String" -Value "0" -Message "Optimized key repeat rate"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "AutoRepeatDelay" -Type "String" -Value "0" -Message "Removed key repeat delay"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Flags" -Type "String" -Value "122" -Message "Modified keyboard response flags"
}

function Invoke-SSDTweaks {
    Write-Host "`nApplying SSD/NVMe tweaks...`n"

    $hasSSD = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' -or $_.BusType -eq 'NVMe' } | Measure-Object | Select-Object -ExpandProperty Count
    if ($hasSSD -gt 0) {
        Write-Host "Enable and optimize TRIM for SSD"
        fsutil behavior set DisableDeleteNotify 0

        Write-Host "Disable defragmentation for SSDs"
        Disable-ScheduledTask -TaskName "\Microsoft\Windows\Defrag\ScheduledDefrag"

        Write-Host "Disable NTFS last access time updates"
        fsutil behavior set disablelastaccess 1

        Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisable8dot3NameCreation" -Type "DWord" -Value "1" -Message "Disabled legacy 8.3 filename creation for better SSD performance"

        # Disable ApplicationPreLaunch & Prefetch - not needed on SSD
        Disable-MMAgent -ApplicationPreLaunch

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
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Type "DWord" -Value "4294967295" -Message "Disabled network throttling for maximum network performance"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NoLazyMode" -Type "DWord" -Value "1" -Message "Disabled lazy mode for network operations"
}

function Invoke-CPUTweaks {
    Write-Host "`nApplying CPU Performance tweaks...`n"

    # source - https://youtu.be/FxpRL7wheGc
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "LazyModeTimeout" -Type "DWord" -Value "25000" -Message "Set optimal lazy mode timeout for better CPU responsiveness"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\MMCSS" -Name "Start" -Type "DWord" -Value "2" -Message "Configured Multimedia Class Scheduler Service for better performance"
}

function Invoke-PowerTweaks {
    Write-Host "`nApplying Power Management tweaks...`n"

    # Disable Power Throttling - unnecessary, especially for desktops
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Type "DWord" -Value "1" -Message "Disabled power throttling for maximum performance"

    # source - https://github.com/ancel1x/Ancels-Performance-Batch
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PlatformAoAcOverride" -Type "DWord" -Value "0" -Message "Disabled AC/DC platform power behavior override"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "EnergyEstimationEnabled" -Type "DWord" -Value "0" -Message "Disabled energy estimation for better performance"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "EventProcessorEnabled" -Type "DWord" -Value "0" -Message "Disabled power event processor"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "CsEnabled" -Type "DWord" -Value "0" -Message "Disabled connected standby for better performance"

    # Tagged Energy Logging - source https://www.youtube.com/watch?v=5omPOfsJNSo
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\TaggedEnergy" -Name "DisableTaggedEnergyLogging" -Type "DWord" -Value "1" -Message "Disabled tagged energy logging"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\TaggedEnergy" -Name "TelemetryMaxApplication" -Type "DWord" -Value "0" -Message "Disabled energy telemetry per application"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\TaggedEnergy" -Name "TelemetryMaxTagPerApplication" -Type "DWord" -Value "0" -Message "Disabled energy tagging per application"

    # CPU Throttling - prevents idle C-states
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Throttle" -Name "PerfEnablePackageIdle" -Type "DWord" -Value "0" -Message "Disabled CPU package idle states"

    # Processor Power Management
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Processor" -Name "CPPCEnable" -Type "DWord" -Value "0" -Message "Disabled Collaborative Processor Performance Control"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Processor" -Name "AllowPepPerfStates" -Type "DWord" -Value "0" -Message "Disabled Platform Energy Provider performance states"

    # PCIe Power Saving (ASPM)
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\pci\Parameters" -Name "ASPMOptOut" -Type "DWord" -Value "1" -Message "Disabled PCIe ASPM power saving"

    # Activate Hidden Ultimate Performance Power Plan
    Write-Host "Activating Ultimate Performance Power Plan"
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee
    powercfg -setactive eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee
}

function Invoke-SystemResponsivenessTweaks {
    Write-Host "`nApplying System Responsiveness tweaks...`n"

    # Set Priority For Programs Instead Of Background Services
    # source - https://youtu.be/bqDMG1ZS-Yw
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Type "DWord" -Value "0x00000024" -Message "Optimized process priority for better responsiveness"
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

    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Type "String" -Value "1" -Message "Enabled automatic ending of tasks"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Type "String" -Value "1000" -Message "Reduced hung application timeout"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Type "String" -Value "2000" -Message "Reduced wait time for killing applications"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "LowLevelHooksTimeout" -Type "String" -Value "1000" -Message "Reduced low level hooks timeout"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type "String" -Value "0" -Message "Removed menu show delay"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Type "String" -Value "2000" -Message "Reduced wait time for killing services"
}

function Invoke-MemoryTweaks {
    Write-Host "`nApplying Memory Optimization tweaks...`n"

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

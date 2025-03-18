@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (
    echo Not running as admin. Elevating...
    where wt.exe >nul 2>&1
    if %errorlevel% equ 0 (
        powershell "Start-Process -FilePath 'wt.exe' -ArgumentList 'cmd /k \"%~0\"' -Verb runAs"
    ) else (
        powershell "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k \"%~0\"' -Verb runAs"
    )
    exit /b
)

set Purple=[38;5;141m
set Grey=[38;5;250m
set Reset=[0m
set Red=[38;5;203m
set Green=[38;5;120m

:universalTweaks
:: Changing Interrupts behavior for lower latency
: source - https://youtu.be/Gazv0q3njYU
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "InterruptSteeringDisabled" "REG_DWORD" "1" "Disabled interrupt steering for lower latency"

:: Mouse & Keyboard Tweaks

:: These settings disable Enhance Pointer Precision, which increases pointer speed with mouse speed
:: This can be useful generally, but it causes cursor issues in games
:: It's recommended to disable this for gaming
call :reg "HKCU\Control Panel\Mouse" "MouseSpeed" "REG_SZ" "0" "Disabled Enhanced Pointer Precision"
call :reg "HKCU\Control Panel\Mouse" "MouseThreshold1" "REG_SZ" "0" "Removed mouse acceleration threshold 1"
call :reg "HKCU\Control Panel\Mouse" "MouseThreshold2" "REG_SZ" "0" "Removed mouse acceleration threshold 2"

:: The MouseDataQueueSize and KeyboardDataQueueSize parameters set the number of events stored in the mouse and keyboard driver buffers
:: A smaller value means faster processing of new information
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" "MouseDataQueueSize" "REG_DWORD" "20" "Optimized mouse input buffer size"
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" "KeyboardDataQueueSize" "REG_DWORD" "20" "Optimized keyboard input buffer size"

:: Accessibility and keyboard response settings
call :reg "HKCU\Control Panel\Accessibility" "StickyKeys" "REG_SZ" "506" "Disabled StickyKeys for better gaming experience"
call :reg "HKCU\Control Panel\Accessibility\ToggleKeys" "Flags" "REG_SZ" "58" "Modified ToggleKeys behavior"
call :reg "HKCU\Control Panel\Accessibility\Keyboard Response" "DelayBeforeAcceptance" "REG_SZ" "0" "Removed keyboard input delay"
call :reg "HKCU\Control Panel\Accessibility\Keyboard Response" "AutoRepeatRate" "REG_SZ" "0" "Optimized key repeat rate"
call :reg "HKCU\Control Panel\Accessibility\Keyboard Response" "AutoRepeatDelay" "REG_SZ" "0" "Removed key repeat delay"
call :reg "HKCU\Control Panel\Accessibility\Keyboard Response" "Flags" "REG_SZ" "122" "Modified keyboard response flags"

:: SSD/NVMe Tweaks
powershell "Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' -or $_.BusType -eq 'NVMe' } | Measure-Object | ForEach-Object { if ($_.Count -gt 0) { exit 0 } else { exit 1 } }"
if %errorlevel% equ 0 (
    echo Enable and optimize TRIM for SSD
    fsutil behavior set DisableDeleteNotify 0

    echo Disable defragmentation for SSDs
    schtasks /Change /TN "\Microsoft\Windows\Defrag\ScheduledDefrag" /Disable
		
    echo Disable NTFS last access time updates
    fsutil behavior set disablelastaccess 1
    call :reg "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsDisable8dot3NameCreation" "REG_DWORD" "1" "Disabled legacy 8.3 filename creation for better SSD performance"
) else (
    echo No SSD or NVMe detected. Skipping tweaks.
)

:: GPU Performance Tweaks
:: The HwSchMode parameter optimizes hardware-level computation scheduling (Hardware Accelerated GPU Scheduling), reducing latency on lower-end GPUs.
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" "REG_DWORD" "2" "Optimized GPU hardware scheduling"
call :reg "HKLM\SYSTEM\ControlSet001\Control\GraphicsDrivers\Scheduler" "EnablePreemption" "REG_DWORD" "0" "Disabled GPU preemption for better performance"

:: Network Optimization

:: By default, Windows uses network throttling to limit non-multimedia traffic to 10 packets per millisecond (about 100 Mb/s).
:: This is to prioritize CPU access for multimedia applications, as processing network packets can be resource-intensive.
:: However, it's recommended to disable this setting, especially with gigabit networks, to avoid unnecessary interference.
: source - https://youtu.be/EmdosMT5TtA

call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" "REG_DWORD" "4294967295" "Disabled network throttling for maximum network performance"
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NoLazyMode" "REG_DWORD" "1" "Disabled lazy mode for network operations"

:: CPU Tweaks

:: LazyMode is a software flag that allows the system to skip some hardware events when CPU load is low.
:: Disabling it can use more resources for event processing, so we set the timer to a minimum of 1ms (10000ms).
: source - https://youtu.be/FxpRL7wheGc
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "LazyModeTimeout" "REG_DWORD" "25000" "Set optimal lazy mode timeout for better CPU responsiveness"
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\MMCSS" "Start" "REG_DWORD" "2" "Configured Multimedia Class Scheduler Service for better performance"

:: Power Tweaks

:: Power Throttling is a service that slows down background apps to save energy on laptops.
:: In this case, it's unnecessary, so it's recommended to disable it.
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" "REG_DWORD" "1" "Disabled power throttling for maximum performance"

: source - https://github.com/ancel1x/Ancels-Performance-Batch
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Power" "PlatformAoAcOverride" "REG_DWORD" "0" "Disabled AC/DC platform power behavior override"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Power" "EnergyEstimationEnabled" "REG_DWORD" "0" "Disabled energy estimation for better performance"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Power" "EventProcessorEnabled" "REG_DWORD" "0" "Disabled power event processor"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Power" "CsEnabled" "REG_DWORD" "0" "Disabled connected standby for better performance"

:: Activate Hidden Ultimate Performance Power Plan
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee
powercfg -setactive eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee
echo.

:: Other Tweaks

:: Specify priority for services (drivers) to handle interrupts first.
:: Windows uses IRQL to determine interrupt priority. If an interrupt can be serviced, it starts execution.
:: Lower priority tasks are queued. This ensures critical services are prioritized for interrupts.
call :reg "HKLM\SYSTEM\CurrentControlSet\services\DXGKrnl\Parameters" "ThreadPriority" "REG_DWORD" "15" "Set high priority for DirectX kernel services"
call :reg "HKLM\SYSTEM\CurrentControlSet\services\USBHUB3\Parameters" "ThreadPriority" "REG_DWORD" "15" "Set high priority for USB 3.0 hub services"
call :reg "HKLM\SYSTEM\CurrentControlSet\services\USBXHCI\Parameters" "ThreadPriority" "REG_DWORD" "15" "Set high priority for USB XHCI services"
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" "ThreadPriority" "REG_DWORD" "31" "Set maximum priority for mouse input"
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" "ThreadPriority" "REG_DWORD" "31" "Set maximum priority for keyboard input"

:: Set Priority For Programs Instead Of Background Services
:: This improves responsiveness of foreground applications
: source - https://youtu.be/bqDMG1ZS-Yw
call :reg "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" "REG_DWORD" "0x00000024" "Optimized process priority for better responsiveness"
call :reg "HKLM\SYSTEM\ControlSet001\Control\PriorityControl" "IRQ8Priority" "REG_DWORD" "1" "Set IRQ8 priority for better system response"
call :reg "HKLM\SYSTEM\ControlSet001\Control\PriorityControl" "IRQ16Priority" "REG_DWORD" "2" "Set IRQ16 priority for better system response"

:: Boot System & Software without limits
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "Startupdelayinmsec" "REG_DWORD" "0" "Removed startup delay for faster boot"

:: Disable Automatic maintenance
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" "MaintenanceDisabled" "REG_DWORD" "1" "Disabled automatic maintenance for better performance"

:: Speed up start time
call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DelayedDesktopSwitchTimeout" "REG_DWORD" "0" "Removed desktop switch delay"

:: Disable ApplicationPreLaunch & Prefetch
:: The outdated Prefetcher and Superfetch services run in the background, analyzing loaded apps/libraries/services.
:: They cache repeated data to disk and then to RAM, speeding up app launches.
:: However, with an SSD, apps load quickly without this, so constant disk caching is unnecessary.
powershell Disable-MMAgent -ApplicationPreLaunch
call :reg "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" "REG_DWORD" "0" "Disabled prefetcher for better SSD performance"
call :reg "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "SfTracingState" "REG_DWORD" "0" "Disabled superfetch tracing"

:: Reducing time of disabling processes and menu
call :reg "HKCU\Control Panel\Desktop" "AutoEndTasks" "REG_SZ" "1" "Enabled automatic ending of tasks"
call :reg "HKCU\Control Panel\Desktop" "HungAppTimeout" "REG_SZ" "1000" "Reduced hung application timeout"
call :reg "HKCU\Control Panel\Desktop" "WaitToKillAppTimeout" "REG_SZ" "2000" "Reduced wait time for killing applications"
call :reg "HKCU\Control Panel\Desktop" "LowLevelHooksTimeout" "REG_SZ" "1000" "Reduced low level hooks timeout"
call :reg "HKCU\Control Panel\Desktop" "MenuShowDelay" "REG_SZ" "0" "Removed menu show delay"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control" "WaitToKillServiceTimeout" "REG_SZ" "2000" "Reduced wait time for killing services"

:: Memory Tweaks
: source - https://github.com/SanGraphic/QuickBoost/blob/main/v2/MemoryTweaks.bat

:: Enabling Large System Cache makes the OS use all RAM for caching system files,
:: except 4MB reserved for disk cache, improving Windows responsiveness.
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" "REG_DWORD" "1" "Enabled large system cache for better performance"
:: Disabling Windows attempt to save as much RAM as possible, such as sharing pages for images, copy-on-write for data pages, and compression
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingCombining" "REG_DWORD" "1" "Disabled memory page combining"
:: Enabling this parameter keeps the system kernel and drivers in RAM instead of the page file, improving responsiveness.
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" "REG_DWORD" "1" "Disabled paging of kernel and drivers"

:: Optimizations for DirectX graphics performance
: source - https://youtu.be/itTcqcJxtbo
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D12_ENABLE_UNSAFE_COMMAND_BUFFER_REUSE" "REG_DWORD" "1" "Enabled D3D12 command buffer reuse"
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D12_ENABLE_RUNTIME_DRIVER_OPTIMIZATIONS" "REG_DWORD" "1" "Enabled D3D12 runtime optimizations"
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D12_RESOURCE_ALIGNMENT" "REG_DWORD" "1" "Optimized D3D12 resource alignment"
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D11_MULTITHREADED" "REG_DWORD" "1" "Enabled D3D11 multithreading"
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D12_MULTITHREADED" "REG_DWORD" "1" "Enabled D3D12 multithreading"
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D11_DEFERRED_CONTEXTS" "REG_DWORD" "1" "Enabled D3D11 deferred contexts"
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D12_DEFERRED_CONTEXTS" "REG_DWORD" "1" "Enabled D3D12 deferred contexts"
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D11_ALLOW_TILING" "REG_DWORD" "1" "Enabled D3D11 tiling optimization"
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D11_ENABLE_DYNAMIC_CODEGEN" "REG_DWORD" "1" "Enabled D3D11 dynamic code generation"
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D12_ALLOW_TILING" "REG_DWORD" "1" "Enabled D3D12 tiling optimization"
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D12_CPU_PAGE_TABLE_ENABLED" "REG_DWORD" "1" "Enabled D3D12 CPU page table"
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D12_HEAP_SERIALIZATION_ENABLED" "REG_DWORD" "1" "Enabled D3D12 heap serialization"
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D12_MAP_HEAP_ALLOCATIONS" "REG_DWORD" "1" "Enabled D3D12 heap allocation mapping"
call :reg "HKLM\SOFTWARE\Microsoft\DirectX" "D3D12_RESIDENCY_MANAGEMENT_ENABLED" "REG_DWORD" "1" "Enabled D3D12 residency management"

:: Serialize Timer Expiration mechanism, officially documented in Windows Internals 7th E2
:: Improves system timing and interrupt handling
: source - https://youtu.be/wil-09_5H0M
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "SerializeTimerExpiration" "REG_DWORD" "1" "Enabled timer serialization for better system timing"

pause
exit

:reg
call "%~dp0\..\reg_helper.bat" %*
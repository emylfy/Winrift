@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (powershell start -verb runas '%~0' & exit)

:: Define colors
set cRosewater=[38;5;224m
set cFlamingo=[38;5;210m
set cMauve=[38;5;141m
set cRed=[38;5;203m
set cGreen=[38;5;120m
set cTeal=[38;5;116m
set cSky=[38;5;111m
set cSapphire=[38;5;69m
set cBlue=[38;5;75m
set cGrey=[38;5;250m
set cReset=[0m

:main
title Simplify11
cls
echo.
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cMauve%  Tired of System Setup After Reinstall? Simplify It!    %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Apply Performance Tweaks                           %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Free Up Space                                      %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] WinUtil - Install Programs, Tweaks and Fixes       %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] Privacy.Sexy - Tool to enforce privacy in clicks   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [5] Install programs without browser                   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [6] Visit PC/Laptop Manufacturers (Soft and drivers)   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [7] System settings and Customization stuff            %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
choice /C 1234567 /N /M ">"
set /a "menuChoice=!errorlevel!"
goto s!menuChoice!

:s1
call :applyTweaks

:s2
call :freeUpSpace

:s3
call :launchWinUtil

:s4
call :launchPrivacySexy

:s5
call :wingetInstall

:s6
call :deviceMenu

:s7
call :coolStuff

:applyTweaks
cls
echo.
echo %cMauve% +-----------------------------------+%cReset%
echo %cMauve% '%cGrey% Storage Device Selection          %cMauve%'%cReset%
echo %cMauve% +-----------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] SSD/NVMe                      %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] HDD                           %cMauve%'%cReset%
echo %cMauve% +-----------------------------------+%cReset%
choice /C 12 /N /M ">"
set /a "storageChoice=!errorlevel!"

if !storageChoice! equ 2 (
    echo %cGrey%HDD selected - Applying optimizations...%cReset%
    :: No specific optimizations needed for HDD
    goto checkLaptop
) else (
    echo %cGreen%SSD/NVMe selected - Applying optimizations...%cReset%
    :: Enable and optimize TRIM for SSD
    fsutil behavior set DisableDeleteNotify 0
    :: Disable defragmentation for SSDs
    schtasks /Change /TN "\Microsoft\Windows\Defrag\ScheduledDefrag" /Disable
    :: Disable NTFS last access time updates
    fsutil behavior set disablelastaccess 1
    call :reg "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsDisable8dot3NameCreation" "REG_DWORD" "1" "Disabled legacy 8.3 filename creation for better SSD performance"
    goto checkLaptop
)

:checkLaptop
set "isLaptop=false"
for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-CimInstance -ClassName Win32_SystemEnclosure | ForEach-Object { $_.ChassisTypes }"') do (
    if "%%i"=="8" set "isLaptop=true"
    if "%%i"=="9" set "isLaptop=true"
    if "%%i"=="10" set "isLaptop=true"
    if "%%i"=="14" set "isLaptop=true"
    if "%%i"=="30" set "isLaptop=true"
)

if "%isLaptop%"=="false" (
    call :applyPowerIntensiveTweaks
)

if "%isLaptop%"=="true" (
    echo.
    echo %cMauve% +-----------------------------------------------------+%cReset%
    echo %cMauve% '%cGrey% Power Management - Max Pending Interrupts           %cMauve%'%cReset%
    echo %cMauve% +-----------------------------------------------------+%cReset%
    echo %cMauve% '%cGrey% Do you want to apply tweaks that will use           %cMauve%'%cReset%
    echo %cMauve% '%cGrey% maximum power and can drain the battery faster?     %cMauve%'%cReset%
    echo %cMauve% +-----------------------------------------------------+%cReset%
    choice /C 12 /N /M "[1] Yes [2] No: "
    set "laptop_power_choice=%errorlevel%"
    if !laptop_power_choice! equ 2 (
    echo Skipping...
    timeout /t 2
    goto mainTweaks
    )
    if !laptop_power_choice! equ 1 goto applyPowerIntensiveTweaks
)

:applyPowerIntensiveTweaks
:: Created by Kizzimo
: source - https://github.com/AlchemyTweaks/Verified-Tweaks/blob/main/Max%20Pending%20Interrupts%20

:: CPU Performance Tuning
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "CPU_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Optimized CPU interrupt handling for lower latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "CPU_MAX_PENDING_IO" "REG_SZ" "0" "Minimized I/O pending operations for better responsiveness"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "CPU_IDLE_POLICY" "REG_SZ" "0" "Disabled CPU idling for maximum performance"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "CPU_BOOST_POLICY" "REG_SZ" "2" "Enabled aggressive CPU boost for better performance"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "CPU_MAX_FREQUENCY" "REG_SZ" "100" "Set maximum CPU frequency for optimal performance"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "CPU_INTERRUPT_BALANCE_POLICY" "REG_SZ" "1" "Enabled balanced interrupt distribution across cores"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "MKL_DEBUG_CPU_TYPE" "REG_SZ" "10" "Optimized CPU debugging settings"

:: I/O Performance Tuning
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "IO_COMPLETION_POLICY" "REG_SZ" "0" "Set immediate I/O completion for lower latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "IO_REQUEST_LIMIT" "REG_SZ" "1024" "Increased I/O request limit for better throughput"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "DISK_MAX_PENDING_IO" "REG_SZ" "0" "Minimized pending disk I/O operations"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "IO_PRIORITY" "REG_SZ" "0" "Set highest I/O priority for better performance"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "MKL_DEBUG_CPU_TYPE" "REG_SZ" "10" "Optimized CPU debugging settings"

:: I/O Performance Tuning
:: Optimizations for system I/O operations and disk access
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "IO_COMPLETION_POLICY" "REG_SZ" "0" "Set immediate I/O completion for lower latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "IO_REQUEST_LIMIT" "REG_SZ" "1024" "Increased I/O request limit for better throughput"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "DISK_MAX_PENDING_IO" "REG_SZ" "0" "Minimized pending disk I/O operations"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "IO_PRIORITY" "REG_SZ" "0" "Set highest I/O priority for better performance"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "DISK_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled disk interrupt queuing"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "IO_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled I/O interrupt queuing"

:: Power Management and Performance
:: Optimizations for maximum CPU and system performance
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "POWER_THROTTLE_POLICY" "REG_SZ" "0" "Disabled power throttling for maximum performance"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "POWER_IDLE_TIMEOUT" "REG_SZ" "0" "Disabled idle timeout for continuous performance"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "CPU_POWER_POLICY" "REG_SZ" "1" "Set high-performance CPU power policy"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "DISABLE_DYNAMIC_TICK" "REG_SZ" "yes" "Disabled dynamic tick for consistent performance"

:: Memory and Latency Tuning
:: Optimizations for memory performance and access speed
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "MEMORY_MAX_ALLOCATION" "REG_SZ" "0" "Optimized memory allocation for faster access"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "MEMORY_LATENCY_POLICY" "REG_SZ" "0" "Set aggressive memory latency policy"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "MEMORY_PREFETCH_POLICY" "REG_SZ" "2" "Enabled aggressive memory prefetching"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "MEMORY_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled memory interrupt queuing"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "DWM_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled DWM interrupt queuing"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "DWM_COMPOSITOR_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled DWM compositor interrupt queuing"

:: Network and Connectivity Tuning
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "NETWORK_BUFFER_SIZE" "REG_SZ" "512" "Increased network buffer size for faster throughput"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "NETWORK_INTERRUPT_COALESCING" "REG_SZ" "0" "Disabled interrupt coalescing for lower network latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "NETWORK_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled network interrupt queuing"

:: Miscellaneous Performance Tuning
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "TIMER_RESOLUTION" "REG_SZ" "0" "Set smallest possible timer resolution for highest responsiveness"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "THREAD_SCHEDULER_POLICY" "REG_SZ" "0" "Prioritized immediate thread scheduling to reduce latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "GPU_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Minimized GPU interrupts for faster rendering"

:: Network Adapter Performance Tuning
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "NETWORK_ADAPTER_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled pending interrupts for network devices"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "NETWORK_ADAPTER_MAX_PENDING_IO" "REG_SZ" "0" "Ensured instant I/O processing for network operations"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "NETWORK_ADAPTER_INTERRUPT_MODERATION" "REG_SZ" "0" "Disabled interrupt moderation for lower network latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "NETWORK_ADAPTER_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled maximum pending interrupts for network adapter"

:: Storage Device (HDD/SSD) Performance Tuning
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "STORAGE_DEVICE_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled pending interrupts for storage devices"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "STORAGE_DEVICE_MAX_PENDING_IO" "REG_SZ" "0" "Ensured immediate processing of storage I/O operations"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "STORAGE_DEVICE_COMPLETION_POLICY" "REG_SZ" "0" "Forced immediate completion of storage I/O tasks"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "STORAGE_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled storage interrupt queuing"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "STORAGE_DEVICE_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled maximum pending interrupts for storage devices"

:: USB Device Performance Tuning
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "USB_DEVICE_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled pending interrupts for USB devices"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "USB_DEVICE_MAX_PENDING_IO" "REG_SZ" "0" "Enabled instant USB I/O processing for lower latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "USB_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled USB interrupt queuing"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "USB_DEVICE_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled maximum pending interrupts for USB devices"

:: PCIe Device Performance Tuning
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PCIE_DEVICE_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled pending interrupts for PCIe devices"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PCIE_DEVICE_MAX_PENDING_IO" "REG_SZ" "0" "Enabled immediate PCIe I/O processing"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PCIE_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled PCIe interrupt queuing"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PCIE_DEVICE_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled PCIe device interrupt queuing"

:: GPU Performance Tuning
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "GPU_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled GPU interrupt queuing"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "GPU_MAX_PENDING_COMPUTE" "REG_SZ" "0" "Enabled immediate GPU compute processing"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "GPU_MAX_PENDING_RENDER" "REG_SZ" "0" "Enabled immediate GPU render processing"

:: Audio Device Performance Tuning
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "AUDIO_DEVICE_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled pending interrupts for audio devices"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "AUDIO_DEVICE_BUFFER_SIZE" "REG_SZ" "512" "Optimized audio buffer size for lower latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "AUDIO_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled audio interrupt queuing"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "AUDIO_DEVICE_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled audio device interrupt queuing"

:: General Device Performance Tuning
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "DEVICE_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled pending interrupts globally"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "DEVICE_MAX_PENDING_IO" "REG_SZ" "0" "Enabled immediate I/O processing globally"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "DEVICE_COMPLETION_POLICY" "REG_SZ" "0" "Set immediate completion policy for all devices"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "DEVICE_MAX_PENDING_INTERRUPTS" "REG_SZ" "0" "Disabled device interrupt queuing globally"

goto mainTweaks

:mainTweaks
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
:: source - https://youtu.be/wil-09_5H0M
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "SerializeTimerExpiration" "REG_DWORD" "1" "Enabled timer serialization for better system timing"


goto customGPUTweaks

:customGPUTweaks
cls
echo.
echo %cMauve% +---------------------------+%cReset%
echo %cMauve% '%cGrey% Select Your RAM Size:     %cMauve%'%cReset%
echo %cMauve% +---------------------------+%cReset%
echo %cMauve% '%cGrey% [1] 4GB                   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] 6GB                   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] 8GB                   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] 16GB                  %cMauve%'%cReset%
echo %cMauve% '%cGrey% [5] 32GB                  %cMauve%'%cReset%
echo %cMauve% '%cGrey% [6] 64GB                  %cMauve%'%cReset%
echo %cMauve% '%cGrey% [7] Skip if Unsure        %cMauve%'%cReset%
echo %cMauve% +---------------------------+%cReset%
choice /C 1234567 /N /M ">"
if errorlevel 7 call :next
call :setRAMSize %errorlevel%

:setRAMSize
set "ramSize=%1"
set "svcHostThreshold="
set "ramSizeText="

if !ramSize! == 1 (
    set "svcHostThreshold=68764420"
    set "ramSizeText=4GB"
)
if !ramSize! == 2 (
    set "svcHostThreshold=103355478"
    set "ramSizeText=6GB"
)
if !ramSize! == 3 (
    set "svcHostThreshold=137922056"
    set "ramSizeText=8GB"
)
if !ramSize! == 4 (
    set "svcHostThreshold=376926742"
    set "ramSizeText=16GB"
)
if !ramSize! == 5 (
    set "svcHostThreshold=861226034"
    set "ramSizeText=32GB"
)
if !ramSize! == 6 (
    set "svcHostThreshold=1729136740"
    set "ramSizeText=64GB"
)

if defined svcHostThreshold (
    call :reg "HKLM\SYSTEM\ControlSet001\Control" "SvcHostSplitThresholdInKB" "REG_DWORD" "!svcHostThreshold!" "Set SvcHost Split Threshold for !ramSizeText! RAM optimization"
) else (
    echo %cRed%Invalid selection.%cReset%
)

pause
goto next

:next
cls
echo.
echo %cMauve% +-------------------------------------+%cReset%
echo %cMauve% '%cGrey% Select your GPU manufacturer:       %cMauve%'%cReset%
echo %cMauve% +-------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] NVIDIA                          %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] AMD                             %cMauve%'%cReset%
echo %cMauve% +-------------------------------------+%cReset%
echo %cMauve% '%cGrey% [3] Skip                            %cMauve%'%cReset%
echo %cMauve% +-------------------------------------+%cReset%

choice /C 123 /N /M ">"
if errorlevel 3 call :main
if errorlevel 2 call :amd
if errorlevel 1 call :nvidia

:nvidia
:: NVIDIA Specific Tweaks
: source - https://github.com/AlchemyTweaks/Verified-Tweaks/blob/main/Nvidia/RmGpsPsEnablePerCpuCoreDpc
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "RmGpsPsEnablePerCpuCoreDpc" "REG_DWORD" "1" "Enabled per-CPU core DPC for NVIDIA drivers"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" "RmGpsPsEnablePerCpuCoreDpc" "REG_DWORD" "1" "Enabled power-aware per-CPU core DPC"
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" "RmGpsPsEnablePerCpuCoreDpc" "REG_DWORD" "1" "Enabled NVIDIA driver per-CPU core DPC"
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\NVAPI" "RmGpsPsEnablePerCpuCoreDpc" "REG_DWORD" "1" "Enabled NVIDIA API per-CPU core DPC"
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" "RmGpsPsEnablePerCpuCoreDpc" "REG_DWORD" "1" "Enabled global NVIDIA tweaks for per-CPU core DPC"
pause

goto main

:amd
: source - https://youtu.be/nuUV2RoPOWc
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "AllowSnapshot" "REG_DWORD" "0" "Disabled AMD snapshot feature"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "AllowSubscription" "REG_DWORD" "0" "Disabled AMD subscription feature"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "AllowRSOverlay" "REG_SZ" "false" "Disabled AMD RS overlay"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "AllowSkins" "REG_SZ" "false" "Disabled AMD skins"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "AutoColorDepthReduction_NA" "REG_DWORD" "0" "Disabled automatic color depth reduction"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "DisableUVDPowerGatingDynamic" "REG_DWORD" "1" "Disabled UVD power gating"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "DisableVCEPowerGating" "REG_DWORD" "1" "Disabled VCE power gating"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "DisablePowerGating" "REG_DWORD" "1" "Disabled general power gating"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "DisableDrmdmaPowerGating" "REG_DWORD" "1" "Disabled DRMDMA power gating"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "DisableDMACopy" "REG_DWORD" "1" "Disabled DMA copy"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "DisableBlockWrite" "REG_DWORD" "0" "Enabled block write"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "StutterMode" "REG_DWORD" "0" "Disabled stutter mode"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "PP_GPUPowerDownEnabled" "REG_DWORD" "0" "Disabled GPU power down"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "LTRSnoopL1Latency" "REG_DWORD" "1" "Optimized LTR Snoop L1 latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "LTRSnoopL0Latency" "REG_DWORD" "1" "Optimized LTR Snoop L0 latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "LTRNoSnoopL1Latency" "REG_DWORD" "1" "Optimized LTR No Snoop L1 latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "LTRMaxNoSnoopLatency" "REG_DWORD" "1" "Optimized LTR max no snoop latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "KMD_RpmComputeLatency" "REG_DWORD" "1" "Optimized KMD RPM compute latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "DalUrgentLatencyNs" "REG_DWORD" "1" "Optimized DAL urgent latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "memClockSwitchLatency" "REG_DWORD" "1" "Optimized memory clock switch latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "PP_RTPMComputeF1Latency" "REG_DWORD" "1" "Optimized RTPM compute F1 latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "PP_DGBMMMaxTransitionLatencyUvd" "REG_DWORD" "1" "Optimized DGBMM UVD transition latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "PP_DGBPMMaxTransitionLatencyGfx" "REG_DWORD" "1" "Optimized DGBPM GFX transition latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "DalNBLatencyForUnderFlow" "REG_DWORD" "1" "Optimized DAL NB underflow latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "BGM_LTRSnoopL1Latency" "REG_DWORD" "1" "Optimized BGM LTR Snoop L1 latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "BGM_LTRSnoopL0Latency" "REG_DWORD" "1" "Optimized BGM LTR Snoop L0 latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "BGM_LTRNoSnoopL1Latency" "REG_DWORD" "1" "Optimized BGM LTR No Snoop L1 latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "BGM_LTRNoSnoopL0Latency" "REG_DWORD" "1" "Optimized BGM LTR No Snoop L0 latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "BGM_LTRMaxSnoopLatencyValue" "REG_DWORD" "1" "Optimized BGM LTR max snoop latency"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "BGM_LTRMaxNoSnoopLatencyValue" "REG_DWORD" "1" "Optimized BGM LTR max no snoop latency"
pause

goto main

:freeUpSpace

:: Disable Reserved Storage
echo.
echo %cGrey%Would you like to disable Reserved Storage?%cReset%
choice /C 12 /N /M "[1] Yes or [2] No : "
set "storage_choice=%errorlevel%"
if !storage_choice!==1 (
    echo %cGrey%Disabling Reserved Storage...%cReset%
    dism /Online /Set-ReservedStorageState /State:Disabled
)

:: Cleanup WinSxS
echo.
echo %cGrey%Would you like to clean up WinSxS?%cReset%
choice /C 12 /N /M "[1] Yes or [2] No : "
if %errorlevel%==1 (
    echo %cGrey%Cleaning up WinSxS...%cReset%
    dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase /RestoreHealth
)

:: Remove Virtual Memory
echo.
echo %cGrey%Would you like to remove Virtual Memory (pagefile.sys)?%cReset%
choice /C 12 /N /M "[1] Yes or [2] No : "
if %errorlevel%==1 (
    echo %cGrey%Removing Virtual Memory...%cReset%
    powershell -Command "Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value ''"
)

:: Clear Windows Update Folder
echo.
echo %cGrey%Would you like to clear the Windows Update Folder?%cReset%
choice /C 12 /N /M "[1] Yes or [2] No : "
if %errorlevel%==1 (
    echo %cGrey%Stopping Windows Update related services...%cReset%
    net stop wuauserv >nul 2>&1
    net stop cryptSvc >nul 2>&1
    net stop bits >nul 2>&1
    net stop msiserver >nul 2>&1
    
    echo %cGrey%Clearing Windows Update Folder...%cReset%
    rd /s /q "%systemdrive%\Windows\SoftwareDistribution"
    md "%systemdrive%\Windows\SoftwareDistribution"
    
    echo %cGrey%Restarting Windows Update related services...%cReset%
    net start wuauserv >nul 2>&1
    net start cryptSvc >nul 2>&1
    net start bits >nul 2>&1
    net start msiserver >nul 2>&1
    
    echo %cGreen%Windows Update folder has been cleared successfully.%cReset%
)

:: Advanced disk cleaner
echo.
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Advanced Disk Cleaner                                  %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% This will clean:                                       %cMauve%'%cReset%
echo %cMauve% '%cGrey% - Windows temporary files                              %cMauve%'%cReset%
echo %cMauve% '%cGrey% - System error memory dump files                       %cMauve%'%cReset%
echo %cMauve% '%cGrey% - Windows upgrade log files                            %cMauve%'%cReset%
echo %cMauve% '%cGrey% - Windows Defender Antivirus files                     %cMauve%'%cReset%
echo %cMauve% '%cGrey% - Delivery Optimization Files                          %cMauve%'%cReset%
echo %cMauve% '%cGrey% - Device driver packages                               %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
choice /C 12 /N /M "[1] Run Cleaner or [2] Skip : "
if %errorlevel%==1 (
    echo %cGrey%Preparing disk cleanup utility...%cReset%
    
    :: Create registry keys for auto-selection of all cleanup options
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders" "StateFlags65535" "REG_DWORD" "2" "Enabled Active Setup Temp Folders cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache" "StateFlags65535" "REG_DWORD" "2" "Enabled BranchCache cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\D3D Shader Cache" "StateFlags65535" "REG_DWORD" "2" "Enabled D3D Shader Cache cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Delivery Optimization Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Delivery Optimization Files cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Device Driver Packages" "StateFlags65535" "REG_DWORD" "2" "Enabled Device Driver Packages cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Downloaded Program Files cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Internet Cache Files cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Language Pack" "StateFlags65535" "REG_DWORD" "2" "Enabled Language Pack cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Offline Pages Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Offline Pages Files cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Old ChkDsk Files cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations" "StateFlags65535" "REG_DWORD" "2" "Enabled Previous Installations cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin" "StateFlags65535" "REG_DWORD" "2" "Enabled Recycle Bin cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\RetailDemo Offline Content" "StateFlags65535" "REG_DWORD" "2" "Enabled RetailDemo Offline Content cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup" "StateFlags65535" "REG_DWORD" "2" "Enabled Service Pack Cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Setup Log Files cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files" "StateFlags65535" "REG_DWORD" "2" "Enabled System error memory dump files cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files" "StateFlags65535" "REG_DWORD" "2" "Enabled System error minidump files cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Temporary Files cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache" "StateFlags65535" "REG_DWORD" "2" "Enabled Thumbnail Cache cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup" "StateFlags65535" "REG_DWORD" "2" "Enabled Update Cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Upgrade Discarded Files cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\User file versions" "StateFlags65535" "REG_DWORD" "2" "Enabled User file versions cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender" "StateFlags65535" "REG_DWORD" "2" "Enabled Windows Defender cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Windows Error Reporting Files cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows ESD installation files" "StateFlags65535" "REG_DWORD" "2" "Enabled Windows ESD installation files cleanup"
    call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Windows Upgrade Log Files cleanup"
    
    :: First try running directly
    cleanmgr /sagerun:65535
    
    :: If direct execution fails, try with full path
    if !errorlevel! neq 0 (
        echo Retrying with full path...
        %SystemRoot%\System32\cleanmgr.exe /sagerun:65535
    )
    
    :: Check final execution status
    if !errorlevel! equ 0 (
        echo Disk cleanup completed successfully.
    ) else (
        echo Error: Disk cleanup failed with code !errorlevel!
        echo Attempting to launch Disk Cleanup manually...
        start cleanmgr.exe
    )
    pause
)

:: Install and Launch PC Manager
echo.
echo %cGrey%Would you like to install and launch PC Manager? (Official Microsoft Utility from Store)%cReset%
choice /C 12 /N /M "[1] Yes or [2] No : "
if %errorlevel%==1 (
    echo %cGrey%Installing PC Manager...%cReset%
    winget install Microsoft.PCManager --accept-package-agreements --accept-source-agreements
    if !errorlevel! equ 0 (
        echo Successfully installed PC Manager.
        start "" "shell:AppsFolder\Microsoft.MicrosoftPCManager_8wekyb3d8bbwe!App"
    ) else if !errorlevel! equ -1978335189 (
        echo %cGrey%PC Manager is already installed. Launching...%cReset%
        start "" "shell:AppsFolder\Microsoft.MicrosoftPCManager_8wekyb3d8bbwe!App"
    ) else (
        echo Failed to install PC Manager. Please try manually.
        start "" "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9pm860492szd&storecid=storeweb-pdp-open-cta"
        pause
    )
)

goto main

:launchWinUtil
cls
start cmd /c powershell -Command "irm 'https://christitus.com/win' | iex"
goto main

:launchPrivacySexy
cls
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Privacy.Sexy Settings                                  %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Open Privacy.Sexy Website (Customizable)           %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Download and Run Script (Standard Preset)          %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Back to Main Menu                                  %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%

choice /C 123 /N /M ">"
if errorlevel 3 goto main
if errorlevel 2 (
    echo %cGrey%Downloading and executing privacy script...%cReset%
    powershell -Command "irm 'https://raw.githubusercontent.com/emylfy/simplify11/refs/heads/main/src/scripts/privacy-standart.bat' -OutFile \"%TEMP%\privacy-standart.bat\"" && start cmd /c "%TEMP%\privacy-standart.bat"
    if !errorlevel! equ 0 (
        echo %cGreen%Privacy script executed successfully.%cReset%
    ) else (
        echo %cRed%Failed to execute privacy script.%cReset%
    )
    pause
    goto main
)
if errorlevel 1 (
    start "" "https://privacy.sexy"
    goto main
)
goto main

:wingetInstall
cls
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Select Package Manager:                                 %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Winget - Windows native solution                    %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] UniGetUI - Graphical package manager                %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Back to Main Menu                                   %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%

choice /C 123 /N /M ">"
if errorlevel 3 goto main
if errorlevel 2 goto additional
if errorlevel 1 goto checkWinget

:additional
powershell -Command "if ((winget list --id MartiCliment.UniGetUI --accept-source-agreements) -match 'MartiCliment.UniGetUI') { exit 0 } else { exit 1 }"
if !errorlevel! equ 0 (
    echo %cGrey%UniGetUI is already installed. Launching...%cReset%
    start "" "unigetui:"
) else (
    echo %cGrey%Installing UniGetUI...%cReset%
    winget install MartiCliment.UniGetUI --accept-package-agreements --accept-source-agreements
    if !errorlevel! equ 0 (
        echo %cGreen%Successfully installed UniGetUI.%cReset%
        start "" "unigetui:"
    ) else (
        echo %cRed%Failed to install UniGetUI. Opening website for manual download...%cReset%
        start "" "https://www.marticliment.com/unigetui/"
        goto checkWinget
    )
)

cls
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Would you like to install additional package managers?   %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Install Scoop                                       %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Install Chocolatey                                  %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Install Both                                        %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] Skip                                                %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
choice /C 1234 /N /M ">"
if !errorlevel! equ 1 (
    if !errorlevel! equ 1 (
        echo %cGrey%Installing Scoop...%cReset%
        start cmd /c powershell -Command "& { irm get.scoop.sh -outfile 'install.ps1'; if (Test-Path 'install.ps1') { .\install.ps1; Remove-Item 'install.ps1' } else { Write-Host 'Failed to download Scoop installer' } }"
        pause
        goto main
    )

) else if !errorlevel! equ 2 (
    echo %cGrey%Checking for Chocolatey installation...%cReset%
    where choco >nul 2>nul
    if !errorlevel! equ 0 (
        echo %cGrey%Chocolatey is already installed.%cReset%
        timeout /t 2
    ) else (
        echo %cGrey%Installing Chocolatey...%cReset%
        powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    )
) else if !errorlevel! equ 3 (
    echo %cGrey%Installing Scoop...%cReset%
    powershell -Command "& {Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; if (Get-Command scoop -ErrorAction SilentlyContinue) { Write-Host 'Scoop is already installed.' } else { try { Invoke-RestMethod get.scoop.sh | Invoke-Expression; Write-Host 'Scoop installed successfully.' } catch { Write-Host 'Failed to install Scoop. Error:' $_.Exception.Message } }}"
    if !errorlevel! equ 0 (
        echo %cGreen%Scoop installation completed.%cReset%
    ) else (
        echo %cRed%Failed to install Scoop. Please check PowerShell execution policy and internet connection.%cReset%
        pause
    )
    echo %cGrey%Checking for Chocolatey installation...%cReset%
    where choco >nul 2>nul
    if !errorlevel! equ 0 (
        echo %cGrey%Chocolatey is already installed.%cReset%
        timeout /t 2
    ) else (
        echo %cGrey%Installing Chocolatey...%cReset%
        powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    )
)

goto main


:checkWinget
where winget >nul 2>nul
if !errorlevel! neq 0 (
    echo %cRed%Winget is not installed. Please install Windows App Installer from Microsoft Store.%cReset%
    start "" "ms-windows-store://pdp/?ProductId=9nblggh4nns1"
    pause
    goto wingetInstall
)

:wingetInstall
title Simplify11: Install apps
cls

:: Define packages for winget installation
set "pkg[1]=Microsoft.VisualStudioCode"
set "pkg[2]=Python"
set "pkg[3]=OpenJS.NodeJS"
set "pkg[4]=Anysphere.Cursor"
set "pkg[5]=Git.Git"
set "pkg[6]=GitHub.GitHubDesktop"
set "pkg[7]=TheBrowserCompany.Arc"
set "pkg[8]=Alex313031.Thorium"
set "pkg[9]=Zen-Team.Zen-Browser"
set "pkg[10]=Yandex.Browser"
set "pkg[11]=Microsoft.PowerToys"
set "pkg[12]=M2Team.NanaZip"
set "pkg[13]=agalwood.motrix"
set "pkg[14]=MartiCliment.UniGetUI"
set "pkg[15]=TechPowerUp.NVCleanstall"
set "pkg[16]=NVIDIA.Broadcast"
set "pkg[17]=RadolynLabs.AyuGramDesktop"
set "pkg[18]=Vencord.Vesktop"
set "pkg[19]=lencx.ChatGPT"
set "pkg[20]=Doist.Todoist"
set "pkg[21]=RustemMussabekov.Raindrop"
set "pkg[22]=Valve.Steam"
set "pkg[23]=EpicGames.EpicGamesLauncher"
set "pkg[24]=Microsoft.DirectX"
set "pkg[25]=Microsoft.DotNet.Runtime.8"
set "pkg[26]=Microsoft.PCManager"
set "pkg[27]=Microsoft.EdgeWebView2Runtime"

echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve%  %cGreen%[0] Search for any program                              %cMauve% %cReset%
echo.
echo %cMauve%  %cGreen%Development Tools:                                      %cMauve% %cReset%
echo %cMauve%  %cGrey%[1] Visual Studio Code  [2] Python                     %cMauve% %cReset%
echo %cMauve%  %cGrey%[3] Node.js             [4] Cursor                     %cMauve% %cReset%
echo %cMauve%  %cGrey%[5] Git                 [6] GitHub Desktop             %cMauve% %cReset%
echo %cMauve%  %cGreen%Browsers:                                              %cMauve% %cReset%
echo %cMauve%  %cGrey%[7] Arc                 [8] Thorium                    %cMauve% %cReset%
echo %cMauve%  %cGrey%[9] Zen                 [10] Yandex                    %cMauve% %cReset%
echo %cMauve%  %cGreen%Utilities:                                             %cMauve% %cReset%
echo %cMauve%  %cGrey%[11] PowerToys          [12] NanaZip                   %cMauve% %cReset%
echo %cMauve%  %cGrey%[13] Motrix             [14] UniGetUI                  %cMauve% %cReset%
echo %cMauve%  %cGrey%[15] NVCleanstall       [16] NVIDIA Broadcast         %cMauve% %cReset%
echo %cMauve%  %cGreen%Social ^& Productivity:                                 %cMauve% %cReset%
echo %cMauve%  %cGrey%[17] AyuGram            [18] Vesktop                   %cMauve% %cReset%
echo %cMauve%  %cGrey%[19] ChatGPT            [20] Todoist                   %cMauve% %cReset%
echo %cMauve%  %cGrey%[21] Raindrop                                          %cMauve% %cReset%
echo %cMauve%  %cGreen%Gaming:                                                %cMauve% %cReset%
echo %cMauve%  %cGrey%[22] Steam              [23] Epic Games Store          %cMauve% %cReset%
echo %cMauve%  %cGreen%Microsoft Stuff:                                       %cMauve% %cReset%
echo %cMauve%  %cGrey%[24] DirectX            [25] .NET 8.0                  %cMauve% %cReset%
echo %cMauve%  %cGrey%[26] PC Manager         [27] Edge WebView              %cMauve% %cReset%
echo.
echo %cMauve%  %cGrey%[28] Update all installed apps                          %cMauve% %cReset%
echo %cMauve%  %cGrey%[29] Back to Main Menu                                 %cMauve% %cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%

set /p choice="%cSapphire%Enter your choices (space-separated numbers '1 2'): %cReset%"

:: Process each number in the input sequentially
for %%a in (%choice%) do (
    if %%a==0 (
        goto searchPkg
    ) else if %%a==28 (
        echo %cGrey%Updating all installed apps...%cReset%
        winget upgrade --all --accept-package-agreements --accept-source-agreements
        if !errorlevel! equ 0 (
            echo %cGreen%Successfully updated all apps.%cReset%
        ) else (
            echo %cRed%Failed to update some apps. Error code: !errorlevel!%cReset%
            pause
        )
    ) else if %%a==29 (
        goto main
    ) else (
        :: Check if it's a valid number
        set /a "num=%%a" 2>nul
        if !num! geq 1 if !num! leq 27 (
            if defined pkg[%%a] (
                echo.
                echo Installing !pkg[%%a]!...
                winget install --id !pkg[%%a]! --accept-package-agreements --accept-source-agreements
                if !errorlevel! equ 0 (
                    echo Successfully installed !pkg[%%a]!
                ) else if !errorlevel! equ -1978335189 (
                    echo %cGrey%!pkg[%%a]! is already installed. Skipping...%cReset%
                    timeout /t 2
                ) else (
                    echo %cRed%Failed to install !pkg[%%a]!. Error code: !errorlevel!%cReset%
                    echo %cGrey%Opening DuckDuckGo search for alternative download...%cReset%
                    start "" "https://duckduckgo.com/?q=download+!pkg[%%a]!+windows"
                    pause
                )
            ) else (
                echo No package defined for choice %%a
                pause
            )
        ) else (
            echo Invalid choice: %%a%
            pause
        )
    )
)

goto wingetInstall

:searchPkg
cls
echo %cGrey%Enter Program name to search (or 'b' to return):%cReset%
set /p "searchTerm="
if /i "%searchTerm%"=="b" goto wingetInstall
if /i "%searchTerm%"=="" goto searchPkg

echo %cGrey%Searching for "%searchTerm%"...%cReset%
winget search "%searchTerm%"
echo.
echo %cGrey%Enter the exact package ID to install (or 'b' to return):%cReset%
set /p "packageId="
if /i "%packageId%"=="b" goto wingetInstall
if /i "%packageId%"=="" goto searchPkg

call :installPkg "%packageId%"
goto wingetInstall

:installPkg
set "packageId=%~1"
echo.
echo %cGrey%Installing %packageId%...%cReset%
winget install --id %packageId% --accept-package-agreements --accept-source-agreements
if !errorlevel! equ 0 (
    echo %cGreen%Successfully installed %packageId%%cReset%
    goto searchPkg
) else if !errorlevel! equ -1978335189 (
    echo %cGrey%%packageId% is already installed. Skipping...%cReset%
    timeout /t 2
    goto searchPkg
) else (
    echo %cRed%Failed to install %packageId%. Error code: !errorlevel!%cReset%
    echo %cGrey%Opening DuckDuckGo search for alternative download...%cReset%
    start "" "https://duckduckgo.com/?q=download+%packageId%+windows"
    pause
    goto searchPkg
)

:coolStuff
cls
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Customization Options                                  %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Open Night Light Settings                        %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Set Short Date Format (d MMM yy)                   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Rename System Drive to Win 11                      %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] Visit Cool Stuff Page (Themes and More)            %cMauve%'%cReset%
echo %cMauve% '%cGrey% [5] Back to Main Menu                                  %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%

choice /C 12345 /N /M ">"
set "customization_choice=%errorlevel%"
if !customization_choice! equ 5 goto main
if !customization_choice! equ 4 (
    start "" "https://github.com/emylfy/simplify11?tab=readme-ov-file#-cool-stuff"
    goto coolStuff
)
if !customization_choice! equ 3 (
    label C:Win 11
    start explorer.exe
    pause
)
if errorlevel 2 (
    call :reg "HKEY_CURRENT_USER\Control Panel\International" "sShortDate" "REG_SZ" "d MMM yy" "Set short date format to d MMM yy"
    echo %cGreen%Date format updated successfully. Changes will take effect after restart.%cReset%
    pause
    goto coolStuff
)
if errorlevel 1 (
    start ms-settings:nightlight
    goto coolStuff
)
goto coolStuff

:deviceMenu
cls
:: Define URLs for modern device manufacturers
set "url[0]=https://support.hp.com/us-en/drivers"
set "url[1]=https://support.lenovo.com"
set "url[2]=https://www.asus.com/support/download-center/"
set "url[3]=https://www.acer.com/ac/en/US/content/drivers"
set "url[4]=https://www.msi.com/support/download"
set "url[5]=https://www.huawei.com/en/support"
set "url[6]=https://www.xiaomi.com/global/support"
set "url[7]=https://www.alienware.com/support"
set "url[8]=https://www.gigabyte.com/support/consumer"

echo %cMauve% +-----------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Select your device manufacturer to install drivers: %cMauve%'%cReset%
echo %cMauve% +-----------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [0] HP                                              %cMauve%'%cReset%
echo %cMauve% '%cGrey% [1] Lenovo                                          %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Asus                                            %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Acer                                            %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] MSI                                             %cMauve%'%cReset%
echo %cMauve% '%cGrey% [5] Huawei                                          %cMauve%'%cReset%
echo %cMauve% '%cGrey% [6] Xiaomi                                          %cMauve%'%cReset%
echo %cMauve% '%cGrey% [7] Alienware                                       %cMauve%'%cReset%
echo %cMauve% '%cGrey% [8] Gigabyte                                        %cMauve%'%cReset%
echo %cMauve% +-----------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [9] Back to menu                                    %cMauve%'%cReset%
echo %cMauve% +-----------------------------------------------------+%cReset%

choice /C 0123456789 /N /M "Select a number: "
set /A "manufacturer_choice=%errorlevel%-1"

if !manufacturer_choice!==1 (
    goto lenovoMenu
) else if !manufacturer_choice! geq 0 if !manufacturer_choice! leq 8 (
    start "" "!url[%manufacturer_choice%]!"
    goto main
) else if !manufacturer_choice!==9 (
    goto main
) else (
    echo %cRed%Invalid choice. Returning to main menu.%cReset%
    timeout /t 2 >nul
    goto main
)

:lenovoMenu
cls
echo.
echo %cMauve% +--------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Install Lenovo Vantage                 %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Install Dolby Access                   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Open Lenovo Driver Page                %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [4] Back to Manufacturer Selection         %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------+%cReset%

choice /C 1234 /N /M ">"
set "lenovo_choice=%errorlevel%"
if !lenovo_choice! equ 4 goto deviceMenu
if !lenovo_choice! equ 3 (
    start "" "https://support.lenovo.com"
    goto lenovoMenu
)
if !lenovo_choice! equ 2 (
    echo %cGrey%Installing Dolby Access...%cReset%
    winget install "9NBLGGH4XDB3" --accept-package-agreements --accept-source-agreements
    if !errorlevel! equ 0 (
        echo %cGreen%Successfully installed Dolby Access.%cReset%
    ) else (
        echo %cRed%Failed to install Dolby Access. Please install manually from the Microsoft Store.%cReset%
         start "" "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9N0866FS04W8&storecid=storeweb-pdp-open-cta"
    )
    timeout /t 2
    goto lenovoMenu
)
if errorlevel 1 (
    echo %cGrey%Installing Lenovo Vantage...%cReset%
    winget install "9WZDNCRFJ4MV" --accept-package-agreements --accept-source-agreements
    if !errorlevel! equ 0 (
        echo %cGreen%Successfully installed Lenovo Vantage.%cReset%
    ) else (
        echo %cRed%Failed to install Lenovo Vantage. Please install manually from the Microsoft Store.%cReset%
         start "" "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9WZDNCRFJ4MV&storecid=storeweb-pdp-open-cta"
    )
    timeout /t 2
    goto lenovoMenu
)

:reg
setlocal
set "key=%~1"
set "valueName=%~2"
set "valueType=%~3"
set "valueData=%~4"
set "comment=%~5"

:: Convert registry hive shortcuts to full paths
set "key=%key:HKLM\=HKEY_LOCAL_MACHINE\%"
set "key=%key:HKCU\=HKEY_CURRENT_USER\%"

:: Create the registry key path if it doesn't exist
reg add "%key%" /f >nul 2>&1

:: Handle different value types
if /i "%valueType%"=="REG_DWORD" (
    reg add "%key%" /v "%valueName%" /t REG_DWORD /d "%valueData%" /f >nul 2>&1
) else if /i "%valueType%"=="REG_SZ" (
    reg add "%key%" /v "%valueName%" /t REG_SZ /d "%valueData%" /f >nul 2>&1
) else if /i "%valueType%"=="REG_BINARY" (
    reg add "%key%" /v "%valueName%" /t REG_BINARY /d "%valueData%" /f >nul 2>&1
) else (
    echo %cRed%[FAILED]%cReset% Unsupported registry value type: %valueType%
    exit /b 1
)

if %errorlevel% equ 0 (
    echo %cGreen%[SUCCESS]%cReset% %comment%
) else (
    echo %cRed%[FAILED]%cReset% Failed to set %valueName%
    exit /b 1
)

exit /b 0
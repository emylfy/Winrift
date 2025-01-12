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

:: Storage Device Selection
:storageSelection
cls
echo.
echo %cMauve% +-----------------------------------+%cReset%
echo %cMauve% '%cGrey% Storage Device Selection          %cMauve%'%cReset%
echo %cMauve% +-----------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] SSD/NVMe                      %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] HDD                           %cMauve%'%cReset%
echo %cMauve% +-----------------------------------+%cReset%
choice /C 12 /N /M ">" 2>nul
if errorlevel 255 goto storageSelectionError
if errorlevel 2 goto storageHDD
if errorlevel 1 goto storageSSD
goto storageSelectionError

:storageSelectionError
echo %cRed%Invalid selection. Please try again.%cReset%
timeout /t 2 >nul
goto storageSelection

:storageSSD
echo %cGreen%SSD/NVMe selected - Applying optimizations...%cReset%
:: Enable and optimize TRIM for SSD
fsutil behavior set DisableDeleteNotify 0
:: Disable defragmentation for SSDs
schtasks /Change /TN "\Microsoft\Windows\Defrag\ScheduledDefrag" /Disable
:: Disable NTFS last access time updates
fsutil behavior set disablelastaccess 1
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsDisable8dot3NameCreation" "REG_DWORD" "1" "Disabled legacy 8.3 filename creation for better SSD performance"
goto checkLaptop

:storageHDD
echo %cGrey%HDD selected - Skipping optimizations...%cReset%

goto checkLaptop

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
    goto laptopPowerChoice
)

:laptopPowerChoice
echo.
echo %cMauve% +-----------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Power Management - Max Pending Interrupts           %cMauve%'%cReset%
echo %cMauve% +-----------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Do you want to apply tweaks that will use           %cMauve%'%cReset%
echo %cMauve% '%cGrey% maximum power and can drain the battery faster?     %cMauve%'%cReset%
echo %cMauve% +-----------------------------------------------------+%cReset%
choice /C 12 /N /M "[1] Yes [2] No: " 2>nul
if errorlevel 255 goto laptopPowerChoiceError
if errorlevel 2 goto skipPowerTweaks
if errorlevel 1 goto applyPowerIntensiveTweaks
goto laptopPowerChoiceError

:laptopPowerChoiceError
echo %cRed%Invalid selection. Please try again.%cReset%
timeout /t 2 >nul
goto laptopPowerChoice

:applyPowerIntensiveTweaks
:: Apply power intensive tweaks
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

goto skipPowerTweaks

:skipPowerTweaks
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
if errorlevel 3 exit
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
exit

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
exit

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
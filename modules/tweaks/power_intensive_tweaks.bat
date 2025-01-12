@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (powershell start -verb runas '%~0' & exit)

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

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

:reg
call "%~dp0\..\reg_helper.bat" %*
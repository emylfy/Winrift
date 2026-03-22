# System Tweaks Guide

All tweaks have been tested and compared across multiple sources. Only the most effective values and best practices are included.

## Table of Contents

- [Before You Start](#before-you-start)
- [Universal Tweaks](#universal-tweaks)
- [Power Management](#power-management)
- [GPU-Specific Tweaks](#gpu-specific-tweaks)
- [Free Up Disk Space](#free-up-disk-space)
- [How to Revert](#how-to-revert)
- [Reference Sources](#reference-sources)

## Before You Start

**Compatibility:** Windows 11 22H2 / 23H2 / 24H2 / 25H2

**Safety:** A System Restore Point is automatically created before applying any tweaks.

**Recommended:** Apply tweaks through the [Winrift](https://github.com/emylfy/winrift) interface — it lets you pick individual categories and handles everything automatically.

**Risk levels used in this guide:**
- 🟢 **Safe** — no side effects, can be reverted easily
- 🟡 **Moderate** — disables features some users may need

## Universal Tweaks

### 1. System Latency 🟡

Reduces system-level latency by changing how Windows handles interrupts and timers.

| Registry Key | Value | Effect |
|---|---|---|
| `InterruptSteeringDisabled` | 1 | Disables interrupt steering — prevents Windows from redistributing hardware interrupts across cores |
| `SerializeTimerExpiration` | 1 | Forces timers to expire on a single core, reducing cross-core contention |

**Path:** `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel`

Sources: [Interrupt Steering](https://youtu.be/Gazv0q3njYU), [Timer Serialization](https://youtu.be/wil-09_5H0M)

---

### 2. Input Device Optimization 🟢

Reduces input lag for mouse and keyboard.

| Registry Key | Value | Effect |
|---|---|---|
| `MouseDataQueueSize` | 20 | Smaller buffer = faster mouse input processing |
| `KeyboardDataQueueSize` | 20 | Smaller buffer = faster keyboard input processing |
| `StickyKeys` | 506 | Disables StickyKeys popup |
| `ToggleKeys Flags` | 58 | Disables ToggleKeys audio indicator |
| `DelayBeforeAcceptance` | 0 | No delay before key press is accepted |
| `AutoRepeatRate` | 0 | Maximum key repeat speed |
| `AutoRepeatDelay` | 0 | No delay before key repeat starts |
| `Keyboard Response Flags` | 122 | Disables FilterKeys with all optimizations active |

**Paths:**
- `HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters`
- `HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters`
- `HKCU:\Control Panel\Accessibility`
- `HKCU:\Control Panel\Accessibility\ToggleKeys`
- `HKCU:\Control Panel\Accessibility\Keyboard Response`

Sources: [Verified-Tweaks](https://github.com/AlchemyTweaks/Verified-Tweaks), [Latency Optimization](https://github.com/denis-g/windows10-latency-optimization)

---

### 3. SSD/NVMe Performance 🟢

Optimizes storage for solid-state drives. Automatically detects SSD/NVMe presence before applying.

| Action | Effect |
|---|---|
| TRIM enabled (`DisableDeleteNotify = 0`) | Ensures SSD can reclaim unused blocks |
| Defragmentation disabled | Prevents unnecessary writes on SSD |
| Last access time disabled | Reduces NTFS write overhead |
| 8.3 filename creation disabled | Removes legacy short filename generation |
| Prefetcher disabled | Not needed on SSD — reduces background I/O |
| Superfetch tracing disabled | Same as above |
| ApplicationPreLaunch disabled | Prevents speculative app loading |

**Paths:**
- `HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem`
- `HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters`

Source: [Latency Optimization](https://github.com/denis-g/windows10-latency-optimization)

---

### 4. GPU Hardware Scheduling 🟡

Enables hardware-accelerated GPU scheduling for lower render latency.

| Registry Key | Value | Effect |
|---|---|---|
| `HwSchMode` | 2 | Enables hardware GPU scheduling |
| `EnablePreemption` | 0 | Disables GPU preemption — reduces micro-stutter |

**Paths:**
- `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers`
- `HKLM:\SYSTEM\ControlSet001\Control\GraphicsDrivers\Scheduler`

Source: [Latency Optimization](https://github.com/denis-g/windows10-latency-optimization)

---

### 5. Network Optimization 🟢

Removes bandwidth throttling for maximum throughput.

| Registry Key | Value | Effect |
|---|---|---|
| `NetworkThrottlingIndex` | 4294967295 | Disables network throttling entirely |
| `NoLazyMode` | 1 | Disables lazy mode for network packet processing |

**Path:** `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile`

Source: [Network Tweaks](https://youtu.be/EmdosMT5TtA)

---

### 6. CPU Performance 🟢

Optimizes CPU scheduling for foreground application performance.

| Registry Key | Value | Effect |
|---|---|---|
| `LazyModeTimeout` | 25000 | Sets optimal timeout for multimedia scheduling |
| MMCSS `Start` | 2 | Sets Multimedia Class Scheduler Service to auto-start |

**Paths:**
- `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile`
- `HKLM:\SYSTEM\CurrentControlSet\Services\MMCSS`

Source: [CPU Tweaks](https://youtu.be/FxpRL7wheGc)

---

### 7. Power Management 🟢

Disables background power monitoring overhead. Safe for all devices including laptops on battery.

| Registry Key | Value | Effect |
|---|---|---|
| `PowerThrottlingOff` | 1 | Disables CPU power throttling |
| `EnergyEstimationEnabled` | 0 | Stops background energy tracking |
| `EventProcessorEnabled` | 0 | Disables power event processor |
| `DisableTaggedEnergyLogging` | 1 | Stops per-app energy logging |
| `TelemetryMaxApplication` | 0 | Disables energy telemetry per application |
| `TelemetryMaxTagPerApplication` | 0 | Disables energy tagging per application |

**Paths:**
- `HKLM:\SYSTEM\CurrentControlSet\Control\Power`
- `HKLM:\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\TaggedEnergy`

Sources: [Ancels Performance Batch](https://github.com/ancel1x/Ancels-Performance-Batch), [Power Tweaks](https://youtu.be/5omPOfsJNSo)

---

### 8. System Responsiveness 🟡

Prioritizes foreground applications over background services.

| Registry Key | Value | Effect |
|---|---|---|
| `Win32PrioritySeparation` | 0x24 | Short, variable, foreground priority boost |
| `IRQ8Priority` | 1 | Higher priority for system timer interrupt |
| `IRQ16Priority` | 2 | Higher priority for secondary interrupts |

**Paths:**
- `HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl`
- `HKLM:\SYSTEM\ControlSet001\Control\PriorityControl`

Source: [Priority Separation](https://youtu.be/bqDMG1ZS-Yw)

---

### 9. Boot Optimization 🟢

Removes artificial delays during Windows startup.

| Registry Key | Value | Effect |
|---|---|---|
| `Startupdelayinmsec` | 0 | Removes startup delay for apps |
| `DelayedDesktopSwitchTimeout` | 0 | Removes desktop transition delay |

**Paths:**
- `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize`
- `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`

---

### 10. System Maintenance 🟡

Disables background maintenance tasks that consume resources.

| Registry Key | Value | Effect |
|---|---|---|
| `MaintenanceDisabled` | 1 | Disables Windows automatic maintenance |
| `CountOperations` | 0 | Disables I/O operation counting |
| `EncryptProtocol` | 0 | Disables FSS provider encryption overhead |
| `DisableRpcOver` | 1 | Disables RPC over Task Scheduler |

**Paths:**
- `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance`
- `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\I/O System`
- `HKLM:\SOFTWARE\Policies\Microsoft\Windows\fssProv`
- `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule`

Source: [System Maintenance](https://youtu.be/5omPOfsJNSo)

---

### 11. UI Responsiveness 🟢

Reduces timeouts and delays in the Windows shell for a snappier feel.

| Registry Key | Value | Effect |
|---|---|---|
| `AutoEndTasks` | 1 | Automatically ends unresponsive tasks |
| `HungAppTimeout` | 1000 | 1 second before marking app as hung |
| `WaitToKillAppTimeout` | 2000 | 2 seconds before force-closing apps |
| `LowLevelHooksTimeout` | 1000 | 1 second timeout for low-level hooks |
| `MenuShowDelay` | 0 | Instant menu display |
| `WaitToKillServiceTimeout` | 2000 | 2 seconds before force-stopping services |

**Paths:**
- `HKCU:\Control Panel\Desktop`
- `HKLM:\SYSTEM\CurrentControlSet\Control`

---

### 12. Memory Optimization 🟡

Improves memory management for systems with sufficient RAM.

| Registry Key | Value | Effect |
|---|---|---|
| `LargeSystemCache` | 1 | Uses larger system cache for file operations |
| `DisablePagingCombining` | 1 | Disables memory page combining |
| `DisablePagingExecutive` | 1 | Keeps kernel and drivers in RAM instead of paging to disk |

**Path:** `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`

Source: [QuickBoost Memory Tweaks](https://github.com/SanGraphic/QuickBoost)

---

### 13. DirectX Enhancements 🟢

Enables advanced DirectX 11 and DirectX 12 features for better gaming performance.

| Feature | APIs | Effect |
|---|---|---|
| Multithreading | D3D11, D3D12 | Distributes rendering work across CPU cores |
| Deferred Contexts | D3D11, D3D12 | Enables deferred command list recording |
| Tiling | D3D11, D3D12 | Optimizes texture and resource tiling |
| Dynamic Code Generation | D3D11 | Enables runtime shader optimization |
| Command Buffer Reuse | D3D12 | Reuses command buffers to reduce allocation overhead |
| Runtime Driver Optimizations | D3D12 | Enables driver-level rendering optimizations |
| Resource Alignment | D3D12 | Optimizes GPU memory resource alignment |
| CPU Page Table | D3D12 | Enables CPU-side page table for GPU memory |
| Heap Serialization | D3D12 | Enables heap allocation serialization |
| Residency Management | D3D12 | Optimizes GPU memory residency |

**Path:** `HKLM:\SOFTWARE\Microsoft\DirectX`

Source: [DirectX Tweaks](https://youtu.be/itTcqcJxtbo)

---

## Power Management 🟡

> **For desktops and plugged-in laptops.** These tweaks disable power-saving features like Connected Standby, CPU idle states, and PCIe ASPM. Skip if running on battery — they will significantly reduce battery life.

| Action | Effect |
|---|---|
| `CsEnabled = 0` | Disables Connected Standby |
| `PlatformAoAcOverride = 0` | Disables AC/DC platform override |
| `PerfEnablePackageIdle = 0` | Disables CPU package idle states (C-states) |
| `CPPCEnable = 0` | Disables Collaborative Processor Performance Control |
| `AllowPepPerfStates = 0` | Disables Platform Energy Provider states |
| `ASPMOptOut = 1` | Disables PCIe Active State Power Management |
| Ultimate Performance power plan | Activates hidden high-performance plan |

**Paths:**
- `HKLM:\SYSTEM\CurrentControlSet\Control\Power`
- `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Throttle`
- `HKLM:\SYSTEM\CurrentControlSet\Control\Processor`
- `HKLM:\SYSTEM\CurrentControlSet\Services\pci\Parameters`

Sources: [Ancels Performance Batch](https://github.com/ancel1x/Ancels-Performance-Batch), [Power Tweaks](https://youtu.be/5omPOfsJNSo)

---

## GPU-Specific Tweaks

### NVIDIA 🟢

Enables per-CPU core DPC (Deferred Procedure Call) processing across all NVIDIA driver paths to reduce GPU-related latency.

**Registry key:** `RmGpsPsEnablePerCpuCoreDpc = 1`

Applied to:
- `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers`
- `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power`
- `HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm`
- `HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\NVAPI`
- `HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak`

Source: [AlchemyTweaks NVIDIA](https://github.com/AlchemyTweaks/Verified-Tweaks)

### AMD 🟡

Optimizes AMD Radeon drivers by disabling power-saving features and minimizing latencies.

**Power gating disabled:**
- UVD, VCE, general, DRMDMA power gating — prevents GPU from entering low-power states during workloads

**Latency optimization:**
- All LTR (Latency Tolerance Reporting) values set to 1 for minimal latency
- Memory clock switch, compute, and display latencies minimized
- BGM (Background Memory) latencies optimized

**Other:**
- Stutter mode disabled
- GPU power down disabled
- Snapshots and subscriptions disabled

**Path:** `HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000`

Sources: [AMD Tweaks](https://youtu.be/nuUV2RoPOWc), [AlchemyTweaks AMD](https://github.com/AlchemyTweaks/Verified-Tweaks)

### Hybrid (Laptop)

Applies both NVIDIA and AMD tweaks for laptops with dual GPU configurations.

---

## Free Up Disk Space

### 1. Disable Reserved Storage
Disables the 7GB partition Windows reserves for updates.
```
dism /Online /Set-ReservedStorageState /State:Disabled
```

### 2. Clean WinSxS
Removes old component versions from the Windows component store.
```
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase /RestoreHealth
```

### 3. PC Manager
Installs and launches Microsoft PC Manager — official utility for system cleanup and optimization.

---

## How to Revert

1. **System Restore** — a restore point is created automatically before any tweaks are applied. Open `rstrui.exe` and select the restore point to undo all changes at once.

2. **Manual** — delete the modified registry keys or set them back to their default values, then reboot. Default values for each key can be found in the linked sources above.

3. **System repair** — if something breaks beyond registry changes:
   ```
   DISM /Online /Cleanup-Image /RestoreHealth
   sfc /scannow
   ```

---

## Reference Sources

- [AlchemyTweaks/Verified-Tweaks](https://github.com/AlchemyTweaks/Verified-Tweaks)
- [SanGraphic/QuickBoost](https://github.com/SanGraphic/QuickBoost)
- [UnLovedCookie/CoutX](https://github.com/UnLovedCookie/CoutX)
- [Snowfliger/SyncOS](https://github.com/Snowfliger/SyncOS)
- [denis-g/windows10-latency-optimization](https://github.com/denis-g/windows10-latency-optimization)
- [ancel1x/Ancels-Performance-Batch](https://github.com/ancel1x/Ancels-Performance-Batch)

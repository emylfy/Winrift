# System Tweaks Guide

Winrift brings Windows settings into one menu so you can see what each tweak changes before you apply it. This guide covers the individual settings, GPU presets, power options, and how to undo your changes on Windows 11 26H2.

## Table of Contents

- [Before You Start](#before-you-start)
- [How to Apply](#how-to-apply)
- [Recommended Preset](#recommended-preset)
- [Universal Tweaks](#universal-tweaks)
- [Power Management](#power-management)
- [GPU-Specific Tweaks](#gpu-specific-tweaks)
- [Free Up Disk Space](#free-up-disk-space)
- [How to Revert](#how-to-revert)
- [Reference Sources](#reference-sources)

## Before You Start

Start with **Review Recommended Preset** if you're setting up a fresh install. Use **All Tweaks** if you came for a specific setting. The preview shows the current and proposed values before you apply anything.

On a laptop, pay particular attention to the idle and power settings. Disabling idle states can increase heat and battery drain. Shorter shutdown timeouts give apps less time to save their work. For GPU changes, compare the same game or app on the same driver before and after.

## How to Apply

Open **Set Up Windows → Performance Tweaks**. Choose **Review Recommended Preset** for a short list, or **All Tweaks** to pick specific changes. **GPU Tweaks** and **Power Settings** have their own menus.

Use **Space** to select an item, **A** to select applicable items, and **→** to see the current and proposed values. A filled circle marks a selection. A check mark means the setting already matches. Press **Enter** to review your selection, then confirm **Apply**. You can return from the review to change your selection.

## Recommended Preset

| Setting | What changes |
| --- | --- |
| Accessibility activation shortcuts | Turns off the activation shortcuts for Sticky Keys, Toggle Keys, and Filter Keys while preserving their other settings. |
| Menu display delay | Sets the delay for opening submenus to zero. |
| TRIM notifications | Enables NTFS and ReFS delete notifications where they are disabled and the query is supported. |

The remaining settings are available for individual selection. The values below are what Winrift proposes. To see whether a preset helps on your PC, compare the same workload before and after applying it.

## Universal Tweaks

### 1. System Latency

These overrides change Windows interrupt and timer settings.

| Registry Key | Value | Effect |
|---|---|---|
| `InterruptSteeringDisabled` | 1 | Disables interrupt steering — prevents Windows from redistributing hardware interrupts across cores |
| `SerializeTimerExpiration` | 1 | Requests serialized timer expiration |

**Path:** `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel`

Sources: [Interrupt Steering](https://youtu.be/Gazv0q3njYU), [Timer Serialization](https://youtu.be/wil-09_5H0M)

---

### 2. Input Devices

| Setting | Value | What changes |
| --- | --- | --- |
| `MouseDataQueueSize` / `KeyboardDataQueueSize` | 20 | Sets the mouse and keyboard driver queue sizes. |
| Accessibility activation shortcuts | Off | Clears the activation shortcut flag through SystemParametersInfo. |
| `DelayBeforeAcceptance` | 0 | Sets the Filter Keys acceptance delay. |
| `AutoRepeatRate` / `AutoRepeatDelay` | 0 | Sets the Filter Keys repeat timing values. |

**Paths:** The queue settings are under `HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters` and `kbdclass\Parameters`. The timing settings are under `HKCU:\Control Panel\Accessibility\Keyboard Response`.

---

### 3. SSD / NVMe

| Setting | What changes |
| --- | --- |
| TRIM notifications | Sets `DisableDeleteNotify` to `0` through `fsutil` for supported filesystems. This verifies the Windows notification setting. |
| Last access time | Disables NTFS last-access timestamp updates. Restart to apply. |
| 8.3 filenames | Disables creation of legacy short filenames through `NtfsDisable8dot3NameCreation`. |
| Prefetch | Sets `EnablePrefetcher` to `0`. |
| Application Prelaunch | Turns off prelaunch through MMAgent. |

**Paths:** `HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem` and `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters`.

---

### 4. GPU Hardware Scheduling

HAGS and GPU preemption are separate settings. Review them individually under **GPU Tweaks → GPU Scheduling & Preemption**.

| Registry Key | Value | Effect |
|---|---|---|
| `HwSchMode` | 2 | Enables hardware GPU scheduling |
| `EnablePreemption` | 0 | Disables GPU preemption requests where the override applies |

**Paths:**
- `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers`
- `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler`

Source: [Latency Optimization](https://github.com/denis-g/windows10-latency-optimization)

---

### 5. Network

`NetworkThrottlingIndex = 0xFFFFFFFF` sets the multimedia network-throttling override under `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile`. Check throughput and latency under your own workload if you are tuning this setting.

### 6. Multimedia Scheduling

| Setting | Value | What changes |
| --- | --- | --- |
| `NoLazyMode` | 1 | Applies the existing Winrift MMCSS override. The upstream file uses `LazyMode = 0`, so its effect cannot be inferred from that file. |
| `LazyModeTimeout` | 25000 | Sets the timeout to 2.5 ms in 100 ns units. |
| MMCSS `Start` | 2 | Sets the Multimedia Class Scheduler Service to automatic startup. |

**Paths:** `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile` and `HKLM:\SYSTEM\CurrentControlSet\Services\MMCSS`.

---

### 7. Background Power Settings

These overrides change background power throttling and energy tracking. Disabling throttling can increase power use.

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

### 8. Process and IRQ Priority

These are optional scheduler and interrupt-priority overrides.

| Registry Key | Value | Effect |
|---|---|---|
| `Win32PrioritySeparation` | 0x24 | Short, variable, foreground priority boost |
| `IRQ8Priority` | 1 | Higher priority for system timer interrupt |
| `IRQ16Priority` | 2 | Higher priority for secondary interrupts |

**Paths:**
- `HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl`

Source: [Priority Separation](https://youtu.be/bqDMG1ZS-Yw)

---

### 9. Startup and Desktop Transition

Changes two timing settings for startup apps and desktop switching.

| Registry Key | Value | Effect |
|---|---|---|
| `Startupdelayinmsec` | 0 | Removes startup delay for apps |
| `DelayedDesktopSwitchTimeout` | 0 | Removes desktop transition delay |

**Paths:**
- `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize`
- `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`

---

### 10. Menus, Hooks and Shutdown

Menu delay is a display preference. Shorter shutdown timeouts and automatic task termination can leave apps less time to save work.

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

### 11. Memory

These settings change cache and paging behavior. Apply them individually if you want to compare their effect on your workload.

| Registry Key | Value | Effect |
|---|---|---|
| `LargeSystemCache` | 1 | Uses larger system cache for file operations |
| MMAgent Page Combining | Off | Disables memory page combining through MMAgent |
| `DisablePagingExecutive` | 1 | Requests that pageable kernel and driver code stay resident |

**Path:** `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`

Source: [QuickBoost Memory Tweaks](https://github.com/SanGraphic/QuickBoost)

---

### 12. Automatic Maintenance

`MaintenanceDisabled = 1` requests that Windows stop automatic maintenance. Leave it unselected if you rely on Windows to schedule maintenance in the background.

**Path:** `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance`

---

### 13. DirectX

Open **GPU Tweaks → DirectX Preset** to review the full set, or use **Individual Tweaks** to select specific entries. The preset writes these values under `HKLM:\SOFTWARE\Microsoft\DirectX`.

| Registry value | Type | Value |
| --- | --- | --- |
| `D3D12_ENABLE_UNSAFE_COMMAND_BUFFER_REUSE` | `DWord` | `1` |
| `D3D12_ENABLE_RUNTIME_DRIVER_OPTIMIZATIONS` | `DWord` | `1` |
| `D3D12_RESOURCE_ALIGNMENT` | `DWord` | `1` |
| `D3D11_MULTITHREADED` | `DWord` | `1` |
| `D3D12_MULTITHREADED` | `DWord` | `1` |
| `D3D11_DEFERRED_CONTEXTS` | `DWord` | `1` |
| `D3D12_DEFERRED_CONTEXTS` | `DWord` | `1` |
| `D3D11_ALLOW_TILING` | `DWord` | `1` |
| `D3D11_ENABLE_DYNAMIC_CODEGEN` | `DWord` | `1` |
| `D3D12_ALLOW_TILING` | `DWord` | `1` |
| `D3D12_CPU_PAGE_TABLE_ENABLED` | `DWord` | `1` |
| `D3D12_HEAP_SERIALIZATION_ENABLED` | `DWord` | `1` |
| `D3D12_MAP_HEAP_ALLOCATIONS` | `DWord` | `1` |
| `D3D12_RESIDENCY_MANAGEMENT_ENABLED` | `DWord` | `1` |

---

## Power Management

Open **Performance Tweaks → Power Settings**. **Enable Ultimate Performance** activates that plan and records the previous plan for Undo. **Open Windows Power Plans** opens Power Options, where you can switch to Balanced or another available plan.

The advanced standby and idle options are separate from the plan picker. They can increase heat and battery drain.

| Action | Effect |
|---|---|
| `CsEnabled = 0` | Disables Connected Standby |
| `PlatformAoAcOverride = 0` | Disables AC/DC platform override |
| `PerfEnablePackageIdle = 0` | Disables CPU package idle states (C-states) |
| `CPPCEnable = 0` | Disables Collaborative Processor Performance Control |
| `AllowPepPerfStates = 0` | Disables Platform Energy Provider states |
| `ASPMOptOut = 1` | Disables PCIe Active State Power Management |

**Paths:**
- `HKLM:\SYSTEM\CurrentControlSet\Control\Power`
- `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Throttle`
- `HKLM:\SYSTEM\CurrentControlSet\Control\Processor`
- `HKLM:\SYSTEM\CurrentControlSet\Services\pci\Parameters`

Sources: [Ancels Performance Batch](https://github.com/ancel1x/Ancels-Performance-Batch), [Power Tweaks](https://youtu.be/5omPOfsJNSo)

---

## GPU-Specific Tweaks

### NVIDIA

A deferred procedure call (DPC) lets a driver run follow-up work after an interrupt. **Review NVIDIA Preset** shows the per-CPU DPC override as one action with five registry writes. How the driver responds depends on the driver version.

**Registry key:** `RmGpsPsEnablePerCpuCoreDpc = 1`

Applied to:
- `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers`
- `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power`
- `HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm`
- `HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\NVAPI`
- `HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak`

Source: [AlchemyTweaks NVIDIA](https://github.com/AlchemyTweaks/Verified-Tweaks)

### AMD

Open **Review AMD Preset** for a summary, then choose **View Details** to see the target driver entry and all 30 values. Use **Individual Tweaks** to select specific changes.

- **Power behavior** includes UVD, VCE, DRMDMA and general power gating, plus GPU power-down settings.
- **Driver timing** includes LTR, display, compute, memory clock-switch and BGM values.
- **Other driver settings** include overlay, snapshot, color depth, stutter mode, DMA copy and block write controls.

**Path:** `HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}`, under the detected AMD driver entry.

<details>
<summary>All 30 AMD registry values</summary>

| Registry value | Type | Value |
| --- | --- | --- |
| `AllowSnapshot` | `DWord` | `0` |
| `AllowSubscription` | `DWord` | `0` |
| `AllowRSOverlay` | `String` | `"false"` |
| `AllowSkins` | `String` | `"false"` |
| `AutoColorDepthReduction_NA` | `DWord` | `0` |
| `DisableUVDPowerGatingDynamic` | `DWord` | `1` |
| `DisableVCEPowerGating` | `DWord` | `1` |
| `DisablePowerGating` | `DWord` | `1` |
| `DisableDrmdmaPowerGating` | `DWord` | `1` |
| `DisableDMACopy` | `DWord` | `1` |
| `DisableBlockWrite` | `DWord` | `0` |
| `StutterMode` | `DWord` | `0` |
| `PP_GPUPowerDownEnabled` | `DWord` | `0` |
| `LTRSnoopL1Latency` | `DWord` | `1` |
| `LTRSnoopL0Latency` | `DWord` | `1` |
| `LTRNoSnoopL1Latency` | `DWord` | `1` |
| `LTRMaxNoSnoopLatency` | `DWord` | `1` |
| `KMD_RpmComputeLatency` | `DWord` | `1` |
| `DalUrgentLatencyNs` | `DWord` | `1` |
| `memClockSwitchLatency` | `DWord` | `1` |
| `PP_RTPMComputeF1Latency` | `DWord` | `1` |
| `PP_DGBMMMaxTransitionLatencyUvd` | `DWord` | `1` |
| `PP_DGBPMMaxTransitionLatencyGfx` | `DWord` | `1` |
| `DalNBLatencyForUnderFlow` | `DWord` | `1` |
| `BGM_LTRSnoopL1Latency` | `DWord` | `1` |
| `BGM_LTRSnoopL0Latency` | `DWord` | `1` |
| `BGM_LTRNoSnoopL1Latency` | `DWord` | `1` |
| `BGM_LTRNoSnoopL0Latency` | `DWord` | `1` |
| `BGM_LTRMaxSnoopLatencyValue` | `DWord` | `1` |
| `BGM_LTRMaxNoSnoopLatencyValue` | `DWord` | `1` |

</details>

## Free Up Disk Space

Open **Set Up Windows → Additional Tools → Free Up Disk Space**.

### Reserved Storage

Check the current state and choose **Enable** or **Disable**. Windows servicing can block the change. The space recovered depends on the installation.

### Clean Windows Components

Runs `DISM /Online /Cleanup-Image /StartComponentCleanup` to remove superseded Windows components. Review the operation before running it.

### PC Manager

Open Microsoft PC Manager if it is installed, or install it from the prompt.

## How to Revert

1. Open **Undo Changes → Action History**.
2. Select the operation and review the values Winrift can restore.
3. Confirm the restore and restart if the setting calls for it.

Winrift uses the recorded previous value and checks for later edits before writing. Use **Restore Configuration Backup** for saved app configs. For component cleanup and actions taken inside external tools, use the recovery options available for that operation.

If you want a Windows restore point before applying tweaks, open **Create a restore point** from the Start menu and create one under **System Protection**. To restore to an existing point later, run `rstrui.exe` and select it.

---

## Reference Sources

- [AlchemyTweaks/Verified-Tweaks](https://github.com/AlchemyTweaks/Verified-Tweaks)
- [SanGraphic/QuickBoost](https://github.com/SanGraphic/QuickBoost)
- [UnLovedCookie/CoutX](https://github.com/UnLovedCookie/CoutX)
- [Snowfliger/SyncOS](https://github.com/Snowfliger/SyncOS)
- [denis-g/windows10-latency-optimization](https://github.com/denis-g/windows10-latency-optimization)
- [ancel1x/Ancels-Performance-Batch](https://github.com/ancel1x/Ancels-Performance-Batch)

## Pinned source comparison

The upstream snapshot is [AlchemyTweaks/Verified-Tweaks at 9b8d96d](https://github.com/AlchemyTweaks/Verified-Tweaks/tree/9b8d96d2d60eac53fc688f718726006321818d62). `tests/fixtures/alchemy-approved.json` records the compared values and source identifiers.

- [NVIDIA per-CPU DPC](https://github.com/AlchemyTweaks/Verified-Tweaks/blob/9b8d96d2d60eac53fc688f718726006321818d62/Nvidia/RmGpsPsEnablePerCpuCoreDpc/RmGpsPsEnablePerCpuCoreDpc.reg): all five path/name/type/value writes match. The picker presents one logical action.
- [AMD Melody](https://github.com/AlchemyTweaks/Verified-Tweaks/blob/9b8d96d2d60eac53fc688f718726006321818d62/AMD%20Radeon/AMD%20Tweak%20Melody/AMD%20Tweak%20Melody.reg): all 30 names/types/values match, with the fixed 0000 source path replaced by an actually present AMD driver key.
- [DirectX](https://github.com/AlchemyTweaks/Verified-Tweaks/blob/9b8d96d2d60eac53fc688f718726006321818d62/DirectX/D3D11%20-%20D3D12%20Tweaks/D3D11%20-%20D3D12%20Tweaks.bat): all 14 existing writes match.

The comparison checks the entries in the presets. See [validation notes](validation.md) for the test environment and outstanding hardware checks.

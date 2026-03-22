. "$PSScriptRoot\..\..\scripts\Common.ps1"

# {4d36e968-e325-11ce-bfc1-08002be10318} = Display Adapters device class GUID
$DISPLAY_ADAPTER_CLASS = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"

function Get-DisplayAdapterIndices {
    # Dynamically enumerate all display adapter registry indices instead of hardcoding 0000-0003
    if (-not (Test-Path $DISPLAY_ADAPTER_CLASS)) { return @() }
    Get-ChildItem -Path $DISPLAY_ADAPTER_CLASS -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -match '^\d{4}$' } |
        ForEach-Object { $_.PSChildName }
}

function Show-GPUMenu {
    Invoke-MenuLoop -Title "GPU-Specific Tweaks" -Items @(
        "[1] NVIDIA",
        "[2] AMD",
        "[3] Both (Hybrid Laptop)",
        "---",
        "[4] Back to menu"
    ) -Actions @{
        "1" = { Invoke-NvidiaTweaks }
        "2" = { Invoke-AMDTweaks }
        "3" = { Invoke-HybridTweaks }
    } -ExitKey "4"
}

function Invoke-HybridTweaks {
    Write-Log -Message "Applying tweaks for hybrid GPU configuration (NVIDIA + AMD)..." -Level INFO
    $nvidiaOk = Invoke-NvidiaTweaks -NoExit
    $amdOk = Invoke-AMDTweaks -NoExit

    if ($nvidiaOk -and $amdOk) {
        Write-Log -Message "Successfully applied tweaks for both NVIDIA and AMD GPUs." -Level SUCCESS
    } elseif ($nvidiaOk) {
        Write-Log -Message "Applied NVIDIA tweaks. AMD GPU was not detected." -Level WARNING
    } elseif ($amdOk) {
        Write-Log -Message "Applied AMD tweaks. NVIDIA GPU was not detected." -Level WARNING
    } else {
        Write-Log -Message "No supported GPUs detected." -Level ERROR
    }
    Write-Host ""
    Write-Host "$Purple Press any key to return to the GPU menu...$Reset"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-NvidiaTweaks {
    param (
        [switch]$NoExit
    )

    # source - https://github.com/AlchemyTweaks/Verified-Tweaks/blob/main/Nvidia/RmGpsPsEnablePerCpuCoreDpc
    $nvidiaFound = $false
    foreach ($idx in (Get-DisplayAdapterIndices)) {
        $devPath = "$DISPLAY_ADAPTER_CLASS\$idx"
        $provider = (Get-ItemProperty -Path $devPath -Name "ProviderName" -ErrorAction SilentlyContinue).ProviderName
        if ($provider -match "NVIDIA") {
            $nvidiaFound = $true
            break
        }
    }
    if (-not $nvidiaFound) {
        Write-Log -Message "No NVIDIA GPU found in display adapter registry. Skipping NVIDIA tweaks." -Level WARNING
        if (-not $NoExit) {
            Write-Host "`n$Purple Press any key to return to the GPU menu...$Reset"
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        return $false
    }

    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enabled per-CPU core DPC for NVIDIA drivers"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enabled power-aware per-CPU core DPC"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enabled NVIDIA driver per-CPU core DPC"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\NVAPI" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enabled NVIDIA API per-CPU core DPC"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enabled global NVIDIA tweaks for per-CPU core DPC"

    if (-not $NoExit) {
        Write-Host ""
        Write-Host "$Purple Press any key to return to the GPU menu...$Reset"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    return $true
}

function Invoke-AMDTweaks {
    param (
        [switch]$NoExit
    )

    # source - https://youtu.be/nuUV2RoPOWc , https://github.com/AlchemyTweaks/Verified-Tweaks/blob/main/AMD%20Radeon/AMD%20Tweak%20Melody
    $amdPath = $null
    foreach ($idx in (Get-DisplayAdapterIndices)) {
        $devPath = "$DISPLAY_ADAPTER_CLASS\$idx"
        $provider = (Get-ItemProperty -Path $devPath -Name "ProviderName" -ErrorAction SilentlyContinue).ProviderName
        if ($provider -match "AMD|ATI|Advanced Micro Devices") {
            $amdPath = $devPath
            break
        }
    }
    if (-not $amdPath) {
        Write-Log -Message "No AMD GPU found in display adapter registry. Skipping AMD tweaks." -Level WARNING
        if (-not $NoExit) {
            Write-Host "`n$Purple Press any key to return to the GPU menu...$Reset"
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        return $false
    }
    Write-Log -Message "Found AMD GPU at $amdPath" -Level INFO
    Set-RegistryValue -Path $amdPath -Name "AllowSnapshot" -Type "DWord" -Value "0" -Message "Disabled AMD snapshot feature"
    Set-RegistryValue -Path $amdPath -Name "AllowSubscription" -Type "DWord" -Value "0" -Message "Disabled AMD subscription feature"
    Set-RegistryValue -Path $amdPath -Name "AllowRSOverlay" -Type "String" -Value "false" -Message "Disabled AMD RS overlay"
    Set-RegistryValue -Path $amdPath -Name "AllowSkins" -Type "String" -Value "false" -Message "Disabled AMD skins"
    Set-RegistryValue -Path $amdPath -Name "AutoColorDepthReduction_NA" -Type "DWord" -Value "0" -Message "Disabled automatic color depth reduction"
    Set-RegistryValue -Path $amdPath -Name "DisableUVDPowerGatingDynamic" -Type "DWord" -Value "1" -Message "Disabled UVD power gating"
    Set-RegistryValue -Path $amdPath -Name "DisableVCEPowerGating" -Type "DWord" -Value "1" -Message "Disabled VCE power gating"
    Set-RegistryValue -Path $amdPath -Name "DisablePowerGating" -Type "DWord" -Value "1" -Message "Disabled general power gating"
    Set-RegistryValue -Path $amdPath -Name "DisableDrmdmaPowerGating" -Type "DWord" -Value "1" -Message "Disabled DRMDMA power gating"
    Set-RegistryValue -Path $amdPath -Name "DisableDMACopy" -Type "DWord" -Value "1" -Message "Disabled DMA copy"
    Set-RegistryValue -Path $amdPath -Name "DisableBlockWrite" -Type "DWord" -Value "0" -Message "Enabled block write"
    Set-RegistryValue -Path $amdPath -Name "StutterMode" -Type "DWord" -Value "0" -Message "Disabled stutter mode"
    Set-RegistryValue -Path $amdPath -Name "PP_GPUPowerDownEnabled" -Type "DWord" -Value "0" -Message "Disabled GPU power down"
    Set-RegistryValue -Path $amdPath -Name "LTRSnoopL1Latency" -Type "DWord" -Value "1" -Message "Optimized LTR Snoop L1 latency"
    Set-RegistryValue -Path $amdPath -Name "LTRSnoopL0Latency" -Type "DWord" -Value "1" -Message "Optimized LTR Snoop L0 latency"
    Set-RegistryValue -Path $amdPath -Name "LTRNoSnoopL1Latency" -Type "DWord" -Value "1" -Message "Optimized LTR No Snoop L1 latency"
    Set-RegistryValue -Path $amdPath -Name "LTRMaxNoSnoopLatency" -Type "DWord" -Value "1" -Message "Optimized LTR max no snoop latency"
    Set-RegistryValue -Path $amdPath -Name "KMD_RpmComputeLatency" -Type "DWord" -Value "1" -Message "Optimized KMD RPM compute latency"
    Set-RegistryValue -Path $amdPath -Name "DalUrgentLatencyNs" -Type "DWord" -Value "1" -Message "Optimized DAL urgent latency"
    Set-RegistryValue -Path $amdPath -Name "memClockSwitchLatency" -Type "DWord" -Value "1" -Message "Optimized memory clock switch latency"
    Set-RegistryValue -Path $amdPath -Name "PP_RTPMComputeF1Latency" -Type "DWord" -Value "1" -Message "Optimized RTPM compute F1 latency"
    Set-RegistryValue -Path $amdPath -Name "PP_DGBMMMaxTransitionLatencyUvd" -Type "DWord" -Value "1" -Message "Optimized DGBMM UVD transition latency"
    Set-RegistryValue -Path $amdPath -Name "PP_DGBPMMaxTransitionLatencyGfx" -Type "DWord" -Value "1" -Message "Optimized DGBPM GFX transition latency"
    Set-RegistryValue -Path $amdPath -Name "DalNBLatencyForUnderFlow" -Type "DWord" -Value "1" -Message "Optimized DAL NB underflow latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRSnoopL1Latency" -Type "DWord" -Value "1" -Message "Optimized BGM LTR Snoop L1 latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRSnoopL0Latency" -Type "DWord" -Value "1" -Message "Optimized BGM LTR Snoop L0 latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRNoSnoopL1Latency" -Type "DWord" -Value "1" -Message "Optimized BGM LTR No Snoop L1 latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRNoSnoopL0Latency" -Type "DWord" -Value "1" -Message "Optimized BGM LTR No Snoop L0 latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRMaxSnoopLatencyValue" -Type "DWord" -Value "1" -Message "Optimized BGM LTR max snoop latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRMaxNoSnoopLatencyValue" -Type "DWord" -Value "1" -Message "Optimized BGM LTR max no snoop latency"

    if (-not $NoExit) {
        Write-Host ""
        Write-Host "$Purple Press any key to return to the GPU menu...$Reset"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    return $true
}

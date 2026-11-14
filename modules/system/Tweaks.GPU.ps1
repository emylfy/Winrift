# {4d36e968-e325-11ce-bfc1-08002be10318} = Display Adapters device class GUID
$DISPLAY_ADAPTER_CLASS = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"

function Get-DisplayAdapterIndices {
    # Resolve registry keys only for present display adapters, excluding stale
    # driver class entries left by removed hardware.
    foreach ($device in @(Get-PnpDevice -PresentOnly -Class Display -ErrorAction SilentlyContinue)) {
        $property = Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName 'DEVPKEY_Device_Driver' -ErrorAction SilentlyContinue
        if ($property.Data -match '\\(\d{4})$' -and (Test-Path "$DISPLAY_ADAPTER_CLASS\$($Matches[1])")) { $Matches[1] }
    }
}

function Show-GPUMenu {
    $vendors = @()
    foreach ($index in @(Get-DisplayAdapterIndices)) {
        $provider = (Get-ItemProperty "$DISPLAY_ADAPTER_CLASS\$index" -ErrorAction SilentlyContinue).ProviderName
        if ($provider -match 'NVIDIA') { $vendors += 'NVIDIA' }
        elseif ($provider -match '\bAMD\b|\bATI\b|Advanced Micro Devices') { $vendors += 'AMD' }
    }
    $items = @()
    if ($vendors -contains 'NVIDIA') { $items += 'N › Review NVIDIA Preset             ›' }
    if ($vendors -contains 'AMD') { $items += 'A › Review AMD Preset                ›' }
    $items += @('G › GPU Scheduling & Preemption       ›', 'D › DirectX Preset                    ›', '---', '0 › Back')
    Invoke-MenuLoop -Title 'GPU Tweaks' -Items $items -Actions @{
        'N' = { Show-WinriftGpuPreset NVIDIA }
        'A' = { Show-WinriftGpuPreset AMD }
        'G' = { Show-WinriftTweakSelection 'GPU Scheduling & Preemption — compatibility varies' { Invoke-GPUTweaks } }
        'D' = { Show-WinriftGpuPreset DirectX }
    } -ExitKey '0' -HideKeys
}

function Show-WinriftGpuPreset {
    param([ValidateSet('NVIDIA','AMD','DirectX')][string]$Vendor)
    $collector = switch ($Vendor) {
        'NVIDIA' { { $null = Invoke-NvidiaTweaks -NoExit } }
        'AMD' { { $null = Invoke-AMDTweaks -NoExit } }
        'DirectX' { { Invoke-DirectXTweaks } }
    }
    Clear-AuditQueue; $script:CollectMode=$true
    try { & $collector } finally { $script:CollectMode=$false }
    $entries = @($script:AuditQueue.ToArray())
    Clear-AuditQueue
    if (-not $entries.Count) { Write-Log 'No applicable preset for detected hardware.'; Wait-ForUser; return }
    $choice = Show-InteractiveMenu -Title "Review $Vendor Preset" -Items @(
        'Experimental preset: hardware benefit and stability have not been established.',
        'Source matching verifies preset values, not driver support or performance gain.',
        'May change stability, power use or rendering behavior.',
        $(if ($Vendor -eq 'NVIDIA') { 'One logical per-CPU DPC action, written to five locations.' } elseif ($Vendor -eq 'DirectX') { 'Changes 14 D3D11 and D3D12 settings.' } else { 'Changes 30 AMD driver settings from the Melody preset.' }),
        '---', 'Y › Apply Preset', 'V › View Details', 'I › Individual Tweaks', 'N › Back'
    )
    if ($choice -eq 'V') {
        Show-InfoBox "$Vendor Preset Details" @($entries | ForEach-Object { "$($_.Path)\$($_.Name) = $($_.Value) ($($_.Type))" })
        Wait-ForUser; Show-WinriftGpuPreset $Vendor; return
    }
    if ($choice -eq 'I') {
        if($Vendor -eq 'NVIDIA'){
            $selection=@(Show-MultiSelect -Title 'NVIDIA Individual Tweaks' -Items @('DPC › Per-CPU DPC preset (five writes, one action)'))
            if($selection -notcontains 'DPC'){return}
            $choice='Y'
        }else{Show-WinriftTweakSelection "$Vendor Individual Tweaks" $collector;return}
    }
    if ($choice -ne 'Y') { return }
    foreach ($entry in $entries) { $script:AuditQueue.Add($entry) }
    Invoke-WinriftTweakApplyWithResults -Title "$Vendor Preset Results" -MayRequireRestart
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
        if (-not $NoExit) { Wait-ForUser }
        return $false
    }

    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enable per-CPU core DPC for NVIDIA drivers"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enable power-aware per-CPU core DPC"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enable NVIDIA driver per-CPU core DPC"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\NVAPI" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enable NVIDIA API per-CPU core DPC"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enable global NVIDIA tweaks for per-CPU core DPC"
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
        if ($provider -match "\bAMD\b|\bATI\b|Advanced Micro Devices") {
            $amdPath = $devPath
            break
        }
    }
    if (-not $amdPath) {
        Write-Log -Message "No AMD GPU found in display adapter registry. Skipping AMD tweaks." -Level WARNING
        if (-not $NoExit) { Wait-ForUser }
        return $false
    }
    Write-Log -Message "Found AMD GPU at $amdPath" -Level INFO
    Set-RegistryValue -Path $amdPath -Name "AllowSnapshot" -Type "DWord" -Value "0" -Message "Disable AMD snapshot feature"
    Set-RegistryValue -Path $amdPath -Name "AllowSubscription" -Type "DWord" -Value "0" -Message "Disable AMD subscription feature"
    Set-RegistryValue -Path $amdPath -Name "AllowRSOverlay" -Type "String" -Value "false" -Message "Disable AMD RS overlay"
    Set-RegistryValue -Path $amdPath -Name "AllowSkins" -Type "String" -Value "false" -Message "Disable AMD skins"
    Set-RegistryValue -Path $amdPath -Name "AutoColorDepthReduction_NA" -Type "DWord" -Value "0" -Message "Disable automatic color depth reduction"
    Set-RegistryValue -Path $amdPath -Name "DisableUVDPowerGatingDynamic" -Type "DWord" -Value "1" -Message "Disable UVD power gating"
    Set-RegistryValue -Path $amdPath -Name "DisableVCEPowerGating" -Type "DWord" -Value "1" -Message "Disable VCE power gating"
    Set-RegistryValue -Path $amdPath -Name "DisablePowerGating" -Type "DWord" -Value "1" -Message "Disable general power gating"
    Set-RegistryValue -Path $amdPath -Name "DisableDrmdmaPowerGating" -Type "DWord" -Value "1" -Message "Disable DRMDMA power gating"
    Set-RegistryValue -Path $amdPath -Name "DisableDMACopy" -Type "DWord" -Value "1" -Message "Disable DMA copy"
    Set-RegistryValue -Path $amdPath -Name "DisableBlockWrite" -Type "DWord" -Value "0" -Message "Enable block write"
    Set-RegistryValue -Path $amdPath -Name "StutterMode" -Type "DWord" -Value "0" -Message "Disable stutter mode"
    Set-RegistryValue -Path $amdPath -Name "PP_GPUPowerDownEnabled" -Type "DWord" -Value "0" -Message "Disable GPU power down"
    Set-RegistryValue -Path $amdPath -Name "LTRSnoopL1Latency" -Type "DWord" -Value "1" -Message "Set LTR Snoop L1 latency"
    Set-RegistryValue -Path $amdPath -Name "LTRSnoopL0Latency" -Type "DWord" -Value "1" -Message "Set LTR Snoop L0 latency"
    Set-RegistryValue -Path $amdPath -Name "LTRNoSnoopL1Latency" -Type "DWord" -Value "1" -Message "Set LTR No Snoop L1 latency"
    Set-RegistryValue -Path $amdPath -Name "LTRMaxNoSnoopLatency" -Type "DWord" -Value "1" -Message "Set LTR max no snoop latency"
    Set-RegistryValue -Path $amdPath -Name "KMD_RpmComputeLatency" -Type "DWord" -Value "1" -Message "Set KMD RPM compute latency"
    Set-RegistryValue -Path $amdPath -Name "DalUrgentLatencyNs" -Type "DWord" -Value "1" -Message "Set DAL urgent latency"
    Set-RegistryValue -Path $amdPath -Name "memClockSwitchLatency" -Type "DWord" -Value "1" -Message "Set memory clock switch latency"
    Set-RegistryValue -Path $amdPath -Name "PP_RTPMComputeF1Latency" -Type "DWord" -Value "1" -Message "Set RTPM compute F1 latency"
    Set-RegistryValue -Path $amdPath -Name "PP_DGBMMMaxTransitionLatencyUvd" -Type "DWord" -Value "1" -Message "Set DGBMM UVD transition latency"
    Set-RegistryValue -Path $amdPath -Name "PP_DGBPMMaxTransitionLatencyGfx" -Type "DWord" -Value "1" -Message "Set DGBPM GFX transition latency"
    Set-RegistryValue -Path $amdPath -Name "DalNBLatencyForUnderFlow" -Type "DWord" -Value "1" -Message "Set DAL NB underflow latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRSnoopL1Latency" -Type "DWord" -Value "1" -Message "Set BGM LTR Snoop L1 latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRSnoopL0Latency" -Type "DWord" -Value "1" -Message "Set BGM LTR Snoop L0 latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRNoSnoopL1Latency" -Type "DWord" -Value "1" -Message "Set BGM LTR No Snoop L1 latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRNoSnoopL0Latency" -Type "DWord" -Value "1" -Message "Set BGM LTR No Snoop L0 latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRMaxSnoopLatencyValue" -Type "DWord" -Value "1" -Message "Set BGM LTR max snoop latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRMaxNoSnoopLatencyValue" -Type "DWord" -Value "1" -Message "Set BGM LTR max no snoop latency"

    return $true
}

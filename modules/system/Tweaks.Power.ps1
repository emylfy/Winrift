. "$PSScriptRoot\..\..\scripts\Common.ps1"
# https://github.com/ancel1x/Ancels-Performance-Batch

function Invoke-PowerMenu {
    Clear-Host
    Show-MenuBox -Title "Power Management" -Items @(
        "For desktops and laptops on AC power.",
        "Disables Connected Standby, CPU idle states,",
        "and PCIe ASPM. Skip if on battery.",
        "---",
        "1 › Apply Power Management Tweaks",
        "2 › Back to menu"
    )
    $choice = Read-Host ">"
    if ($choice -eq "1") {
        New-SafeRestorePoint
        Start-TweakSession
        $script:DesiredStateCategory = "Aggressive Power Management"
        Invoke-AggressivePowerTweaks
        Save-TweakBackup
        Save-DesiredState
        Write-Host ""
        Write-Host "$Green Power Management tweaks applied successfully.$Reset"
        Write-Host "$Yellow A system restart is recommended for all changes to take effect.$Reset"
        Write-Host "`n$Purple Press any key to return...$Reset"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Invoke-AggressivePowerTweaks {
    Write-Host "`nApplying Aggressive Power Management tweaks...`n"

    $chassis = (Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue).ChassisTypes
    # ChassisTypes 9,10,14 = Laptop/Notebook/Sub Notebook
    if ($chassis | Where-Object { $_ -in @(9, 10, 14) }) {
        Write-Log -Message "WARNING: Laptop detected. These tweaks disable sleep/idle states and ASPM, which increases heat and battery drain. Skip if not on AC power." -Level WARNING
    }

    # source - https://github.com/ancel1x/Ancels-Performance-Batch
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "CsEnabled" -Type "DWord" -Value "0" -Message "Disabled connected standby for better performance"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PlatformAoAcOverride" -Type "DWord" -Value "0" -Message "Disabled AC/DC platform power behavior override"

    # CPU Throttling - prevents idle C-states
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Throttle" -Name "PerfEnablePackageIdle" -Type "DWord" -Value "0" -Message "Disabled CPU package idle states"

    # Processor Power Management
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Processor" -Name "CPPCEnable" -Type "DWord" -Value "0" -Message "Disabled Collaborative Processor Performance Control"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Processor" -Name "AllowPepPerfStates" -Type "DWord" -Value "0" -Message "Disabled Platform Energy Provider performance states"

    # PCIe Power Saving (ASPM)
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\pci\Parameters" -Name "ASPMOptOut" -Type "DWord" -Value "1" -Message "Disabled PCIe ASPM power saving"

    # Activate Hidden Ultimate Performance Power Plan
    # e9a42b02-... = built-in Ultimate Performance scheme GUID (hidden by default)
    # eeeeeeee-... = custom GUID for the duplicated plan to avoid conflicts
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee 2>$null | Out-Null
    powercfg -setactive eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Log -Message "Activated Ultimate Performance power plan" -Level SUCCESS
    } else {
        Write-Log -Message "Failed to activate Ultimate Performance plan (exit code: $LASTEXITCODE)" -Level ERROR
    }
}

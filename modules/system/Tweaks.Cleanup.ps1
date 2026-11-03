$PC_MANAGER_AUMID = "Microsoft.MicrosoftPCManager_8wekyb3d8bbwe!App"
$PC_MANAGER_STORE = "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9pm860492szd&storecid=storeweb-pdp-open-cta"

function Clear-SystemSpace {
    Invoke-MenuLoop -Title 'Free Up Disk Space' -Items @(
        '1 › Clean Windows Components         ›',
        '2 › Reserved Storage                 ›',
        '3 › Open Microsoft PC Manager        ↗', '---', '0 › Back'
    ) -Actions @{
        '1' = {
            $choice = Show-InteractiveMenu -Title 'Review Component Cleanup' -Items @(
                'Remove superseded Windows component versions using DISM.',
                'This cleanup is not reversible through Winrift Undo.',
                'Command: DISM /Online /Cleanup-Image /StartComponentCleanup',
                '---', 'Y › Apply', 'N › Back'
            )
            if ($choice -ne 'Y') { return }
            if ($env:WINRIFT_DRY_RUN -eq '1') { Write-Log '[DRY-RUN] DISM /Online /Cleanup-Image /StartComponentCleanup' }
            else { $null=Invoke-NativeCommand -Command dism.exe -Arguments @('/Online','/Cleanup-Image','/StartComponentCleanup') -SuccessMessage 'Component cleanup command completed.' -ErrorMessage 'Component cleanup failed' }
            Wait-ForUser
        }
        '2' = { Show-WinriftReservedStorage }
        '3' = {
            if ($env:WINRIFT_DRY_RUN -eq '1') { Write-Log '[DRY-RUN] Open or offer PC Manager installation'; Wait-ForUser; return }
            $app = Get-AppxPackage -Name Microsoft.MicrosoftPCManager -ErrorAction SilentlyContinue
            if ($app) { Start-Process "shell:AppsFolder\$PC_MANAGER_AUMID"; return }
            $choice=Show-InteractiveMenu -Title 'Microsoft PC Manager' -Items @('Y › Install PC Manager', 'N › Back')
            if ($choice -eq 'Y') {
                if (Install-WingetPackage '9PM860492SZD' 'PC Manager' -Source msstore) { Start-Process "shell:AppsFolder\$PC_MANAGER_AUMID" }
                Wait-ForUser
            }
        }
    } -ExitKey '0' -HideKeys
}

function Show-WinriftReservedStorage {
    try {
        $state=Get-WindowsReservedStorageState -Online -ErrorAction Stop
    } catch { Write-Log "Reserved Storage state unavailable: $($_.Exception.Message)" -Level WARNING; Wait-ForUser; return }
    $choice=Show-InteractiveMenu -Title 'Reserved Storage' -Items @(
        "Current state: $state. Space use varies; no fixed amount is promised.",
        '1 › Enable', '2 › Disable', '---', '0 › Back'
    )
    if ($choice -notin @('1','2')) { return }
    $proposed=if ($choice -eq '1') { 'Enabled' } else { 'Disabled' }
    $confirm=Show-InteractiveMenu -Title 'Review Reserved Storage' -Items @("Current: $state", "Proposed: $proposed", 'Windows servicing may prevent this operation.', '---','Y › Apply','N › Back')
    if ($confirm -ne 'Y') { return }
    if ($env:WINRIFT_DRY_RUN -eq '1') { Write-Log "[DRY-RUN] Reserved Storage: $proposed"; Wait-ForUser; return }
    try {
        Set-WindowsReservedStorageState -Online -State $proposed -ErrorAction Stop | Out-Null
        $after=Get-WindowsReservedStorageState -Online -ErrorAction Stop
        if ("$after" -ne $proposed) { throw "State query returned $after" }
        Write-Log "Reserved Storage state verified: $after" -Level SUCCESS
    } catch { Write-Log "Reserved Storage change failed: $($_.Exception.Message)" -Level ERROR }
    Wait-ForUser
}
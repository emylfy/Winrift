. "$PSScriptRoot\..\..\scripts\Common.ps1"

# Named Constants
$WINGET_ALREADY_INSTALLED = -1978335189  # Winget exit code when package is already installed
$PC_MANAGER_AUMID = "Microsoft.MicrosoftPCManager_8wekyb3d8bbwe!App"
$PC_MANAGER_STORE = "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9pm860492szd&storecid=storeweb-pdp-open-cta"

function Clear-SystemSpace {
    $Host.UI.RawUI.WindowTitle = "System Cleaner"

    Invoke-MenuLoop -Title "Free Up Disk Space" -Items @(
        "[1] Disable Reserved Storage (up to 7GB for Windows updates)",
        "[2] Clean up WinSxS (remove old component versions)",
        "[3] Install and Launch PC Manager (Official Microsoft Utility)",
        "---",
        "[4] Back to menu"
    ) -Actions @{
        "1" = {
            Write-Log -Message "Disabling Reserved Storage..." -Level INFO
            Invoke-NativeCommand -Command "dism" `
                -Arguments @("/Online", "/Set-ReservedStorageState", "/State:Disabled") `
                -SuccessMessage "Reserved Storage disabled." `
                -ErrorMessage "Failed to disable Reserved Storage"
            Read-Host "Press Enter to continue"
        }
        "2" = {
            Write-Log -Message "Cleaning up WinSxS (this may take several minutes)..." -Level INFO
            Invoke-NativeCommand -Command "dism" `
                -Arguments @("/Online", "/Cleanup-Image", "/StartComponentCleanup", "/ResetBase", "/RestoreHealth") `
                -SuccessMessage "WinSxS cleanup complete." `
                -ErrorMessage "WinSxS cleanup encountered issues"
            Read-Host "Press Enter to continue"
        }
        "3" = {
            if (-not (Assert-WingetAvailable)) { Read-Host "Press Enter to continue"; return }
            Write-Log -Message "Installing PC Manager..." -Level INFO
            & winget install Microsoft.PCManager --accept-package-agreements --accept-source-agreements

            if ($LASTEXITCODE -eq 0) {
                Write-Log -Message "Successfully installed PC Manager." -Level SUCCESS
                Start-Sleep -Seconds 2
                Start-Process "shell:AppsFolder\$PC_MANAGER_AUMID"
            } elseif ($LASTEXITCODE -eq $WINGET_ALREADY_INSTALLED) {
                Write-Log -Message "PC Manager is already installed. Launching..." -Level INFO
                Start-Process "shell:AppsFolder\$PC_MANAGER_AUMID"
            } else {
                Write-Log -Message "Failed to install PC Manager (exit code: $LASTEXITCODE). Please try manually." -Level ERROR
                Start-Process $PC_MANAGER_STORE
                Read-Host "Press Enter to continue"
            }
        }
    } -ExitKey "4"
}

. "$PSScriptRoot\..\..\scripts\Common.ps1"

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
            $null = Invoke-NativeCommand -Command "dism" `
                -Arguments @("/Online", "/Set-ReservedStorageState", "/State:Disabled") `
                -SuccessMessage "Reserved Storage disabled." `
                -ErrorMessage "Failed to disable Reserved Storage"
            Read-Host "Press Enter to continue"
        }
        "2" = {
            Write-Log -Message "Cleaning up WinSxS (this may take several minutes)..." -Level INFO
            $null = Invoke-NativeCommand -Command "dism" `
                -Arguments @("/Online", "/Cleanup-Image", "/StartComponentCleanup", "/ResetBase", "/RestoreHealth") `
                -SuccessMessage "WinSxS cleanup complete." `
                -ErrorMessage "WinSxS cleanup encountered issues"
            Read-Host "Press Enter to continue"
        }
        "3" = {
            $installed = Install-WingetPackage "9PM860492SZD" "PC Manager" -Source "msstore"
            if ($installed) {
                Start-Sleep -Seconds 2
                Start-Process "shell:AppsFolder\$PC_MANAGER_AUMID"
            } else {
                Start-Process $PC_MANAGER_STORE
                Read-Host "Press Enter to continue"
            }
        }
    } -ExitKey "4"
}

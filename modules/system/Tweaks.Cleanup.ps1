. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Clear-SystemSpace {
    $Host.UI.RawUI.WindowTitle = "System Cleaner"

    while ($true) {
        Clear-Host
        Show-MenuBox -Title "Free Up Disk Space" -Items @(
            "[1] Disable Reserved Storage (up to 7GB for Windows updates)",
            "[2] Clean up WinSxS (remove old component versions)",
            "[3] Remove Virtual Memory (pagefile.sys) - requires 16GB+ RAM",
            "[4] Install and Launch PC Manager (Official Microsoft Utility)",
            "---",
            "[5] Back to menu"
        )

        $choice = Read-Host ">"

        switch ($choice) {
            "1" {
                Write-Log -Message "Disabling Reserved Storage..." -Level INFO
                Invoke-Expression "dism /Online /Set-ReservedStorageState /State:Disabled"
                Write-Log -Message "Reserved Storage disabled." -Level SUCCESS
                Read-Host "Press Enter to continue"
                break
            }
            "2" {
                Write-Log -Message "Cleaning up WinSxS..." -Level INFO
                Invoke-Expression "dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase /RestoreHealth"
                Write-Log -Message "WinSxS cleanup complete." -Level SUCCESS
                Read-Host "Press Enter to continue"
                break
            }
            "3" {
                Write-Host "$Yellow Warning: This may affect system performance. Only use if you have 16GB+ RAM.$Reset"
                $confirm = Read-Host "Are you sure? [Y/N]"
                if ($confirm -eq "Y" -or $confirm -eq "y") {
                    Write-Log -Message "Removing Virtual Memory..." -Level INFO
                    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value ''
                    Write-Log -Message "Virtual Memory removed. Restart required." -Level SUCCESS
                }
                Read-Host "Press Enter to continue"
                break
            }
            "4" {
                Write-Log -Message "Installing PC Manager..." -Level INFO
                $result = Invoke-Expression "winget install Microsoft.PCManager --accept-package-agreements --accept-source-agreements"

                if ($LASTEXITCODE -eq 0) {
                    Write-Log -Message "Successfully installed PC Manager." -Level SUCCESS
                    Start-Sleep -Seconds 2
                    Start-Process "shell:AppsFolder\Microsoft.MicrosoftPCManager_8wekyb3d8bbwe!App"
                } elseif ($LASTEXITCODE -eq -1978335189) {
                    Write-Log -Message "PC Manager is already installed. Launching..." -Level INFO
                    Start-Process "shell:AppsFolder\Microsoft.MicrosoftPCManager_8wekyb3d8bbwe!App"
                } else {
                    Write-Log -Message "Failed to install PC Manager. Please try manually." -Level ERROR
                    Start-Process "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9pm860492szd&storecid=storeweb-pdp-open-cta"
                    Read-Host "Press Enter to continue"
                }
                break
            }
            "5" { return }
            default { }
        }
    }
}

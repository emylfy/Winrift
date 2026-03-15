. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-DeviceMenu {
    $Host.UI.RawUI.WindowTitle = "Simplify11 - Drivers"

    $urls = @{
        "1"  = "https://www.nvidia.com/en-us/software/nvidia-app/"
        "2"  = "https://www.amd.com/en/support/download/drivers.html"
        "3"  = "https://support.hp.com/us-en/drivers"
        "4"  = "https://support.lenovo.com"
        "5"  = "https://www.asus.com/support/download-center/"
        "6"  = "https://www.acer.com/ac/en/US/content/drivers"
        "7"  = "https://www.msi.com/support/download"
        "8"  = "https://www.huawei.com/en/support"
        "9"  = "https://www.xiaomi.com/global/support"
        "10" = "https://www.dell.com/support/home/products/computers?app=drivers"
        "11" = "https://www.gigabyte.com/Support/Consumer/Download"
    }

    while ($true) {
        Clear-Host
        Show-MenuBox -Title "Select your device manufacturer to install drivers" -Items @(
            "[1]  Nvidia App",
            "[2]  AMD Drivers",
            "---",
            "[3]  HP",
            "[4]  Lenovo",
            "[5]  Asus",
            "[6]  Acer",
            "[7]  MSI",
            "[8]  Huawei",
            "[9]  Xiaomi",
            "[10] DELL/Alienware",
            "[11] Gigabyte",
            "---",
            "[Enter] Back to Menu"
        )

        $choice = Read-Host "Select your device manufacturer"

        if ($choice -eq "") {
            return
        } elseif ($choice -eq "4") {
            Show-LenovoMenu
        } elseif ($urls.ContainsKey($choice)) {
            Start-Process $urls[$choice]
        } else {
            Write-Log -Message "Invalid choice. Please try again." -Level ERROR
            Start-Sleep -Seconds 1
        }
    }
}

function Show-LenovoMenu {
    while ($true) {
        Clear-Host
        Show-MenuBox -Title "Lenovo Driver Options" -Items @(
            "[1] Install Lenovo Vantage",
            "[2] Open Lenovo Driver Page",
            "---",
            "[3] Back to Manufacturer Selection"
        )

        $choice = Read-Host ">"

        switch ($choice) {
            "1" {
                Write-Log -Message "Installing Lenovo Vantage..." -Level INFO
                try {
                    winget install "9WZDNCRFJ4MV" --accept-package-agreements --accept-source-agreements
                    if ($LASTEXITCODE -eq 0) {
                        Write-Log -Message "Successfully installed Lenovo Vantage." -Level SUCCESS
                    } else {
                        Write-Log -Message "Failed to install Lenovo Vantage. Please install manually from the Microsoft Store." -Level ERROR
                        Start-Process "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9WZDNCRFJ4MV&storecid=storeweb-pdp-open-cta"
                    }
                } catch {
                    Write-Log -Message "Error installing Lenovo Vantage: $($_.Exception.Message)" -Level ERROR
                }
                Start-Sleep -Seconds 2
                break
            }
            "2" {
                Start-Process "https://support.lenovo.com"
                break
            }
            "3" { return }
            default { }
        }
    }
}

Show-DeviceMenu

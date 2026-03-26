. "$PSScriptRoot\..\..\scripts\Common.ps1"

Initialize-Logging -ModuleName "drivers"

function Show-DeviceMenu {
    $Host.UI.RawUI.WindowTitle = "Winrift - Drivers"

    $urls = @{
        "1"  = "https://www.nvidia.com/en-us/software/nvidia-app/"
        "2"  = "https://www.amd.com/en/support/download/drivers.html"
        "4"  = "https://support.hp.com/us-en/drivers"
        "5"  = "https://support.lenovo.com"
        "6"  = "https://www.asus.com/support/download-center/"
        "7"  = "https://www.acer.com/ac/en/US/content/drivers"
        "8"  = "https://www.msi.com/support/download"
        "9"  = "https://www.huawei.com/en/support"
        "10" = "https://www.xiaomi.com/global/support"
        "11" = "https://www.dell.com/support/home/products/computers?app=drivers"
        "12" = "https://www.gigabyte.com/Support/Consumer/Download"
    }

    while ($true) {
        Clear-Host
        Show-MenuBox -Title "Select your manufacturer" -Items @(
            "1 › Nvidia App",
            "2 › AMD Drivers",
            "3 › Intel Driver & Support Assistant (auto-install)",
            "---",
            "4 › HP",
            "5 › Lenovo",
            "6 › Asus",
            "7 › Acer",
            "8 › MSI",
            "9 › Huawei",
            "10 › Xiaomi",
            "11 › DELL/Alienware",
            "12 › Gigabyte",
            "---",
            "Enter › Back to Menu"
        )

        $choice =  Read-Host " "

        if ($choice -eq "") {
            return
        } elseif ($choice -eq "3") {
            Install-IntelDSA
        } elseif ($choice -eq "5") {
            Show-LenovoMenu
        } elseif ($urls.ContainsKey($choice)) {
            Start-Process $urls[$choice]
        } else {
            Write-Log -Message "Invalid choice. Please try again." -Level ERROR
            Start-Sleep -Seconds 1
        }
    }
}

function Install-IntelDSA {
    $installed = Install-WingetPackage "Intel.IntelDriverAndSupportAssistant" "Intel Driver & Support Assistant"
    if ($installed) {
        Start-Process "https://www.intel.com/content/www/us/en/support/intel-driver-support-assistant.html"
    } else {
        Start-Process "https://www.intel.com/content/www/us/en/support/detect.html"
    }
    Start-Sleep -Seconds 2
}

function Show-LenovoMenu {
    Invoke-MenuLoop -Title "Lenovo Driver Options" -Items @(
        "1 › Install Lenovo Vantage",
        "2 › Open Lenovo Driver Page",
        "---",
        "3 › Back to Manufacturer Selection"
    ) -Actions @{
        "1" = {
            $installed = Install-WingetPackage "9WZDNCRFJ4MV" "Lenovo Vantage"
            if (-not $installed) {
                Start-Process "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9WZDNCRFJ4MV&storecid=storeweb-pdp-open-cta"
            }
            Start-Sleep -Seconds 2
        }
        "2" = { Start-Process "https://support.lenovo.com" }
    } -ExitKey "3"
}

Show-DeviceMenu

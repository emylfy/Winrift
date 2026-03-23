. "$PSScriptRoot\..\..\scripts\Common.ps1"

Initialize-Logging -ModuleName "drivers"

# Winget exit code for "package already installed"
$WINGET_ALREADY_INSTALLED = -1978335189

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
            "[1]  Nvidia App",
            "[2]  AMD Drivers",
            "[3]  Intel Driver & Support Assistant (auto-install)",
            "---",
            "[4]  HP",
            "[5]  Lenovo",
            "[6]  Asus",
            "[7]  Acer",
            "[8]  MSI",
            "[9]  Huawei",
            "[10] Xiaomi",
            "[11] DELL/Alienware",
            "[12] Gigabyte",
            "---",
            "[Enter] Back to Menu"
        )

        $choice = Read-Host ">"

        if ($choice -eq "") {
            Invoke-ReturnToMenu; return
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
    if (-not (Assert-WingetAvailable)) { return }
    Write-Log -Message "Installing Intel Driver & Support Assistant..." -Level INFO
    try {
        & winget install Intel.IntelDriverAndSupportAssistant --accept-package-agreements --accept-source-agreements

        if ($LASTEXITCODE -eq 0) {
            Write-Log -Message "Intel DSA installed. Launching..." -Level SUCCESS
            Start-Process "https://www.intel.com/content/www/us/en/support/intel-driver-support-assistant.html"
        } elseif ($LASTEXITCODE -eq $WINGET_ALREADY_INSTALLED) {
            Write-Log -Message "Intel DSA is already installed. Launching..." -Level INFO
            Start-Process "https://www.intel.com/content/www/us/en/support/intel-driver-support-assistant.html"
        } else {
            Write-Log -Message "Failed to install Intel DSA. Opening download page..." -Level ERROR
            Start-Process "https://www.intel.com/content/www/us/en/support/detect.html"
        }
    } catch {
        Write-Log -Message "Error installing Intel DSA: $($_.Exception.Message)" -Level ERROR
        Start-Process "https://www.intel.com/content/www/us/en/support/detect.html"
    }
    Start-Sleep -Seconds 2
}

function Show-LenovoMenu {
    Invoke-MenuLoop -Title "Lenovo Driver Options" -Items @(
        "[1] Install Lenovo Vantage",
        "[2] Open Lenovo Driver Page",
        "---",
        "[3] Back to Manufacturer Selection"
    ) -Actions @{
        "1" = {
            if (-not (Assert-WingetAvailable)) { return }
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
        }
        "2" = { Start-Process "https://support.lenovo.com" }
    } -ExitKey "3"
}

Show-DeviceMenu

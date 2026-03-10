. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-DeviceMenu {
    $Host.UI.RawUI.WindowTitle = "Simplify11 - Drivers"
    Clear-Host

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

    Write-Host "$Purple +------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Nvidia App         $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] AMD Drivers        $Purple'$Reset"
    Write-Host "$Purple +------------------------+$Reset"
    Write-Host "$Purple '$Reset [3] HP                 $Purple'$Reset"
    Write-Host "$Purple '$Reset [4] Lenovo             $Purple'$Reset"
    Write-Host "$Purple '$Reset [5] Asus               $Purple'$Reset"
    Write-Host "$Purple '$Reset [6] Acer               $Purple'$Reset"
    Write-Host "$Purple '$Reset [7] MSI                $Purple'$Reset"
    Write-Host "$Purple '$Reset [8] Huawei             $Purple'$Reset"
    Write-Host "$Purple '$Reset [9] Xiaomi             $Purple'$Reset"
    Write-Host "$Purple '$Reset [10] DELL/Alienware    $Purple'$Reset"
    Write-Host "$Purple '$Reset [11] Gigabyte          $Purple'$Reset"
    Write-Host "$Purple '$Reset [Enter] Back to Menu   $Purple'$Reset"
    Write-Host "$Purple +------------------------+$Reset"

    $choice = Read-Host "Select your device manufacturer to install drivers"

    if ($choice -eq "4") {
        Show-LenovoMenu
    }
    elseif ($choice -eq "") {
        return
    }
    elseif ($urls.ContainsKey($choice)) {
        Start-Process $urls[$choice]
        Show-DeviceMenu
    }
    else {
        Write-Host "$Red Invalid choice. Returning to main menu. $Reset"
        Start-Sleep -Seconds 2
        Show-DeviceMenu
    }
}

function Show-LenovoMenu {
    Clear-Host
    Write-Host ""
    Write-Host "$Purple +--------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Install Lenovo Vantage                 $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] Open Lenovo Driver Page                $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [3] Back to Manufacturer Selection         $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------+$Reset"

    $choice = Read-Host ">"

    switch ($choice) {
        "3" { Show-DeviceMenu }
        "2" {
            Start-Process "https://support.lenovo.com"
            Show-LenovoMenu
        }
        "1" {
            Write-Host "$Reset Installing Lenovo Vantage... $Reset"
            $result = winget install "9WZDNCRFJ4MV" --accept-package-agreements --accept-source-agreements

            if ($LASTEXITCODE -eq 0) {
                Write-Host "$Green Successfully installed Lenovo Vantage. $Reset"
            }
            else {
                Write-Host "$Red Failed to install Lenovo Vantage. Please install manually from the Microsoft Store. $Reset"
                Start-Process "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9WZDNCRFJ4MV&storecid=storeweb-pdp-open-cta"
            }

            Start-Sleep -Seconds 2
            Show-LenovoMenu
        }
        default {
            Write-Host "$Red Invalid choice. $Reset"
            Start-Sleep -Seconds 1
            Show-LenovoMenu
        }
    }
}

Show-DeviceMenu

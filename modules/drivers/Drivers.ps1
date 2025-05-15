. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-DeviceMenu {
    $Host.UI.RawUI.WindowTitle = "Simplify11 - Drivers"
    Clear-Host

    $urls = @(
        "https://www.nvidia.com/en-us/software/nvidia-app/",
        "https://www.amd.com/en/support/download/drivers.html",
        "https://support.hp.com/us-en/drivers",
        "https://support.lenovo.com",
        "https://www.asus.com/support/download-center/",
        "https://www.acer.com/ac/en/US/content/drivers",
        "https://www.msi.com/support/download",
        "https://www.huawei.com/en/support",
        "https://www.xiaomi.com/global/support",
        "https://www.dell.com/support/home/products/computers?app=drivers",
        "https://www.gigabyte.com/Support/Consumer/Download"
    )

    Write-Host "$Purple +------------------------+$Reset"
    Write-Host "$Purple '$Grey [0] Nvidia App         $Purple'$Reset"
    Write-Host "$Purple '$Grey [1] AMD Drivers        $Purple'$Reset"
    Write-Host "$Purple +------------------------+$Reset"
    Write-Host "$Purple '$Grey [2] HP                 $Purple'$Reset"
    Write-Host "$Purple '$Grey [3] Lenovo             $Purple'$Reset"
    Write-Host "$Purple '$Grey [4] Asus               $Purple'$Reset"
    Write-Host "$Purple '$Grey [5] Acer               $Purple'$Reset"
    Write-Host "$Purple '$Grey [6] MSI                $Purple'$Reset"
    Write-Host "$Purple '$Grey [7] Huawei             $Purple'$Reset"
    Write-Host "$Purple '$Grey [8] Xiaomi             $Purple'$Reset"
    Write-Host "$Purple '$Grey [9] DELL/Alienware     $Purple'$Reset"
    Write-Host "$Purple '$Grey [10] Gigabyte          $Purple'$Reset"
    Write-Host "$Purple +------------------------+$Reset"

    $choice = Read-Host "Select your device manufacturer to install drivers"
    
    if ($choice -eq "3") {
        Show-LenovoMenu
    }
    elseif ($choice -in 0..10) {
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
    Write-Host "$Purple '$Grey [1] Install Lenovo Vantage                 $Purple'$Reset"
    Write-Host "$Purple '$Grey [2] Open Lenovo Driver Page                $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------+$Reset"
    Write-Host "$Purple '$Grey [3] Back to Manufacturer Selection         $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------+$Reset"

    $choice = Read-Host ">"
    
    switch ($choice) {
        "3" { Show-DeviceMenu }
        "2" { 
            Start-Process "https://support.lenovo.com"
            Show-LenovoMenu 
        }
        "1" {
            Write-Host "$Grey Installing Lenovo Vantage... $Reset"
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
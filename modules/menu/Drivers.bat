@echo off
setlocal EnableDelayedExpansion

set Purple=[38;5;141m
set Grey=[38;5;250m
set Reset=[0m
set Red=[38;5;203m
set Green=[38;5;120m

:deviceMenu
cls

set "url[0]=https://www.nvidia.com/en-us/software/nvidia-app/"
set "url[1]=https://www.amd.com/en/support/download/drivers.html"
set "url[2]=https://support.hp.com/us-en/drivers"
set "url[3]=https://support.lenovo.com"
set "url[4]=https://www.asus.com/support/download-center/"
set "url[5]=https://www.acer.com/ac/en/US/content/drivers"
set "url[6]=https://www.msi.com/support/download"
set "url[7]=https://www.huawei.com/en/support"
set "url[8]=https://www.xiaomi.com/global/support"
set "url[9]=https://www.alienware.com/support"
set "url[10]=https://www.gigabyte.com/support/consumer"

echo %Purple% +------------------------+%Reset%
echo %Purple% '%Grey% [0] Nvidia App         %Purple%'%Reset%
echo %Purple% '%Grey% [1] AMD Drivers        %Purple%'%Reset%
echo %Purple% +------------------------+%Reset%
echo %Purple% '%Grey% [2] HP                 %Purple%'%Reset%
echo %Purple% '%Grey% [3] Lenovo             %Purple%'%Reset%
echo %Purple% '%Grey% [4] Asus               %Purple%'%Reset%
echo %Purple% '%Grey% [5] Acer               %Purple%'%Reset%
echo %Purple% '%Grey% [6] MSI                %Purple%'%Reset%
echo %Purple% '%Grey% [7] Huawei             %Purple%'%Reset%
echo %Purple% '%Grey% [8] Xiaomi             %Purple%'%Reset%
echo %Purple% '%Grey% [9] Alienware          %Purple%'%Reset%
echo %Purple% '%Grey% [10] Gigabyte          %Purple%'%Reset%
echo %Purple% +------------------------+%Reset%

choice /C 0123456789 /N /M "Select your device manufacturer to install drivers: "
set /a "manufacturer_choice=%errorlevel%-1"

if !manufacturer_choice! equ 3 (
    goto lenovoMenu
) else if !manufacturer_choice! geq 0 if !manufacturer_choice! leq 10 (
    start "" "!url[%manufacturer_choice%]!"
    goto main
) else (
    echo %Red%Invalid choice. Returning to main menu.%Reset%
    timeout /t 2 >nul
    goto main
)

:lenovoMenu
cls
echo.
echo %Purple% +--------------------------------------------+%Reset%
echo %Purple% '%Grey% [1] Install Lenovo Vantage                 %Purple%'%Reset%
echo %Purple% '%Grey% [2] Open Lenovo Driver Page                %Purple%'%Reset%
echo %Purple% +--------------------------------------------+%Reset%
echo %Purple% '%Grey% [3] Back to Manufacturer Selection         %Purple%'%Reset%
echo %Purple% +--------------------------------------------+%Reset%

choice /C 123 /N /M ">"
set /a "lenovo_choice=%errorlevel%"

if !lenovo_choice! equ 3 goto deviceMenu
if !lenovo_choice! equ 2 (
    start "" "https://support.lenovo.com"
    goto lenovoMenu
)
if !lenovo_choice! equ 1 (
    echo %Grey%Installing Lenovo Vantage...%Reset%
    winget install "9WZDNCRFJ4MV" --accept-package-agreements --accept-source-agreements
    if !errorlevel! equ 0 (
        echo %Green%Successfully installed Lenovo Vantage.%Reset%
    ) else (
        echo %Red%Failed to install Lenovo Vantage. Please install manually from the Microsoft Store.%Reset%
        start "" "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9WZDNCRFJ4MV&storecid=storeweb-pdp-open-cta"
    )
    timeout /t 2
    goto lenovoMenu
)
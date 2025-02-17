: Add Nvidia App & AMD

@echo off
setlocal EnableDelayedExpansion

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

:deviceMenu
cls

set "url[0]=https://support.hp.com/us-en/drivers"
set "url[1]=https://support.lenovo.com"
set "url[2]=https://www.asus.com/support/download-center/"
set "url[3]=https://www.acer.com/ac/en/US/content/drivers"
set "url[4]=https://www.msi.com/support/download"
set "url[5]=https://www.huawei.com/en/support"
set "url[6]=https://www.xiaomi.com/global/support"
set "url[7]=https://www.alienware.com/support"
set "url[8]=https://www.gigabyte.com/support/consumer"

echo %cMauve% +------------------------+%cReset%
echo %cMauve% '%cGrey% [0] HP                 %cMauve%'%cReset%
echo %cMauve% '%cGrey% [1] Lenovo             %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Asus               %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Acer               %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] MSI                %cMauve%'%cReset%
echo %cMauve% '%cGrey% [5] Huawei             %cMauve%'%cReset%
echo %cMauve% '%cGrey% [6] Xiaomi             %cMauve%'%cReset%
echo %cMauve% '%cGrey% [7] Alienware          %cMauve%'%cReset%
echo %cMauve% '%cGrey% [8] Gigabyte           %cMauve%'%cReset%
echo %cMauve% +------------------------+%cReset%
echo %cMauve% '%cGrey% [9] Back to menu       %cMauve%'%cReset%
echo %cMauve% +------------------------+%cReset%

choice /C 0123456789 /N /M "Select your device manufacturer to install drivers: "
set /a "manufacturer_choice=%errorlevel%-1"

if !manufacturer_choice!==1 (
    goto lenovoMenu
) else if !manufacturer_choice! geq 0 if !manufacturer_choice! leq 8 (
    start "" "!url[%manufacturer_choice%]!"
    goto main
) else if !manufacturer_choice!==9 (
    goto main
) else (
    echo %cRed%Invalid choice. Returning to main menu.%cReset%
    timeout /t 2 >nul
    goto main
)

:lenovoMenu
cls
echo.
echo %cMauve% +--------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Install Lenovo Vantage                 %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Open Lenovo Driver Page                %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [3] Back to Manufacturer Selection         %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------+%cReset%

choice /C 123 /N /M ">"
set /a "lenovo_choice=%errorlevel%"
if !lenovo_choice! equ 3 goto deviceMenu
if !lenovo_choice! equ 2 (
    start "" "https://support.lenovo.com"
    goto lenovoMenu
)
if errorlevel 1 (
    echo %cGrey%Installing Lenovo Vantage...%cReset%
    winget install "9WZDNCRFJ4MV" --accept-package-agreements --accept-source-agreements
    if !errorlevel! equ 0 (
        echo %cGreen%Successfully installed Lenovo Vantage.%cReset%
    ) else (
        echo %cRed%Failed to install Lenovo Vantage. Please install manually from the Microsoft Store.%cReset%
         start "" "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9WZDNCRFJ4MV&storecid=storeweb-pdp-open-cta"
    )
    timeout /t 2
    goto lenovoMenu
) 
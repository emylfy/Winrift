@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (powershell start -verb runas '%~0' & exit)

:: Define colors
set cRosewater=[38;5;224m
set cFlamingo=[38;5;210m
set cMauve=[38;5;141m
set cRed=[38;5;203m
set cGreen=[38;5;120m
set cTeal=[38;5;116m
set cSky=[38;5;111m
set cSapphire=[38;5;69m
set cBlue=[38;5;75m
set cGrey=[38;5;250m
set cReset=[0m

:deviceMenu
cls
:: Define URLs for modern device manufacturers
set "url[0]=https://support.hp.com/us-en/drivers"
set "url[1]=https://support.lenovo.com"
set "url[2]=https://www.asus.com/support/download-center/"
set "url[3]=https://www.acer.com/ac/en/US/content/drivers"
set "url[4]=https://www.msi.com/support/download"
set "url[5]=https://www.huawei.com/en/support"
set "url[6]=https://www.xiaomi.com/global/support"
set "url[7]=https://www.alienware.com/support"
set "url[8]=https://www.gigabyte.com/support/consumer"

echo %cMauve% +-----------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Select your device manufacturer to install drivers: %cMauve%'%cReset%
echo %cMauve% +-----------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [0] HP                                              %cMauve%'%cReset%
echo %cMauve% '%cGrey% [1] Lenovo                                          %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Asus                                            %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Acer                                            %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] MSI                                             %cMauve%'%cReset%
echo %cMauve% '%cGrey% [5] Huawei                                          %cMauve%'%cReset%
echo %cMauve% '%cGrey% [6] Xiaomi                                          %cMauve%'%cReset%
echo %cMauve% '%cGrey% [7] Alienware                                       %cMauve%'%cReset%
echo %cMauve% '%cGrey% [8] Gigabyte                                        %cMauve%'%cReset%
echo %cMauve% +-----------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [9] Back to menu                                    %cMauve%'%cReset%
echo %cMauve% +-----------------------------------------------------+%cReset%

choice /C 0123456789 /N /M "Select a number: "
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
echo %cMauve% '%cGrey% [2] Install Dolby Access                   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Open Lenovo Driver Page                %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [4] Back to Manufacturer Selection         %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------+%cReset%

choice /C 1234 /N /M ">"
set /a "lenovo_choice=%errorlevel%"
if !lenovo_choice! equ 4 goto deviceMenu
if !lenovo_choice! equ 3 (
    start "" "https://support.lenovo.com"
    goto lenovoMenu
)
if !lenovo_choice! equ 2 (
    echo %cGrey%Installing Dolby Access...%cReset%
    winget install "9NBLGGH4XDB3" --accept-package-agreements --accept-source-agreements
    if !errorlevel! equ 0 (
        echo %cGreen%Successfully installed Dolby Access.%cReset%
    ) else (
        echo %cRed%Failed to install Dolby Access. Please install manually from the Microsoft Store.%cReset%
         start "" "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9N0866FS04W8&storecid=storeweb-pdp-open-cta"
    )
    timeout /t 2
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
@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (powershell start -verb runas '%~0' & exit)

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

:freeUpSpace

echo.
echo %cGrey%Would you like to disable Reserved Storage?%cReset%
choice /C 12 /N /M "[1] Yes or [2] No : "
set /a "storage_choice=%errorlevel%"
if !storage_choice!==1 (
    echo %cGrey%Disabling Reserved Storage...%cReset%
    dism /Online /Set-ReservedStorageState /State:Disabled
)

echo.
echo %cGrey%Would you like to clean up WinSxS?%cReset%
choice /C 12 /N /M "[1] Yes or [2] No : "
set /a "winsxs_choice=%errorlevel%"
if !winsxs_choice!==1 (
    echo %cGrey%Cleaning up WinSxS...%cReset%
    dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase /RestoreHealth
)

echo.
echo %cGrey%Would you like to remove Virtual Memory (pagefile.sys)?%cReset%
choice /C 12 /N /M "[1] Yes or [2] No : "
set /a "vm_choice=%errorlevel%"
if !vm_choice!==1 (
    echo %cGrey%Removing Virtual Memory...%cReset%
    powershell -Command "Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value ''"
)

echo.
echo %cGrey%Would you like to install and launch PC Manager? (Official Microsoft Utility from Store)%cReset%
choice /C 12 /N /M "[1] Yes or [2] No : "
set /a "pcmanager_choice=%errorlevel%"
if !pcmanager_choice!==1 (
    echo %cGrey%Installing PC Manager...%cReset%
    winget install Microsoft.PCManager --accept-package-agreements --accept-source-agreements
    if !errorlevel! equ 0 (
        echo Successfully installed PC Manager.
        start "" "shell:AppsFolder\Microsoft.MicrosoftPCManager_8wekyb3d8bbwe!App"
    ) else if !errorlevel! equ -1978335189 (
        echo %cGrey%PC Manager is already installed. Launching...%cReset%
        start "" "shell:AppsFolder\Microsoft.MicrosoftPCManager_8wekyb3d8bbwe!App"
    ) else (
        echo Failed to install PC Manager. Please try manually.
        start "" "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9pm860492szd&storecid=storeweb-pdp-open-cta"
        pause
    )
)

goto main
@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (powershell start -verb runas '%~0' & exit)

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

:freeUpSpace

:: Disable Reserved Storage
echo.
echo %cGrey%Would you like to disable Reserved Storage?%cReset%
choice /C 12 /N /M "[1] Yes or [2] No : "
set /a "storage_choice=%errorlevel%"
if !storage_choice!==1 (
    echo %cGrey%Disabling Reserved Storage...%cReset%
    dism /Online /Set-ReservedStorageState /State:Disabled
)

:: Cleanup WinSxS
echo.
echo %cGrey%Would you like to clean up WinSxS?%cReset%
choice /C 12 /N /M "[1] Yes or [2] No : "
set /a "winsxs_choice=%errorlevel%"
if !winsxs_choice!==1 (
    echo %cGrey%Cleaning up WinSxS...%cReset%
    dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase /RestoreHealth
)

:: Remove Virtual Memory
echo.
echo %cGrey%Would you like to remove Virtual Memory (pagefile.sys)?%cReset%
choice /C 12 /N /M "[1] Yes or [2] No : "
set /a "vm_choice=%errorlevel%"
if !vm_choice!==1 (
    echo %cGrey%Removing Virtual Memory...%cReset%
    powershell -Command "Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value ''"
)

:: Clear Windows Update Folder
echo.
echo %cGrey%Would you like to clear the Windows Update Folder?%cReset%
choice /C 12 /N /M "[1] Yes or [2] No : "
set /a "wu_choice=%errorlevel%"
if !wu_choice!==1 (
    echo %cGrey%Stopping Windows Update related services...%cReset%
    net stop wuauserv >nul 2>&1
    net stop cryptSvc >nul 2>&1
    net stop bits >nul 2>&1
    net stop msiserver >nul 2>&1
    
    echo %cGrey%Clearing Windows Update Folder...%cReset%
    rd /s /q "%systemdrive%\Windows\SoftwareDistribution"
    md "%systemdrive%\Windows\SoftwareDistribution"
    
    echo %cGrey%Restarting Windows Update related services...%cReset%
    net start wuauserv >nul 2>&1
    net start cryptSvc >nul 2>&1
    net start bits >nul 2>&1
    net start msiserver >nul 2>&1
    
    echo %cGreen%Windows Update folder has been cleared successfully.%cReset%
)

@REM :: Advanced disk cleaner
@REM echo.
@REM echo %cMauve% +--------------------------------------------------------+%cReset%
@REM echo %cMauve% '%cGrey% Advanced Disk Cleaner                                  %cMauve%'%cReset%
@REM echo %cMauve% +--------------------------------------------------------+%cReset%
@REM echo %cMauve% '%cGrey% This will clean:                                       %cMauve%'%cReset%
@REM echo %cMauve% '%cGrey% - Windows temporary files                              %cMauve%'%cReset%
@REM echo %cMauve% '%cGrey% - System error memory dump files                       %cMauve%'%cReset%
@REM echo %cMauve% '%cGrey% - Windows upgrade log files                            %cMauve%'%cReset%
@REM echo %cMauve% '%cGrey% - Windows Defender Antivirus files                     %cMauve%'%cReset%
@REM echo %cMauve% '%cGrey% - Delivery Optimization Files                          %cMauve%'%cReset%
@REM echo %cMauve% '%cGrey% - Device driver packages                               %cMauve%'%cReset%
@REM echo %cMauve% +--------------------------------------------------------+%cReset%
@REM choice /C 12 /N /M "[1] Run Cleaner or [2] Skip : "
@REM set /a "cleaner_choice=%errorlevel%"
@REM if !cleaner_choice!==1 (
@REM     echo %cGrey%Preparing disk cleanup utility...%cReset%
    
@REM     :: Create registry keys for auto-selection of all cleanup options
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders" "StateFlags65535" "REG_DWORD" "2" "Enabled Active Setup Temp Folders cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache" "StateFlags65535" "REG_DWORD" "2" "Enabled BranchCache cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\D3D Shader Cache" "StateFlags65535" "REG_DWORD" "2" "Enabled D3D Shader Cache cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Delivery Optimization Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Delivery Optimization Files cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Device Driver Packages" "StateFlags65535" "REG_DWORD" "2" "Enabled Device Driver Packages cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Downloaded Program Files cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Internet Cache Files cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Language Pack" "StateFlags65535" "REG_DWORD" "2" "Enabled Language Pack cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Offline Pages Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Offline Pages Files cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Old ChkDsk Files cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations" "StateFlags65535" "REG_DWORD" "2" "Enabled Previous Installations cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin" "StateFlags65535" "REG_DWORD" "2" "Enabled Recycle Bin cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\RetailDemo Offline Content" "StateFlags65535" "REG_DWORD" "2" "Enabled RetailDemo Offline Content cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup" "StateFlags65535" "REG_DWORD" "2" "Enabled Service Pack Cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Setup Log Files cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files" "StateFlags65535" "REG_DWORD" "2" "Enabled System error memory dump files cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files" "StateFlags65535" "REG_DWORD" "2" "Enabled System error minidump files cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Temporary Files cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache" "StateFlags65535" "REG_DWORD" "2" "Enabled Thumbnail Cache cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup" "StateFlags65535" "REG_DWORD" "2" "Enabled Update Cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Upgrade Discarded Files cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\User file versions" "StateFlags65535" "REG_DWORD" "2" "Enabled User file versions cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender" "StateFlags65535" "REG_DWORD" "2" "Enabled Windows Defender cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Windows Error Reporting Files cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows ESD installation files" "StateFlags65535" "REG_DWORD" "2" "Enabled Windows ESD installation files cleanup"
@REM     call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files" "StateFlags65535" "REG_DWORD" "2" "Enabled Windows Upgrade Log Files cleanup"
    
@REM     :: First try running directly
@REM     cleanmgr /sagerun:65535
    
@REM     :: If direct execution fails, try with full path
@REM     if !errorlevel! neq 0 (
@REM         echo Retrying with full path...
@REM         %SystemRoot%\System32\cleanmgr.exe /sagerun:65535
@REM     )
    
@REM     :: Check final execution status
@REM     if !errorlevel! equ 0 (
@REM         echo Disk cleanup completed successfully.
@REM     ) else (
@REM         echo Error: Disk cleanup failed with code !errorlevel!
@REM         echo Attempting to launch Disk Cleanup manually...
@REM         start cleanmgr.exe
@REM     )
@REM     pause
@REM )

:: Install and Launch PC Manager
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

:reg
setlocal
set "key=%~1"
set "valueName=%~2"
set "valueType=%~3"
set "valueData=%~4"
set "comment=%~5"

:: Convert registry hive shortcuts to full paths
set "key=%key:HKLM\=HKEY_LOCAL_MACHINE\%"
set "key=%key:HKCU\=HKEY_CURRENT_USER\%"

:: Create the registry key path if it doesn't exist
reg add "%key%" /f >nul 2>&1

:: Handle different value types
if /i "%valueType%"=="REG_DWORD" (
    reg add "%key%" /v "%valueName%" /t REG_DWORD /d "%valueData%" /f >nul 2>&1
) else if /i "%valueType%"=="REG_SZ" (
    reg add "%key%" /v "%valueName%" /t REG_SZ /d "%valueData%" /f >nul 2>&1
) else if /i "%valueType%"=="REG_BINARY" (
    reg add "%key%" /v "%valueName%" /t REG_BINARY /d "%valueData%" /f >nul 2>&1
) else (
    echo %cRed%[FAILED]%cReset% Unsupported registry value type: %valueType%
    exit /b 1
)

if %errorlevel% equ 0 (
    echo %cGreen%[SUCCESS]%cReset% %comment%
) else (
    echo %cRed%[FAILED]%cReset% Failed to set %valueName%
    exit /b 1
)

exit /b 0
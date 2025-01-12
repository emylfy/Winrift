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

:coolStuff
cls
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Customization Options                                  %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Open Night Light Settings                        %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Set Short Date Format (d MMM yy)                   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Rename System Drive to Win 11                      %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] Visit Cool Stuff Page (Themes and More)            %cMauve%'%cReset%
echo %cMauve% '%cGrey% [5] Back to Main Menu                                  %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%

choice /C 12345 /N /M ">"
set /a "customization_choice=%errorlevel%"
if !customization_choice! equ 5 goto main
if !customization_choice! equ 4 (
    start "" "https://github.com/emylfy/simplify11?tab=readme-ov-file#-cool-stuff"
    goto coolStuff
)
if !customization_choice! equ 3 (
    label C:Win 11
    start explorer.exe
    pause
)
if errorlevel 2 (
    call :reg "HKEY_CURRENT_USER\Control Panel\International" "sShortDate" "REG_SZ" "d MMM yy" "Set short date format to d MMM yy"
    echo %cGreen%Date format updated successfully. Changes will take effect after restart.%cReset%
    pause
    goto coolStuff
)
if errorlevel 1 (
    start ms-settings:nightlight
    goto coolStuff
)
goto coolStuff

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
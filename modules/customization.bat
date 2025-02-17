: Install cursor
: Windows terminal preset
: Disable automatic addition of folders to Quick Access

@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (
    echo Not running as admin. Elevating...
    where wt.exe >nul 2>&1
    if %errorlevel% equ 0 (
        powershell -Command "Start-Process -FilePath 'wt.exe' -ArgumentList 'cmd /k \"%~0\"' -Verb runAs"
    ) else (
        powershell -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k \"%~0\"' -Verb runAs"
    )
    exit /b
)

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

:coolStuff
cls
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Customization Options                                  %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Set Short Date and Hours Format - Feb 17, 17:57    %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Back to Menu                                       %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%

choice /C 12345 /N /M ">"
set /a "customization_choice=%errorlevel%"
if !customization_choice! equ 2 exit
if errorlevel 1 (
    @REM call :reg "HKEY_CURRENT_USER\Control Panel\International" "sShortDate" "REG_SZ" "d MMM yy" "Set short date format to d MMM yy"
		reg add "HKCU\Control Panel\International" /v sShortDate /t REG_SZ /d "dd MMM yyyy" /f
		reg add "HKCU\Control Panel\International" /v sShortTime /t REG_SZ /d "HH:mm" /f
		reg add "HKCU\Control Panel\International" /v sTimeFormat /t REG_SZ /d "HH:mm:ss" /f
    echo %cGreen%Date format updated successfully. Changes will take effect after restart.%cReset%
    pause
    goto coolStuff
)
goto coolStuff

:reg
call "%~dp0\..\reg_helper.bat" %*
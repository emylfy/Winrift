: Windows terminal preset

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
echo %cMauve% '%cGrey% [2] Disable automatic pin of folders to Quick Access   %cMauve%'%cReset%
echo %cMauve% +-Require-Internet-Connection----------------------------+%cReset%
echo %cMauve% '%cGrey% [3] Launch Windots - configs, cursor, wallpapers       %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [4] Back to Menu                                       %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%

choice /C 1234 /N /M ">"
set /a "customization_choice=%errorlevel%"
if !customization_choice! equ 4 exit
if !customization_choice! equ 3 goto launchWindots
if !customization_choice! equ 2 goto disableQuickAccess
if !customization_choice! equ 1 goto shortDateHours
goto coolStuff

:shortDateHours
cls
echo %cGreen%Setting short date and hours format...%cReset%
reg add "HKCU\Control Panel\International" /v sShortDate /t REG_SZ /d "dd MMM yyyy" /f
reg add "HKCU\Control Panel\International" /v sShortTime /t REG_SZ /d "HH:mm" /f
reg add "HKCU\Control Panel\International" /v sTimeFormat /t REG_SZ /d "HH:mm:ss" /f
echo %cGreen%Date and time format updated successfully. Changes will take effect after restart.%cReset%
pause
goto coolStuff

:disableQuickAccess
cls
echo %cGreen%Disabling automatic addition of folders to Quick Access...%cReset%
powershell -Command "Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowFrequent' -Type DWord -Value 0"
powershell -Command "Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowRecent' -Type DWord -Value 0"
powershell -Command "$quickAccess = (New-Object -ComObject shell.application).Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}').Items(); $quickAccess | ForEach-Object { $_.InvokeVerb('remove') }"
powershell -Command "Stop-Process -Name explorer -Force; Start-Process explorer"
echo %cGreen%Quick Access settings updated successfully. Explorer will restart to apply changes.%cReset%
pause
goto coolStuff

:launchWindots
cls
powershell -Command "iwr https://dub.sh/windots/"
goto coolStuff

:reg
call "%~dp0\..\reg_helper.bat" %*

@REM :configs_menu
@REM cls
@REM echo.
@REM echo %cMauve% +--------------------------------------------------------+%cReset%
@REM echo %cMauve% '%cGrey% [1] ZSH Configuration                      %cMauve%'%cReset%
@REM echo %cMauve% '%cGrey% [2] PowerShell Configuration               %cMauve%'%cReset%
@REM echo %cMauve% '%cGrey% [3] Oh My Posh Configuration               %cMauve%'%cReset%
@REM echo %cMauve% '%cGrey% [4] FastFetch Configuration                %cMauve%'%cReset%
@REM echo %cMauve% '%cGrey% [5] Return to Main Menu                           %cMauve%'%cReset%
@REM echo %cMauve% +--------------------------------------------------------+%cReset%
@REM choice /C 12345 /N /M "Select config to install: "
@REM set /a "configChoice=%errorlevel%"

@REM :customization_menu
@REM cls
@REM echo.
@REM echo %cMauve% +--------------------------------------------------------+%cReset%
@REM echo %cMauve% '%cGrey% [1] Install macOS Cursor Theme                   %cMauve%'%cReset%
@REM echo %cMauve% '%cGrey% [2] Download Rectify11                           %cMauve%'%cReset%
@REM echo %cMauve% '%cGrey% [3] Return to Main Menu                          %cMauve%'%cReset%
@REM echo %cMauve% +--------------------------------------------------------+%cReset%
@REM choice /C 123 /N /M "Select customization: "
@REM set /a "customChoice=%errorlevel%"

: Install cursor
@REM cmd /c explorer /select,"%USERPROFILE%\Documents\GitHub\windots\config\etc\cursor\install.inf"
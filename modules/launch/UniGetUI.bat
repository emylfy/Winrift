@echo off
setlocal EnableDelayedExpansion

set Purple=[38;5;141m
set Grey=[38;5;250m
set Reset=[0m
set Red=[38;5;203m
set Green=[38;5;120m

:UniGetUI
cls
echo %Purple% +------------------------------------------+%Reset%
echo %Purple% '%Grey% UniGetUI (formerly WingetUI)             %Purple%'%Reset%
echo %Purple% +------------------------------------------+%Reset%
echo %Purple% '%Grey% [1] Install and Launch                   %Purple%'%Reset%
echo %Purple% '%Grey% [2] Open List of Apps by Category        %Purple%'%Reset%
echo %Purple% '%Grey% [3] Try Fixing Winget if something wrong %Purple%'%Reset%
echo %Purple% +------------------------------------------+%Reset%
choice /C 12 /N /M "Select an option: "
if %errorlevel% equ 1 goto UniGetUI
if %errorlevel% equ 2 goto AppCategoryMenu

:UniGetUI
cls
echo %Purple% +---                    ---+%Reset%
echo %Purple%  '%Grey%    Install UniGetUI    %Purple%'%Reset%
echo %Purple% +---                    ---+%Reset%

winget source update
powershell "if ((winget list --id MartiCliment.UniGetUI --accept-source-agreements) -match 'MartiCliment.UniGetUI') { exit 0 } else { exit 1 }"
if !errorlevel! equ 0 (
    echo %Grey%UniGetUI is already installed. Launching...%Reset%
    start "" "unigetui:"
) else (
    echo %Grey%Installing UniGetUI...%Reset%
    winget install MartiCliment.UniGetUI --accept-package-agreements --accept-source-agreements
    if !errorlevel! equ 0 (
        echo %Green%Successfully installed UniGetUI.%Reset%
        start "" "unigetui:"
    ) else (
        echo %Red%Failed to install UniGetUI. Opening website for manual download...%Reset%
        start "" "https://www.marticliment.com/unigetui/"
        goto checkWinget
    )
)

goto UniGetUI

:checkWinget
where winget >nul 2>nul
if !errorlevel! neq 0 (
    echo %Red%Winget is not installed. Please install Windows App Installer from Microsoft Store.%Reset%
    start "" "ms-windows-store://pdp/?ProductId=9nblggh4nns1"
    pause
    goto UniGetUI
)

:AppCategoryMenu
cls
echo %Purple% +--------------------------------+%Reset%
echo %Purple% '%Grey% App Categories                 %Purple%'%Reset%
echo %Purple% +--------------------------------+%Reset%
echo %Purple% '%Grey% [1] Development                %Purple%'%Reset%
echo %Purple% '%Grey% [2] Web Browsers               %Purple%'%Reset%
echo %Purple% '%Grey% [3] Utilities, Microsoft tools %Purple%'%Reset%
echo %Purple% '%Grey% [4] Productivity Suite         %Purple%'%Reset%
echo %Purple% '%Grey% [5] Gaming Essentials          %Purple%'%Reset%
echo %Purple% '%Grey% [6] Communications             %Purple%'%Reset%
echo %Purple% +--------------------------------+%Reset%
choice /C 123456 /N /M "Select a category: "
if %errorlevel% equ 1 set "bundleName=development"
if %errorlevel% equ 2 set "bundleName=browsers"
if %errorlevel% equ 3 set "bundleName=utilities"
if %errorlevel% equ 4 set "bundleName=productivity"
if %errorlevel% equ 5 set "bundleName=games"
if %errorlevel% equ 6 set "bundleName=communications"

"%LOCALAPPDATA%\Programs\UniGetUI\UniGetUI.exe" /launch "%~dp0..\ubundle\%bundleName%.ubundle"
IF ERRORLEVEL 1 (
    start "" "%~dp0..\ubundle\%bundleName%.ubundle"
    IF ERRORLEVEL 1 (
        echo Make sure that you installed UniGetUI.
        goto :UniGetUI
    )
)

IF ERRORLEVEL 1 (
    start "" "%~dp0..\ubundle\%bundleName%.ubundle"
    IF ERRORLEVEL 1 (
        echo Make sure that you installed UniGetUI.
        goto :UniGetUI
    )
)
goto AppCategoryMenu
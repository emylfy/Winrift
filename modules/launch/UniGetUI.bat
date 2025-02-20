@echo off
setlocal EnableDelayedExpansion

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

:UniGetUI
cls
echo %cMauve% +------------------------------------------+%cReset%
echo %cMauve% '%cGrey% UniGetUI (formerly WingetUI)             %cMauve%'%cReset%
echo %cMauve% +------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Install and Launch                   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Open List of Apps by Category        %cMauve%'%cReset%
echo %cMauve% +------------------------------------------+%cReset%
choice /C 12 /N /M "Select an option: "
if %errorlevel% equ 1 goto UniGetUI
if %errorlevel% equ 2 goto AppCategoryMenu

:UniGetUI
cls
echo %cMauve% +---                    ---+%cReset%
echo %cMauve%  '%cGrey%    Install UniGetUI    %cMauve%'%cReset%
echo %cMauve% +---                    ---+%cReset%

powershell -Command "if ((winget list --id MartiCliment.UniGetUI --accept-source-agreements) -match 'MartiCliment.UniGetUI') { exit 0 } else { exit 1 }"
if !errorlevel! equ 0 (
    echo %cGrey%UniGetUI is already installed. Launching...%cReset%
    start "" "unigetui:"
) else (
    echo %cGrey%Installing UniGetUI...%cReset%
    winget install MartiCliment.UniGetUI --accept-package-agreements --accept-source-agreements
    if !errorlevel! equ 0 (
        echo %cGreen%Successfully installed UniGetUI.%cReset%
        start "" "unigetui:"
    ) else (
        echo %cRed%Failed to install UniGetUI. Opening website for manual download...%cReset%
        start "" "https://www.marticliment.com/unigetui/"
        goto checkWinget
    )
)

goto UniGetUI

:checkWinget
where winget >nul 2>nul
if !errorlevel! neq 0 (
    echo %cRed%Winget is not installed. Please install Windows App Installer from Microsoft Store.%cReset%
    start "" "ms-windows-store://pdp/?ProductId=9nblggh4nns1"
    pause
    goto UniGetUI
)

:AppCategoryMenu
cls
echo %cMauve% +--------------------------------+%cReset%
echo %cMauve% '%cGrey% App Categories                 %cMauve%'%cReset%
echo %cMauve% +--------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Development                %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Web Browsers               %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Utilities, Microsoft tools %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] Productivity Suite         %cMauve%'%cReset%
echo %cMauve% '%cGrey% [5] Gaming Essentials          %cMauve%'%cReset%
echo %cMauve% '%cGrey% [6] Communications             %cMauve%'%cReset%
echo %cMauve% +--------------------------------+%cReset%
choice /C 123456 /N /M "Select a category: "
if %errorlevel% equ 1 set "bundleName=development"
if %errorlevel% equ 2 set "bundleName=browsers"
if %errorlevel% equ 3 set "bundleName=utilities"
if %errorlevel% equ 4 set "bundleName=productivity"
if %errorlevel% equ 5 set "bundleName=games"
if %errorlevel% equ 6 set "bundleName=communications"

"%LOCALAPPDATA%\Programs\UniGetUI\UniGetUI.exe" "%~dp0ubundle\%bundleName%.ubundle"
goto AppCategoryMenu
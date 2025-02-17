@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (powershell start -verb runas '%~0' & exit)

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

:wingetInstallMenu
cls
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Install UniGetUI                                        %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%

:UniGetUI
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

goto main

:checkWinget
where winget >nul 2>nul
if !errorlevel! neq 0 (
    echo %cRed%Winget is not installed. Please install Windows App Installer from Microsoft Store.%cReset%
    start "" "ms-windows-store://pdp/?ProductId=9nblggh4nns1"
    pause
    goto wingetInstall
)
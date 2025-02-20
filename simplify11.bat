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

:main
title Simplify11 v25.02
cls
echo.
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cMauve%   Tired of System Setup After Reinstall? Simplify It!   %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [0] Configure Your Windows Installation Answer File    %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] WinUtil - Install Programs, Tweaks, Fixes, Updates %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] WinScript - Build your script from scratch         %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Privacy.sexy - Enforce privacy and security        %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] UniGetUI - Discover, Install, Update Packages      %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [5] System Tweaks - SSD, GPU, CPU, Storage and etc     %cMauve%'%cReset%
echo %cMauve% '%cGrey% [6] Install Drivers - Nvidia, AMD, Device Manufacturer %cMauve%'%cReset%
echo %cMauve% '%cGrey% [7] Customization stuff, windots                       %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
choice /C 01234567 /N /M ">"
set /a "menuChoice=%errorlevel%-1"
goto s!menuChoice!

:s0
start "" https://github.com/emylfy/simplify11/blob/main/src/docs/autounattend_guide.md
goto main

:s1
start cmd /c "%~dp0modules\launch\WinUtil.bat"
goto main

:s2
start cmd /c "%~dp0modules\launch\WinScript.bat"
goto main

:s3
start cmd /c "%~dp0modules\launch\PrivacySexy.bat"
goto main

:s4
start cmd /c "%~dp0modules\launch\UniGetUI.bat"
goto main

:s5
start cmd /c "%~dp0modules\menu\Tweaks.bat"
goto main

:s6
start cmd /c "%~dp0modules\menu\Drivers.bat"
goto main

:s7
start cmd /c "%~dp0modules\menu\Customization.bat"
goto main

exit /b 0
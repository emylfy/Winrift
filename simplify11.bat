@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (
    echo Not running as admin. Elevating...
    where wt.exe >nul 2>&1
    if %errorlevel% equ 0 (
        powershell "Start-Process -FilePath 'wt.exe' -ArgumentList 'cmd /k \"%~0\"' -Verb runAs"
    ) else (
        powershell "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k \"%~0\"' -Verb runAs"
    )
    exit /b
)

set Purple=[38;5;141m
set Grey=[38;5;250m
set Reset=[0m
set Red=[38;5;203m
set Green=[38;5;120m

:main
title Simplify11 v25.02
cls
echo %Purple% +--------------------------------------------------------+%Reset%
echo %Purple% '%Purple%   Tired of System Setup After Reinstall? Simplify It!   %Purple%'%Reset%
echo %Purple% +--------------------------------------------------------+%Reset%
echo %Purple% '%Grey% [0] Configure Your Windows Installation Answer File    %Purple%'%Reset%
echo %Purple% +--------------------------------------------------------+%Reset%
echo %Purple% '%Grey% [1] WinUtil - Install Programs, Tweaks, Fixes, Updates %Purple%'%Reset%
echo %Purple% '%Grey% [2] WinScript - Build your script from scratch         %Purple%'%Reset%
echo %Purple% '%Grey% [3] Privacy.sexy - Enforce privacy and security        %Purple%'%Reset%
echo %Purple% '%Grey% [4] UniGetUI - Discover, Install, Update Packages      %Purple%'%Reset%
echo %Purple% +--------------------------------------------------------+%Reset%
echo %Purple% '%Grey% [5] System Tweaks - SSD, GPU, CPU, Storage and etc     %Purple%'%Reset%
echo %Purple% '%Grey% [6] Install Drivers - Nvidia, AMD, Device Manufacturer %Purple%'%Reset%
echo %Purple% '%Grey% [7] Customization stuff, Windots                       %Purple%'%Reset%
echo %Purple% +--------------------------------------------------------+%Reset%
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
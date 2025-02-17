@echo off
setlocal EnableDelayedExpansion
:: net session >nul 2>&1 || (powershell start -verb runas '%~0' & exit)

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

:main
title Simplify11 v25.01
cls
echo.
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cMauve%  Tired of System Setup After Reinstall? Simplify It!    %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [0] Configure Your Windows Installation Answer File    %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] WinUtil - Install Programs, Tweaks, Fixes, Updates %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Winscript - Build your script from scratch         %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Privacy.sexy - Enforce privacy and security        %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] UniGetUI - Discover, Install, Update Packages      %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [5] System Tweaks - SSD, GPU, CPU, Storage and etc     %cMauve%'%cReset%
echo %cMauve% '%cGrey% [6] Install Drivers - Nvidia, AMD, Device Manufacturer %cMauve%'%cReset%
echo %cMauve% '%cGrey% [7] Customization stuff, windots                       %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
choice /C 1234567 /N /M ">"
set /a "menuChoice=%errorlevel%"
goto s!menuChoice!

:s1
start cmd /c "%~dp0modules\launchWinUtil.bat"
goto main

:s2
start cmd /c "%~dp0modules\launchWinscript.bat"
goto main

:s3
start cmd /c "%~dp0modules\launchPrivacySexy.bat"
goto main

:s4
start cmd /c "%~dp0modules\wingetInstall.bat"
goto main

:s5
start cmd /c "%~dp0modules\applyTweaks.bat"
goto main

:s6
start cmd /c "%~dp0modules\deviceMenu.bat"
goto main

:s7
start cmd /c "%~dp0modules\customization.bat"
goto main

exit /b 0
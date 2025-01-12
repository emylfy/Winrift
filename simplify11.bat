@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (powershell start -verb runas '%~0' & exit)

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

title Creating Restore Point directly coming soon
echo This is Pre-release, and not fully tested
echo Please, create restore point before Applying Tweaks
pause

:main
title Simplify11 v25.01
cls
echo.
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cMauve%  Tired of System Setup After Reinstall? Simplify It!    %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Apply Performance Tweaks                           %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Free Up Space                                      %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] WinUtil - Install Programs, Tweaks and Fixes       %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] Privacy.Sexy - Tool to enforce privacy in clicks   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [5] Install programs without browser                   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [6] Check PC/Laptop Manufacturers (Soft and drivers)   %cMauve%'%cReset%
echo %cMauve% '%cGrey% [7] Customization stuff                                %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
choice /C 1234567 /N /M ">"
set /a "menuChoice=%errorlevel%"
goto s!menuChoice!

:s1
start cmd /c "%~dp0modules\applyTweaks.bat"
goto main

:s2
start cmd /c "%~dp0modules\freeUpSpace.bat"
goto main

:s3
start cmd /c "%~dp0modules\launchWinUtil.bat"
goto main

:s4
start cmd /c "%~dp0modules\launchPrivacySexy.bat"
goto main

:s5
start cmd /c "%~dp0modules\wingetInstall.bat"
goto main

:s6
start cmd /c "%~dp0modules\deviceMenu.bat"
goto main

:s7
start cmd /c "%~dp0modules\coolStuff.bat"
goto main

exit /b 0
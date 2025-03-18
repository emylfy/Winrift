@echo off
setlocal EnableDelayedExpansion

set Purple=[38;5;141m
set Grey=[38;5;250m
set Reset=[0m
set Red=[38;5;203m
set Green=[38;5;120m

:WinScript
cls
echo.
echo %Purple% +-----------------------------------+%Reset%
echo %Purple% '%Grey%  Winscript - Make Windows Yours   %Purple%'%Reset%
echo %Purple% +-----------------------------------+%Reset%
echo %Purple% '%Grey% [1] Open online version           %Purple%'%Reset%
echo %Purple% '%Grey% [2] Install and Launch via Winget %Purple%'%Reset%
echo %Purple% '%Grey% [3] Back to menu                  %Purple%'%Reset%
echo %Purple% +-----------------------------------+%Reset%
choice /C 123 /N /M "Select an option: "

if errorlevel 3 goto :eof
if errorlevel 2 goto install
if errorlevel 1 goto online

:online
start "" "https://winscript.cc/online/"
goto WinScript

:install
echo %Green%Installing WinScript... This may take a moment.%Reset%
winget install --id=flick9000.WinScript
start "" "%ProgramFiles%\WinScript\WinScript.exe"
echo %Green%Installation complete. Launching WinScript...%Reset%
exit /b
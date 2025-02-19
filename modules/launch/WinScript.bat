@echo off
setlocal EnableDelayedExpansion

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

:WinScript
cls
echo.
echo %cMauve% +-----------------------------------+%cReset%
echo %cMauve% '%cGrey%  Winscript - Make Windows Yours   %cMauve%'%cReset%
echo %cMauve% +-----------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Open online version           %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Install and Launch via Winget %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Back to menu                  %cMauve%'%cReset%
echo %cMauve% +-----------------------------------+%cReset%
choice /C 123 /N /M "Select an option: "

if errorlevel 3 goto :eof
if errorlevel 2 goto install
if errorlevel 1 goto online

:online
start "" "https://winscript.cc/online/"
goto WinScript

:install
echo %cGreen%Installing WinScript... This may take a moment.%cReset%
winget install --id=flick9000.WinScript
start "" "%ProgramFiles%\WinScript\WinScript.exe"
echo %cGreen%Installation complete. Launching WinScript...%cReset%
exit /b
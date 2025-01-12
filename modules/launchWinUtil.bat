@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (powershell start -verb runas '%~0' & exit)

:: Define colors
set cRosewater=[38;5;224m
set cFlamingo=[38;5;210m
set cMauve=[38;5;141m
set cRed=[38;5;203m
set cGreen=[38;5;120m
set cTeal=[38;5;116m
set cSky=[38;5;111m
set cSapphire=[38;5;69m
set cBlue=[38;5;75m
set cGrey=[38;5;250m
set cReset=[0m

:: Start of launchWinUtil content
cls
echo.
echo %cMauve% +-----------------------------------+%cReset%
echo %cMauve% '%cGrey% Launching Windows Utility Tool... %cMauve%'%cReset%
echo %cMauve% +-----------------------------------+%cReset%

:: Launch Windows Utility Tool
start cmd /c powershell -Command "irm 'https://christitus.com/win' | iex"

exit /b 0
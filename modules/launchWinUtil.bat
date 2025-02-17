@echo off
setlocal EnableDelayedExpansion

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

cls
echo.
echo %cMauve% +-----------------------------------+%cReset%
echo %cMauve% '%cGrey% Launching Windows Utility Tool... %cMauve%'%cReset%
echo %cMauve% +-----------------------------------+%cReset%

start cmd /c powershell -Command "irm 'https://christitus.com/win' | iex"

exit /b 0
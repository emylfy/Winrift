@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (powershell start -verb runas '%~0' & exit)

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

:menu
cls
echo.
echo %cMauve% +----------------------------------------+%cReset%
echo %cMauve% '%cGrey%           System Tweaks Menu           %cMauve%'%cReset%
echo %cMauve% +----------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Storage Device Tweaks              %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] GPU Performance Tweaks             %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Power-Intensive Tweaks             %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] Universal System Tweaks            %cMauve%'%cReset%
echo %cMauve% '%cGrey% [5] Exit                               %cMauve%'%cReset%
echo %cMauve% +----------------------------------------+%cReset%

choice /C 123456 /N /M "Select an option: "
if errorlevel 5 goto :eof
if errorlevel 4 goto universal
if errorlevel 3 goto powerIntensive
if errorlevel 2 goto gpu
if errorlevel 1 goto storage

:storage
cls
echo %cGreen%Applying Storage Device Tweaks...%cReset%
start cmd /c "%~dp0\tweaks\storage_tweaks.bat"
pause
goto menu

:gpu
cls
echo %cGreen%Applying GPU Performance Tweaks...%cReset%
start cmd /c "%~dp0\tweaks\gpu_tweaks.bat"
pause
goto menu

:powerIntensive
cls
echo %cGreen%Applying Power-Intensive Tweaks...%cReset%
start cmd /c "%~dp0\tweaks\power_intensive_tweaks.bat"
pause
goto menu

:universal
cls
echo %cGreen%Applying Universal System Tweaks...%cReset%
start cmd /c "%~dp0\tweaks\universal_tweaks.bat"
pause
goto menu
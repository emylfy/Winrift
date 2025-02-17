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
echo %cMauve% '%cGrey% [1] SSD/NVMe Tweaks                    %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] GPU Performance Tweaks             %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Universal System Tweaks            %cMauve%'%cReset%
echo %cMauve% '%cGrey% [4] Exit                               %cMauve%'%cReset%
echo %cMauve% +----------------------------------------+%cReset%
choice /C 1234 /N /M "Select an option: "
if errorlevel 4 goto :eof
if errorlevel 3 goto :ssd
if errorlevel 2 goto :gpu
if errorlevel 1 goto :universal

:ssd
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

:universal
cls
echo %cGreen%Applying Universal System Tweaks...%cReset%
start cmd /c "%~dp0\tweaks\universal_tweaks.bat"
pause
goto menu
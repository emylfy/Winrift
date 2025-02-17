@echo off
setlocal EnableDelayedExpansion

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
if errorlevel 3 goto :universal
if errorlevel 2 goto :gpu
if errorlevel 1 goto :ssd

:ssd
cls
echo %cGreen%Applying Storage Device Tweaks...%cReset%
start cmd /c "%~dp0\tweaks\storage_tweaks.bat"
pause
goto :eof

:gpu
cls
echo %cGreen%Applying GPU Performance Tweaks...%cReset%
start cmd /c "%~dp0\tweaks\gpu_tweaks.bat"
pause
goto :eof

:universal
cls
echo %cGreen%Applying Universal System Tweaks...%cReset%
start cmd /c "%~dp0\tweaks\universal_tweaks.bat"
pause
goto :eof
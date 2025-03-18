@echo off
setlocal EnableDelayedExpansion

set Purple=[38;5;141m
set Grey=[38;5;250m
set Reset=[0m
set Red=[38;5;203m
set Green=[38;5;120m

:menu
cls
echo.
echo %Purple% +----------------------------------------+%Reset%
echo %Purple% '%Grey% [1] SSD/NVMe Tweaks                    %Purple%'%Reset%
echo %Purple% '%Grey% [2] GPU Performance Tweaks             %Purple%'%Reset%
echo %Purple% '%Grey% [3] Universal System Tweaks            %Purple%'%Reset%
echo %Purple% '%Grey% [4] Exit                               %Purple%'%Reset%
echo %Purple% +----------------------------------------+%Reset%
choice /C 1234 /N /M "Select an option: "
if errorlevel 4 goto :eof
if errorlevel 3 goto :universal
if errorlevel 2 goto :gpu
if errorlevel 1 goto :ssd

:ssd
cls
echo %Green%Applying Storage Device Tweaks...%Reset%
start cmd /c "%~dp0..\tweaks\SSD.bat"
pause
goto :menu

:gpu
cls
start cmd /c "%~dp0..\tweaks\Gpu.bat"
pause
goto :menu

:universal
cls
echo %Green%Applying Universal System Tweaks...%Reset%
start cmd /c "%~dp0..\tweaks\Universal.bat"
pause
goto :menu
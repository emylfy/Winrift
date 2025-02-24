@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (
    echo Not running as admin. Elevating...
    where wt.exe >nul 2>&1
    if %errorlevel% equ 0 (
        powershell "Start-Process -FilePath 'wt.exe' -ArgumentList 'cmd /k \"%~0\"' -Verb runAs"
    ) else (
        powershell "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k \"%~0\"' -Verb runAs"
    )
    exit /b
)

set Purple=[38;5;141m
set Grey=[38;5;250m
set Reset=[0m
set Red=[38;5;203m
set Green=[38;5;120m

cls
echo.
echo %Purple% +-----------------------------------+%Reset%
echo %Purple% '%Grey% Launching Windows Utility Tool... %Purple%'%Reset%
echo %Purple% +-----------------------------------+%Reset%

wt.exe cmd /c powershell "irm 'https://christitus.com/win' | iex"
if %errorlevel% neq 0 (
    powershell "irm 'https://christitus.com/win' | iex"
)
exit
@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (
    echo Not running as admin. Elevating...
    where wt.exe >nul 2>&1
    if %errorlevel% equ 0 (
        powershell -Command "Start-Process -FilePath 'wt.exe' -ArgumentList 'cmd /k \"%~0\"' -Verb runAs"
    ) else (
        powershell -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k \"%~0\"' -Verb runAs"
    )
    exit /b
)

set Purple=[38;5;141m
set Grey=[38;5;250m
set Reset=[0m
set Red=[38;5;203m
set Green=[38;5;120m

:PrivacySexy
cls
echo %Purple% +--------------------------------------------------------+%Reset%
echo %Purple% '%Grey% Privacy.Sexy Settings                                  %Purple%'%Reset%
echo %Purple% +--------------------------------------------------------+%Reset%
echo %Purple% '%Grey% [1] Build your own batch from privacy.sexy website     %Purple%'%Reset%
echo %Purple% '%Grey% [2] Download and Run Standard preset (for most users)  %Purple%'%Reset%
echo %Purple% '%Grey% [3] Back to Main Menu                                  %Purple%'%Reset%
echo %Purple% +--------------------------------------------------------+%Reset%

choice /C 123 /N /M ">"
set /a "privacy_choice=%errorlevel%"
if !privacy_choice! equ 3 exit
if !privacy_choice! equ 2 (
    echo %Grey%Downloading and executing privacy script...%Reset%
    powershell -Command "irm 'https://raw.githubusercontent.com/emylfy/simplify11/refs/heads/main/modules/tweaks/Privacy.bat' -OutFile \"%TEMP%\Privacy.bat\"" && start cmd /c "%TEMP%\Privacy.bat"
    if !errorlevel! equ 0 (
        echo %Green%Privacy script executed successfully.%Reset%
    ) else (
        echo %Red%Failed to execute privacy script.%Reset%
    )
    pause
    goto main
)
if errorlevel 1 (
    start "" "https://privacy.sexy"
    goto main
)
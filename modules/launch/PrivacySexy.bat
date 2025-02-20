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

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

:PrivacySexy
cls
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Privacy.Sexy Settings                                  %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Build your own batch from privacy.sexy website     %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] Download and Run Standard preset (for most users)  %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Back to Main Menu                                  %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%

choice /C 123 /N /M ">"
set /a "privacy_choice=%errorlevel%"
if !privacy_choice! equ 3 exit
if !privacy_choice! equ 2 (
    echo %cGrey%Downloading and executing privacy script...%cReset%
    powershell -Command "irm 'https://raw.githubusercontent.com/emylfy/simplify11/refs/heads/main/modules/tweaks/Privacy.bat' -OutFile \"%TEMP%\Privacy.bat\"" && start cmd /c "%TEMP%\Privacy.bat"
    if !errorlevel! equ 0 (
        echo %cGreen%Privacy script executed successfully.%cReset%
    ) else (
        echo %cRed%Failed to execute privacy script.%cReset%
    )
    pause
    goto main
)
if errorlevel 1 (
    start "" "https://privacy.sexy"
    goto main
)
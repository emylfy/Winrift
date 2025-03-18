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


:menu
cls
echo %Purple% +--------------------------------------------------------+%Reset%
echo %Purple% '%Grey% Customization Options                                  %Purple%'%Reset%
echo %Purple% +--------------------------------------------------------+%Reset%
echo %Purple% '%Grey% [1] Set Short Date and Hours Format - Feb 17, 17:57    %Purple%'%Reset%
echo %Purple% '%Grey% [2] Disable automatic pin of folders to Quick Access   %Purple%'%Reset%
echo %Purple% '%Grey% [3] Selectively pull icons from folders in start menu  %Purple%'%Reset%
echo %Purple% +-Require-Internet-Connection----------------------------+%Reset%
echo %Purple% '%Grey% [4] Launch Windots - configs, cursor, wallpapers       %Purple%'%Reset%
echo %Purple% +--------------------------------------------------------+%Reset%
echo %Purple% '%Grey% [5] Back to Menu                                       %Purple%'%Reset%
echo %Purple% +--------------------------------------------------------+%Reset%

choice /C 12345 /N /M ">"
set /a "menu_choice=%errorlevel%"
if !menu_choice! equ 5 exit
if !menu_choice! equ 4 goto Windots
if !menu_choice! equ 3 goto Organizer
if !menu_choice! equ 2 goto disableQuickAccess
if !menu_choice! equ 1 goto shortDateHours
goto menu

:shortDateHours
cls
echo %Grey%Setting short date and hours format...%Reset%
reg add "HKCU\Control Panel\International" /v sShortDate /t REG_SZ /d "dd MMM yyyy" /f
reg add "HKCU\Control Panel\International" /v sShortTime /t REG_SZ /d "HH:mm" /f
reg add "HKCU\Control Panel\International" /v sTimeFormat /t REG_SZ /d "HH:mm:ss" /f
echo %Grey%Date and time format updated successfully. Changes will take effect after restart.%Reset%
pause
goto menu

:disableQuickAccess
cls
echo %Grey%Disabling automatic addition of folders to Quick Access...%Reset%
powershell "Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowFrequent' -Type DWord -Value 0"
powershell "Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowRecent' -Type DWord -Value 0"
powershell "$quickAccess = (New-Object -ComObject shell.application).Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}').Items(); $quickAccess | ForEach-Object { $_.InvokeVerb('remove') }"
powershell "Stop-Process -Name explorer -Force; Start-Process explorer"
echo %Green%Quick Access settings updated successfully. Explorer will restart to apply changes.%Reset%
pause
goto menu

:extractStartFolders
cls
explorer /select,%TEMP%\simplify11\simplify11-main\modules\tweaks\Organizer.ps1
goto menu

:Windots
cls
wt powershell "iwr 'https://dub.sh/windots' |iex "
goto menu

:reg
call "%~dp0\..\reg_helper.bat" %*
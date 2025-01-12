@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (powershell start -verb runas '%~0' & exit)

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

:: Storage Device Selection
:storageSelection
cls
echo.
echo %cMauve% +-----------------------------------+%cReset%
echo %cMauve% '%cGrey% Storage Device Selection          %cMauve%'%cReset%
echo %cMauve% +-----------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] SSD/NVMe                      %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] HDD                           %cMauve%'%cReset%
echo %cMauve% +-----------------------------------+%cReset%
choice /C 12 /N /M ">" 2>nul
if errorlevel 255 goto storageSelectionError
if errorlevel 2 goto storageHDD
if errorlevel 1 goto storageSSD
goto storageSelectionError

:storageSelectionError
echo %cRed%Invalid selection. Please try again.%cReset%
timeout /t 2 >nul
goto storageSelection

:storageHDD
echo Skipping tweaks...
goto :eof

:storageSSD
echo %cGreen%SSD/NVMe selected - Applying optimizations...%cReset%
:: Enable and optimize TRIM for SSD
fsutil behavior set DisableDeleteNotify 0
:: Disable defragmentation for SSDs
schtasks /Change /TN "\Microsoft\Windows\Defrag\ScheduledDefrag" /Disable
:: Disable NTFS last access time updates
fsutil behavior set disablelastaccess 1
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsDisable8dot3NameCreation" "REG_DWORD" "1" "Disabled legacy 8.3 filename creation for better SSD performance"
pause

:reg
call "%~dp0\..\reg_helper.bat" %*
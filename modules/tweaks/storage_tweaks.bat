@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (powershell start -verb runas '%~0' & exit)

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

powershell -command "Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' -or $_.BusType -eq 'NVMe' } | Measure-Object | ForEach-Object { if ($_.Count -gt 0) { exit 0 } else { exit 1 } }"
if %errorlevel% equ 0 (
    echo Enable and optimize TRIM for SSD
    fsutil behavior set DisableDeleteNotify 0

    echo Disable defragmentation for SSDs
    schtasks /Change /TN "\Microsoft\Windows\Defrag\ScheduledDefrag" /Disable
		
    echo Disable NTFS last access time updates
    fsutil behavior set disablelastaccess 1
    call :reg "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsDisable8dot3NameCreation" "REG_DWORD" "1" "Disabled legacy 8.3 filename creation for better SSD performance"
) else (
    echo No SSD or NVMe detected. Skipping tweaks.
)
pause

:reg
call "%~dp0\..\reg_helper.bat" %*
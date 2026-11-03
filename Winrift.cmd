@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Start-Winrift.ps1" %*
set "winriftExit=%errorlevel%"
if not "%winriftExit%"=="0" (
    echo.
    echo Winrift failed. Startup logs: %%LOCALAPPDATA%%\Winrift\logs
    pause
)
exit /b %winriftExit%
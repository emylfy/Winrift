:reg
setlocal
set "key=%~1"
set "valueName=%~2"
set "valueType=%~3"
set "valueData=%~4"
set "comment=%~5"

:: Convert registry hive shortcuts to full paths
set "key=%key:HKLM\=HKEY_LOCAL_MACHINE\%"
set "key=%key:HKCU\=HKEY_CURRENT_USER\%"

:: Create the registry key path if it doesn't exist
reg add "%key%" /f >nul 2>&1

:: Handle different value types
if /i "%valueType%"=="REG_DWORD" (
	reg add "%key%" /v "%valueName%" /t REG_DWORD /d "%valueData%" /f >nul 2>&1
) else if /i "%valueType%"=="REG_SZ" (
	reg add "%key%" /v "%valueName%" /t REG_SZ /d "%valueData%" /f >nul 2>&1
) else if /i "%valueType%"=="REG_BINARY" (
	reg add "%key%" /v "%valueName%" /t REG_BINARY /d "%valueData%" /f >nul 2>&1
) else (
	echo %cRed%[FAILED]%cReset% Unsupported registry value type: %valueType%
	exit /b 1
)

if %errorlevel% equ 0 (
	echo %cGreen%[SUCCESS]%cReset% %comment%
) else (
	echo %cRed%[FAILED]%cReset% Failed to set %valueName%
	exit /b 1
)

exit /b 0
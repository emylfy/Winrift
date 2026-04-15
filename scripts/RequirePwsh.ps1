function Install-Pwsh {
    # Returns the path to pwsh.exe, installing it if necessary.
    # Expects to run as admin — caller must elevate first.
    # Returns $null if all install methods fail.

    # Already on PATH
    $existing = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
    if ($existing) { return $existing }

    # Default install location
    $pwsh = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh) { return $pwsh }

    Write-Host ""
    Write-Host "  Winrift requires PowerShell 7. Installing..." -ForegroundColor Yellow
    Write-Host ""

    # Method 1: winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  [1/2] Trying winget..." -ForegroundColor Cyan
        & winget install --id Microsoft.PowerShell --accept-package-agreements --accept-source-agreements --silent 2>&1 | Out-Null
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
        if (Test-Path $pwsh) {
            Write-Host "  PowerShell 7 installed successfully." -ForegroundColor Green
            return $pwsh
        }
        Write-Host "  winget failed, trying fallback..." -ForegroundColor Yellow
    }

    # Method 2: Direct MSI download + msiexec
    Write-Host "  [2/2] Downloading MSI installer..." -ForegroundColor Cyan
    try {
        $arch = if ([Environment]::Is64BitOperatingSystem) {
            if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "x64" }
        } else { "x86" }
        $msiUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.7/PowerShell-7.4.7-win-$arch.msi"
        $msiPath = Join-Path $env:TEMP "pwsh-install.msi"

        Write-Host "  Downloading: $msiUrl" -ForegroundColor DarkGray
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -ErrorAction Stop

        Write-Host "  Running installer..." -ForegroundColor Cyan
        Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 ENABLE_PSREMOTING=0 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1" -Wait
        Remove-Item $msiPath -Force -ErrorAction SilentlyContinue

        $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
        if (Test-Path $pwsh) {
            Write-Host "  PowerShell 7 installed successfully." -ForegroundColor Green
            return $pwsh
        }
    } catch {
        Write-Host "  MSI install failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  Automatic installation failed. Please install PowerShell 7 manually:" -ForegroundColor Red
    Write-Host "  https://aka.ms/powershell-release?tag=stable" -ForegroundColor Cyan
    Write-Host ""
    $null = Read-Host "  Press Enter to exit"
    return $null
}

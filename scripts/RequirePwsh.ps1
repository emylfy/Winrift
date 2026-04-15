function Install-Pwsh {
    $existing = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
    if ($existing) { return $existing }

    $pwsh = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh) { return $pwsh }

    $localPwsh = "$env:LOCALAPPDATA\Winrift\pwsh\pwsh.exe"
    if (Test-Path $localPwsh) { return $localPwsh }

    Write-Host ""
    Write-Host "  Winrift requires PowerShell 7. Downloading portable (~50MB)..." -ForegroundColor Yellow
    Write-Host ""

    $arch = if ([Environment]::Is64BitOperatingSystem) {
        if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "x64" }
    } else { "x86" }

    $zipUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.7/PowerShell-7.4.7-win-$arch.zip"
    $zipPath = Join-Path $env:TEMP "pwsh-portable.zip"
    $destDir = "$env:LOCALAPPDATA\Winrift\pwsh"

    try {
        Write-Host "  Downloading..." -ForegroundColor Cyan
        Start-BitsTransfer -Source $zipUrl -Destination $zipPath -DisplayName "PowerShell 7" -ErrorAction Stop

        Write-Host "  Extracting..." -ForegroundColor Cyan
        $ProgressPreference = 'SilentlyContinue'
        if (Test-Path $destDir) { Remove-Item $destDir -Recurse -Force -ErrorAction SilentlyContinue }
        Expand-Archive -Path $zipPath -DestinationPath $destDir -Force
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

        if (Test-Path "$destDir\pwsh.exe") {
            Write-Host "  PowerShell 7 ready." -ForegroundColor Green
            return "$destDir\pwsh.exe"
        }
    } catch {
        Write-Host "  Download failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  Please install PowerShell 7 manually:" -ForegroundColor Red
    Write-Host "  https://aka.ms/powershell-release?tag=stable" -ForegroundColor Cyan
    Write-Host ""
    $null = Read-Host "  Press Enter to exit"
    return $null
}

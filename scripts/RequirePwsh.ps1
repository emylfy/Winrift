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
        if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -eq "ARM64") { "arm64" } else { "x64" }
    } else { "x86" }

    # Resolve the latest stable PS7 from GitHub; fall back to a known-good pin
    # if the API is unreachable (offline, rate-limited). Avoids the version
    # going stale in source over the years this must keep working unattended.
    $pwshVer = "7.4.7"
    try {
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/PowerShell/PowerShell/releases/latest" -Headers @{ "User-Agent" = "winrift" } -TimeoutSec 10 -ErrorAction Stop
        if ($rel.tag_name -match '^v?(\d+\.\d+\.\d+)$') { $pwshVer = $Matches[1] }
    } catch { }

    $zipUrl = "https://github.com/PowerShell/PowerShell/releases/download/v$pwshVer/PowerShell-$pwshVer-win-$arch.zip"
    $zipPath = Join-Path $env:TEMP "pwsh-portable.zip"
    $destDir = "$env:LOCALAPPDATA\Winrift\pwsh"

    try {
        Write-Host "  Downloading..." -ForegroundColor Cyan
        # BITS may be unavailable or denied. HTTPS download does not require
        # the BITS service and keeps first launch usable on those systems.
        try {
            Start-BitsTransfer -Source $zipUrl -Destination $zipPath -DisplayName "PowerShell 7" -ErrorAction Stop
        } catch {
            Write-Host "  BITS unavailable; retrying direct HTTPS download..." -ForegroundColor Yellow
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -TimeoutSec 180 -ErrorAction Stop
        }

        Write-Host "  Extracting..." -ForegroundColor Cyan
        $ProgressPreference = 'SilentlyContinue'
        if (Test-Path -LiteralPath $destDir) {
            $runtimeRoot=[IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Winrift')).TrimEnd('\')+'\'
            $resolved=[IO.Path]::GetFullPath($destDir)
            $preserved=$resolved+'.previous-'+[guid]::NewGuid().ToString('N')
            if(-not $resolved.StartsWith($runtimeRoot,[StringComparison]::OrdinalIgnoreCase) -or -not $preserved.StartsWith($runtimeRoot,[StringComparison]::OrdinalIgnoreCase)) { throw 'Portable runtime path escaped the Winrift directory.' }
            Move-Item -LiteralPath $resolved -Destination $preserved -ErrorAction Stop
        }
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

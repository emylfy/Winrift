# Headless Winrift bootstrap: fetch Winrift if needed, then apply a profile in
# one non-interactive pass. Intended for autounattend FirstLogon and any scripted
# provisioning. PS 5.1-safe (no PS7 syntax) — it hands off to Winrift.ps1, which
# bootstraps PS7 itself.
#
# Profile resolution: $env:WINRIFT_PROFILE, then
# C:\Windows\Setup\Scripts\winrift-profile.json, then C:\Winrift\profile.json.

$ErrorActionPreference = 'Continue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }

$profilePath = $env:WINRIFT_PROFILE
if (-not $profilePath) {
    foreach ($cand in @("C:\Windows\Setup\Scripts\winrift-profile.json", "C:\Winrift\profile.json")) {
        if (Test-Path $cand) { $profilePath = $cand; break }
    }
}
if (-not $profilePath -or -not (Test-Path $profilePath)) {
    Write-Host "Winrift apply: no profile found (set WINRIFT_PROFILE or place winrift-profile.json)." -ForegroundColor Yellow
    return
}

$repo        = "emylfy/winrift"
$tempPath    = "$env:TEMP\winrift"
$extractPath = Join-Path $tempPath "winrift-main"
$zipPath     = Join-Path $tempPath "winrift.zip"
$archiveUrl  = "https://github.com/$repo/archive/refs/heads/main.zip"

if (-not (Test-Path "$extractPath\Winrift.ps1")) {
    if (-not (Test-Path $tempPath)) { New-Item -ItemType Directory -Path $tempPath | Out-Null }
    Write-Host "Downloading Winrift..." -ForegroundColor Cyan
    try {
        Start-BitsTransfer -Source $archiveUrl -Destination $zipPath -ErrorAction Stop
        if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue }
        Expand-Archive -Path $zipPath -DestinationPath $tempPath -Force
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Failed to download Winrift: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}

if (-not (Test-Path "$extractPath\Winrift.ps1")) {
    Write-Host "Winrift.ps1 not found after download." -ForegroundColor Red
    return
}

Write-Host "Applying Winrift profile: $profilePath" -ForegroundColor Cyan
& "$extractPath\Winrift.ps1" -Apply $profilePath -NoConfirm

# Online entry point. Keep this downloader compatible with Windows PowerShell 5.1.
if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

$Host.UI.RawUI.WindowTitle = "Launcher"

# Incremental launcher: skip download if the local copy in $env:TEMP\winrift
# matches the latest remote version. Saves bandwidth and 5-15 seconds on every
# subsequent run, especially relevant for the README one-liner workflow where
# people re-run `irm | iex` repeatedly.

$repo        = "emylfy/winrift"
$tempPath    = "$env:TEMP\winrift"
$extractPath = Join-Path $tempPath "winrift-main"
$zipPath     = Join-Path $tempPath "winrift.zip"
$localVerFile  = Join-Path $extractPath "config\version.json"
$remoteVerUrl  = "https://raw.githubusercontent.com/$repo/main/config/version.json"
$archiveUrl    = "https://github.com/$repo/archive/refs/heads/main.zip"

if (-not (Test-Path $tempPath)) {
    New-Item -ItemType Directory -Path $tempPath | Out-Null
}

function Get-LocalVersion {
    if (-not (Test-Path $localVerFile)) { return $null }
    try {
        return (Get-Content $localVerFile -Raw | ConvertFrom-Json).version
    } catch { return $null }
}

function Get-RemoteVersion {
    try {
        $remote = Invoke-RestMethod -Uri $remoteVerUrl -TimeoutSec 5 -ErrorAction Stop
        return $remote.version
    } catch { return $null }
}

$localVer  = Get-LocalVersion
$remoteVer = Get-RemoteVersion
$needDownload = $true

if ($localVer -and $remoteVer) {
    if ($localVer -eq $remoteVer) {
        Write-Host "Winrift v$localVer is already up to date — skipping download." -ForegroundColor Green
        $needDownload = $false
    } else {
        Write-Host "Updating Winrift: v$localVer -> v$remoteVer" -ForegroundColor Cyan
    }
} elseif ($localVer -and -not $remoteVer) {
    # Network unreachable — fall back to existing copy if it's there
    Write-Host "Network unreachable, using cached Winrift v$localVer" -ForegroundColor Yellow
    $needDownload = $false
}

if ($needDownload) {
    Write-Host "Downloading Winrift..." -ForegroundColor Cyan
    Write-Progress -Activity "Downloading Winrift" -Status "Initializing..." -PercentComplete 0

    try {
        try {
            Start-BitsTransfer -Source $archiveUrl -Destination $zipPath -DisplayName "Downloading Winrift" -ErrorAction Stop
        } catch {
            Invoke-WebRequest -Uri $archiveUrl -OutFile $zipPath -UseBasicParsing -TimeoutSec 180 -ErrorAction Stop
        }

        Write-Host "Download complete!" -ForegroundColor Green

        Write-Host "Extracting files..." -ForegroundColor Cyan
        Write-Progress -Activity "Installing Winrift" -Status "Extracting..." -PercentComplete 50

        # Wipe stale extracted dir before re-expanding so removed files actually go away
        if (Test-Path $extractPath) {
            Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        Expand-Archive -Path $zipPath -DestinationPath $tempPath -Force
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue

        Write-Progress -Activity "Installing Winrift" -Status "Complete" -PercentComplete 100
    } catch {
        Write-Progress -Activity "Installing Winrift" -Status "Error" -PercentComplete 100
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host "Please download manually from: https://github.com/$repo" -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        return
    } finally {
        Write-Progress -Activity "Installing Winrift" -Completed
    }
}

if (-not (Test-Path "$extractPath\Winrift.ps1")) {
    Write-Host "Winrift.ps1 not found at $extractPath — installation incomplete." -ForegroundColor Red
    Start-Sleep -Seconds 5
    return
}

Write-Host @"
 __        ___       ____  _  __ _
 \ \      / (_)_ __ |  _ \(_)/ _| |_
  \ \ /\ / /| | '_ \| |_) | | |_| __|
   \ V  V / | | | | |  _ <| |  _| |_
    \_/\_/  |_|_| |_|_| \_\_|_|  \__|
"@ -ForegroundColor Cyan

# Let the local entry point handle elevation and select the interactive host.
$winriftPath = Join-Path $extractPath 'Winrift.ps1'
$shellPath = (Get-Process -Id $PID -ErrorAction Stop).Path
& $shellPath -NoProfile -ExecutionPolicy Bypass -File $winriftPath

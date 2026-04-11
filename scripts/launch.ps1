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
        Start-BitsTransfer -Source $archiveUrl `
                          -Destination $zipPath `
                          -DisplayName "Downloading Winrift" `
                          -Description "Downloading required files..."

        Write-Progress -Activity "Downloading Winrift" -Status "Complete" -PercentComplete 100
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

# Spawn Winrift.ps1 with -ExecutionPolicy Bypass so the new process can run
# regardless of system execution policy.
$winriftPath = "$extractPath\Winrift.ps1"
if (Get-Command wt -ErrorAction SilentlyContinue) {
    wt powershell.exe -NoExit -ExecutionPolicy Bypass -File $winriftPath
} else {
    Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", $winriftPath
}

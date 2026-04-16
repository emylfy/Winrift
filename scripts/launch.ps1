# PS7 requirement gate — auto-install portable and relaunch in pwsh.
# launch.ps1 runs via irm|iex so $PSScriptRoot is empty — inline the installer.
# Portable zip goes to %LOCALAPPDATA%\Winrift\pwsh — no admin needed.
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
    if (-not $pwsh) {
        $pwsh = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
        if (-not (Test-Path $pwsh)) {
            $pwsh = "$env:LOCALAPPDATA\Winrift\pwsh\pwsh.exe"
            if (-not (Test-Path $pwsh)) { $pwsh = $null }
        }
    }

    if (-not $pwsh) {
        Write-Host ""
        Write-Host "  Winrift requires PowerShell 7. Downloading portable (~50MB)..." -ForegroundColor Yellow
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
            $pwsh = "$destDir\pwsh.exe"
            if (-not (Test-Path $pwsh)) { $pwsh = $null }
        } catch {
            Write-Host "  Download failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        if (-not $pwsh) {
            Write-Host "  Please install PowerShell 7 manually: https://aka.ms/powershell-release?tag=stable" -ForegroundColor Red
            $null = Read-Host "  Press Enter to exit"
            return
        }
        Write-Host "  PowerShell 7 ready." -ForegroundColor Green
    }

    & $pwsh -NoExit -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/emylfy/winrift/main/scripts/launch.ps1 | iex"
    return
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
# regardless of system execution policy. Resolve the current pwsh.exe by full
# path — portable PS7 installed to %LOCALAPPDATA%\Winrift\pwsh\ is NOT on PATH,
# so `wt pwsh.exe` / `Start-Process pwsh.exe` would fail with 0x80070002.
$winriftPath = "$extractPath\Winrift.ps1"
$pwshPath = (Get-Process -Id $PID).Path
if (-not $pwshPath -or -not (Test-Path $pwshPath)) { $pwshPath = 'pwsh.exe' }
if (Get-Command wt -ErrorAction SilentlyContinue) {
    wt $pwshPath -NoExit -ExecutionPolicy Bypass -File $winriftPath
} else {
    Start-Process $pwshPath -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", $winriftPath
}

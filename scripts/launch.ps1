$Host.UI.RawUI.WindowTitle = "Launcher"

$tempPath = "$env:TEMP\winrift"
$zipPath = "$tempPath\winrift.zip"

if (!(Test-Path $tempPath)) {
    New-Item -ItemType Directory -Path $tempPath | Out-Null
}

Write-Host "Downloading Winrift..." -ForegroundColor Cyan
Write-Progress -Activity "Downloading Winrift" -Status "Initializing..." -PercentComplete 0

try {
    Start-BitsTransfer -Source "https://github.com/emylfy/winrift/archive/refs/heads/main.zip" `
                      -Destination $zipPath `
                      -DisplayName "Downloading Winrift" `
                      -Description "Downloading required files..."

    Write-Progress -Activity "Downloading Winrift" -Status "Complete" -PercentComplete 100
    Write-Host "Download complete!" -ForegroundColor Green

    Write-Host "Extracting files..." -ForegroundColor Cyan
    Write-Progress -Activity "Installing Winrift" -Status "Extracting..." -PercentComplete 50

    Expand-Archive -Path $zipPath -DestinationPath $tempPath -Force

    Write-Progress -Activity "Installing Winrift" -Status "Complete" -PercentComplete 100

    Write-Host @"
 __        ___       ____  _  __ _
 \ \      / (_)_ __ |  _ \(_)/ _| |_
  \ \ /\ / /| | '_ \| |_) | | |_| __|
   \ V  V / | | | | |  _ <| |  _| |_
    \_/\_/  |_|_| |_|_| \_\_|_|  \__|
"@ -ForegroundColor Cyan

    if (Get-Command wt -ErrorAction SilentlyContinue) {
        wt powershell.exe -NoExit -File "$env:TEMP\winrift\winrift-main\Winrift.ps1"
    } else {
        Start-Process powershell.exe -ArgumentList "-NoExit", "-File", "$env:TEMP\winrift\winrift-main\Winrift.ps1"
    }
}
catch {
    Write-Progress -Activity "Installing Winrift" -Status "Error" -PercentComplete 100
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Please download manually from: https://github.com/emylfy/winrift" -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}
finally {
    Write-Progress -Activity "Installing Winrift" -Completed
}

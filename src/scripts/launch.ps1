# Create temp directory
$tempPath = "$env:TEMP\simplify11"
$zipPath = "$tempPath\simplify11.zip"

# Create directory if it doesn't exist
if (!(Test-Path $tempPath)) {
    New-Item -ItemType Directory -Path $tempPath | Out-Null
}

# Try to add exclusion if running as admin
try {
    Add-MpPreference -ExclusionPath $tempPath -ErrorAction SilentlyContinue
} catch {
    Write-Host "Note: Running without admin rights, continuing normally..." -ForegroundColor Yellow
}

Write-Host "Downloading Simplify11..." -ForegroundColor Cyan
Write-Progress -Activity "Downloading Simplify11" -Status "Initializing..." -PercentComplete 0

try {
    # Download using Start-BitsTransfer (native Windows command)
    Start-BitsTransfer -Source "https://github.com/emylfy/simplify11/archive/refs/heads/main.zip" `
                      -Destination $zipPath `
                      -DisplayName "Downloading Simplify11" `
                      -Description "Downloading required files..."

    Write-Progress -Activity "Downloading Simplify11" -Status "Complete" -PercentComplete 100
    Write-Host "Download complete!" -ForegroundColor Green
    
    Write-Host "Extracting files..." -ForegroundColor Cyan
    Write-Progress -Activity "Installing Simplify11" -Status "Extracting..." -PercentComplete 50

    # Use native PowerShell commands for extraction
    Expand-Archive -Path $zipPath -DestinationPath $tempPath -Force

    # Copy icon safely
    Copy-Item "$tempPath\simplify11-main\src\media\icon.ico" "$env:APPDATA\icon.ico" -Force

    Write-Progress -Activity "Installing Simplify11" -Status "Creating shortcut..." -PercentComplete 75

    # Create shortcut
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Simplify11.lnk")
    $Shortcut.TargetPath = "$tempPath\simplify11-main\simplify11.bat"
    $Shortcut.IconLocation = "$env:APPDATA\icon.ico"
    $Shortcut.Save()

    Write-Progress -Activity "Installing Simplify11" -Status "Complete" -PercentComplete 100

    Write-Host @"
 ____  _                 _ _  __       _ _ 
/ ___|(_)_ __ ___  _ __ | (_)/ _|_   _/ / |
\___ \| | '_ ' _ \| '_ \| | | |_| | | | | |
 ___) | | | | | | | |_) | | |  _| |_| | | |
|____/|_|_| |_| |_| .__/|_|_|_|  \__, | |_|
                  |_|             |___/     
"@ -ForegroundColor Cyan

    Write-Host "Installation complete! Starting Simplify11..." -ForegroundColor Green

    # Launch the script
    Start-Process "$tempPath\simplify11-main\simplify11.bat"
}
catch {
    Write-Progress -Activity "Installing Simplify11" -Status "Error" -PercentComplete 100
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Please download manually from: https://github.com/emylfy/simplify11" -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}
finally {
    Write-Progress -Activity "Installing Simplify11" -Completed
}
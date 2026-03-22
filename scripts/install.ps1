$Host.UI.RawUI.WindowTitle = "Winrift - Installer"

$startMenuPath = [System.Environment]::GetFolderPath('Programs')
$shortcutPath = Join-Path -Path $startMenuPath -ChildPath "Winrift.lnk"
$wshShell = New-Object -ComObject WScript.Shell
$shortcut = $wshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/emylfy/winrift/main/scripts/launch.ps1 | iex"'
$shortcut.Description = "Launch Winrift"
$shortcut.WorkingDirectory = $env:USERPROFILE

$icoDir = "$env:APPDATA\Winrift"
if (-not (Test-Path $icoDir)) {
    New-Item -Path $icoDir -ItemType Directory -Force | Out-Null
}

try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/emylfy/winrift/refs/heads/main/media/icon.ico" -OutFile "$icoDir\icon.ico" -ErrorAction Stop
} catch {
    Write-Host "Warning: Could not download icon. Shortcut will use default icon." -ForegroundColor Yellow
}

$icoPath = "$icoDir\icon.ico"
$shortcut.IconLocation = $icoPath
$shortcut.Save()

Write-Host "Shortcut 'Winrift' created in the Start Menu."
Start-Process -FilePath $shortcutPath

exit

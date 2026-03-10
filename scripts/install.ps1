$Host.UI.RawUI.WindowTitle = "Simplify11 - Installer"

$startMenuPath = [System.Environment]::GetFolderPath('Programs')
$shortcutPath = Join-Path -Path $startMenuPath -ChildPath "Simplify11.lnk"
$wshShell = New-Object -ComObject WScript.Shell
$shortcut = $wshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass "iwr \"https://dub.sh/simplify11\" | iex"'
$shortcut.Description = "Launch Simplify11"
$shortcut.WorkingDirectory = $env:USERPROFILE

$icoDir = "$env:APPDATA\Simplify11"
if (-not (Test-Path $icoDir)) {
    New-Item -Path $icoDir -ItemType Directory -Force | Out-Null
}

try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/emylfy/simplify11/refs/heads/main/media/icon.ico" -OutFile "$icoDir\icon.ico" -ErrorAction Stop
} catch {
    Write-Host "Warning: Could not download icon. Shortcut will use default icon." -ForegroundColor Yellow
}

$icoPath = "$icoDir\icon.ico"
$shortcut.IconLocation = $icoPath
$shortcut.Save()

Write-Host "Shortcut 'Simplify11' created in the Start Menu."
Start-Process -FilePath $shortcutPath

exit
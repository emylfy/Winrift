$Host.UI.RawUI.WindowTitle = "Winrift - Installer"

$startMenuPath = [System.Environment]::GetFolderPath('Programs')
$shortcutPath = Join-Path -Path $startMenuPath -ChildPath "Winrift.lnk"
$wshShell = New-Object -ComObject WScript.Shell
$shortcut = $wshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -Command "irm https://github.com/emylfy/winrift/releases/latest/download/launch.ps1 | iex"'
if($PSScriptRoot -and (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'Start-Winrift.ps1'))){
    $shortcut.Arguments='-NoProfile -ExecutionPolicy Bypass -File "'+(Join-Path $PSScriptRoot 'Start-Winrift.ps1')+'"'
}
$shortcut.Description = "Launch Winrift"
$shortcut.WorkingDirectory = $env:USERPROFILE

$icoDir = "$env:LOCALAPPDATA\Winrift"
if (-not (Test-Path $icoDir)) {
    New-Item -Path $icoDir -ItemType Directory -Force | Out-Null
}

try {
    Invoke-WebRequest -Uri "https://github.com/emylfy/winrift/releases/latest/download/icon.ico" -OutFile "$icoDir\icon.ico" -ErrorAction Stop
} catch {
    Write-Host "Warning: Could not download icon. Shortcut will use default icon." -ForegroundColor Yellow
}

$icoPath = "$icoDir\icon.ico"
$shortcut.IconLocation = $icoPath
$shortcut.Save()

Write-Host "Shortcut 'Winrift' created in the Start Menu."
Start-Process -FilePath $shortcutPath

exit

$startMenuPath = [System.Environment]::GetFolderPath('Programs')
$shortcutPath = Join-Path -Path $startMenuPath -ChildPath "Simplify11.lnk"
$wshShell = New-Object -ComObject WScript.Shell
$shortcut = $wshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass "iwr \"https://dub.sh/simplify11\" | iex"'
$shortcut.Description = "Launch Simplify11"
$shortcut.WorkingDirectory = $startMenuPath

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/emylfy/simplify11/refs/heads/main/src/media/icon.ico" -OutFile "$env:APPDATA\icon.ico"

$icoPath = "$env:APPDATA\icon.ico"
$shortcut.IconLocation = $icoPath
$shortcut.Save()

Write-Host "Shortcut 'Simplify11' created in the Start Menu."
Start-Process -FilePath $shortcutPath

exit
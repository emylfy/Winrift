# Define the path to the Start Menu Programs folder
$startMenuPath = [System.Environment]::GetFolderPath('Programs')

# Define the path for the shortcut
$shortcutPath = Join-Path -Path $startMenuPath -ChildPath "Simplify11.lnk"

# Create a new COM object for WScript.Shell
$wshShell = New-Object -ComObject WScript.Shell

# Create a new shortcut
$shortcut = $wshShell.CreateShortcut($shortcutPath)

# Set the target path to launch PowerShell with the desired command
$shortcut.TargetPath = "powershell.exe"

# Set the arguments to execute the command
$shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -Command "iwr \"https://dub.sh/simplify11\" | iex"'

# Set the shortcut description
$shortcut.Description = "Launch Simplify11"

# Set the shortcut working directory
$shortcut.WorkingDirectory = $startMenuPath

# Download icon
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/emylfy/simplify11/refs/heads/main/src/media/icon.ico" -OutFile "$env:APPDATA\icon.ico"

# Set the path to the ICO file
$icoPath = "$env:APPDATA\icon.ico"

# Set the icon for the shortcut
$shortcut.IconLocation = $icoPath

# Save the shortcut
$shortcut.Save()

# Output confirmation message
Write-Host "Shortcut 'Simplify11' created in the Start Menu."

# Launch the shortcut
Start-Process -FilePath $shortcutPath

exit
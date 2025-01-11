# Download and run the main script
irm 'https://raw.githubusercontent.com/emylfy/simplify11/refs/heads/main/simplify11.bat' -outfile "$env:TEMP\simplify11.bat"

# Download icon
irm "https://raw.githubusercontent.com/emylfy/simplify11/refs/heads/main/src/media/icon.ico" -outfile "$env:APPDATA\icon.ico"

# Create shortcut
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Simplify11.lnk")
$Shortcut.TargetPath = "$env:TEMP\simplify11.bat"
$Shortcut.IconLocation = "$env:APPDATA\icon.ico"
$Shortcut.Save()

# Display Logo
Write-Host @"
   _____                    _____ ______     ______ ____
  / ___/(_)___ ___  ____  / (_)/ ____/_  __/ / / /
  \__ \/ / __ `__ \/ __ \/ / // /_  / / / / / / / 
 ___/ / / / / / / / /_/ / / // __/ / /_/ / /_/ /  
/____/_/_/ /_/ /_/ .___/_/_//_/    \__, /_____/   
                /_/                /____/           
"@ -ForegroundColor Cyan

# Run the script
& "$env:TEMP\simplify11.bat"
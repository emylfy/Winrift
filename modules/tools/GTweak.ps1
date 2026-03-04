. "$PSScriptRoot\..\..\scripts\Common.ps1"

$Host.UI.RawUI.WindowTitle = "GTweak Launcher"

$downloadUrl = "https://github.com/Greedeks/GTweak/releases/latest/download/gtweak.exe"
$downloadPath = "$env:TEMP\gtweak.exe"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -UseBasicParsing
    
    if (Test-Path $downloadPath) {
        Start-Process -FilePath $downloadPath
    } else {
        Write-Host "$Red Failed to download GTweak $Reset"
        exit 1
    }
} catch {
    Write-Host "$Red Failed to launch GTweak: $($_.Exception.Message) $Reset"
    exit 1
}

exit

. "$PSScriptRoot\..\..\scripts\Common.ps1"

$Host.UI.RawUI.WindowTitle = "GTweak Launcher"

$downloadUrl = "https://github.com/Greedeks/GTweak/releases/latest/download/gtweak.exe"
$downloadPath = "$env:TEMP\gtweak.exe"

Write-Host "$Purple +-------------------------+$Reset"
Write-Host "$Purple '$Reset Launching GTweak...     $Purple'$Reset"
Write-Host "$Purple +-------------------------+$Reset"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -UseBasicParsing
    
    if (Test-Path $downloadPath) {
        Write-Host "$Green GTweak downloaded successfully. Launching... $Reset"
        Start-Process -FilePath $downloadPath
    } else {
        Write-Host "$Red Failed to download GTweak. $Reset"
    }
} catch {
    Write-Host "$Red Error downloading GTweak: $($_.Exception.Message) $Reset"
}

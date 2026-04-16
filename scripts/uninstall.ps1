$Host.UI.RawUI.WindowTitle = "Winrift - Uninstall"

Write-Host ""
Write-Host "  Uninstalling Winrift..." -ForegroundColor Yellow
Write-Host ""

$removed = 0

$shortcut = Join-Path ([Environment]::GetFolderPath('StartMenu')) "Programs\Winrift.lnk"
if (Test-Path $shortcut) {
    Remove-Item $shortcut -Force
    Write-Host "  Removed Start Menu shortcut" -ForegroundColor Green
    $removed++
}

$dataDir = Join-Path $env:LOCALAPPDATA "Winrift"
if (Test-Path $dataDir) {
    Remove-Item $dataDir -Recurse -Force
    Write-Host "  Removed data directory: $dataDir" -ForegroundColor Green
    $removed++
}

try {
    Unregister-ScheduledTask -TaskName "Winrift-DriftCheck" -Confirm:$false -ErrorAction Stop
    Write-Host "  Removed drift check scheduled task" -ForegroundColor Green
    $removed++
} catch { $null = $_ }

if ($removed -eq 0) {
    Write-Host "  Nothing to remove — Winrift is not installed." -ForegroundColor DarkGray
} else {
    Write-Host ""
    Write-Host "  Winrift uninstalled." -ForegroundColor Green
}

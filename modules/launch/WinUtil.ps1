if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Not running as admin. Elevating..."
    
    $wtExists = Get-Command wt.exe -ErrorAction SilentlyContinue
    
    if ($wtExists) {
        Start-Process -FilePath 'wt.exe' -ArgumentList "powershell -NoExit -File `"$PSCommandPath`"" -Verb RunAs
    } else {
        Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoExit -File `"$PSCommandPath`"" -Verb RunAs
    }
    
    exit
}

$Purple = [char]0x1b + "[38;5;141m"
$Grey = [char]0x1b + "[38;5;250m"
$Reset = [char]0x1b + "[0m"
$Red = [char]0x1b + "[38;5;203m"
$Green = [char]0x1b + "[38;5;120m"

Clear-Host
Write-Host ""
Write-Host "$Purple +-----------------------------------+$Reset"
Write-Host "$Purple '$Grey Launching Windows Utility Tool... $Purple'$Reset"
Write-Host "$Purple +-----------------------------------+$Reset"

try {
    $wtExists = Get-Command wt.exe -ErrorAction SilentlyContinue
    
    if ($wtExists) {
        Start-Process -FilePath 'wt.exe' -ArgumentList 'powershell -Command "irm ''https://christitus.com/win'' | iex"' -Wait
    } else {
        Invoke-Expression (Invoke-RestMethod -Uri 'https://christitus.com/win')
    }
} catch {
    Write-Host "$Red Failed to launch Windows Utility Tool: $_$Reset"
}

exit
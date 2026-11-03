# Windows PowerShell 5.1 entry point: begin diagnostics before PS7 bootstrap.
param(
    [switch]$DryRun,
    [switch]$NoConfirm,
    [switch]$Uninstall,
    [string]$Apply
)
$ErrorActionPreference = 'Stop'
$started = $false
try {
    $logDir = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Winrift\logs'
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    $log = Join-Path $logDir ("bootstrap_{0}_{1}.log" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'), $PID)
    Start-Transcript -Path $log -ErrorAction Stop | Out-Null
    $started = $true
    Write-Host "Startup log: $log"
    & (Join-Path (Split-Path $PSScriptRoot -Parent) 'Winrift.ps1') @PSBoundParameters
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
} catch {
    Write-Host "Winrift failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
    exit 1
} finally {
    if ($started) { Stop-Transcript | Out-Null }
}
. "$PSScriptRoot\Common.ps1"
$choice=Show-InteractiveMenu -Title 'Uninstall Winrift' -Items @(
    'Remove the Start Menu shortcut and Winrift-DriftCheck task, if present.',
    'Keep all backups, history, saved setups, logs and source files.',
    'Uninstall does not undo system changes.', '---','Y › Uninstall','N › Back'
)
if($choice -ne 'Y'){return}
if($env:WINRIFT_DRY_RUN -eq '1'){Write-Log '[DRY-RUN] Uninstall shortcut and Winrift task; retain backups.';return}
$shortcut=Join-Path ([Environment]::GetFolderPath('Programs')) 'Winrift.lnk'
try{
    if(Test-Path -LiteralPath $shortcut){Remove-Item -LiteralPath $shortcut -ErrorAction Stop}
    $task=Get-ScheduledTask -TaskPath '\' -TaskName 'Winrift-DriftCheck' -ErrorAction SilentlyContinue
    if($task){Unregister-ScheduledTask -TaskPath '\' -TaskName 'Winrift-DriftCheck' -Confirm:$false -ErrorAction Stop}
    Write-Log 'Uninstall operations completed. Backups and history retained.'
}catch{Write-Log "Uninstall incomplete: $($_.Exception.Message)" -Level ERROR}
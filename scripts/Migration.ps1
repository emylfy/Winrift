function Invoke-WinriftUpgradeMigration {
    if($env:WINRIFT_DRY_RUN -eq '1'){return}
    $root=Get-WinriftStateRoot
    $marker=Join-Path $root 'migrations\shared-ui-v1.json'
    if(Test-Path -LiteralPath $marker){return}
    try{
        $legacy=Join-Path $root 'tweaks\desired_state.json'
        $preserved=$null
        if(Test-Path -LiteralPath $legacy){
            $preserved=Join-Path $root ('migrations\legacy-desired-state-'+[guid]::NewGuid().ToString('N')+'.json')
            [IO.Directory]::CreateDirectory((Split-Path $preserved -Parent))|Out-Null
            [IO.File]::Copy($legacy,$preserved,$false)
            if((Get-FileHash -LiteralPath $legacy).Hash -ne (Get-FileHash -LiteralPath $preserved).Hash){throw 'Legacy setup preservation verification failed.'}
        }
        Import-WinriftLegacyRegistryBackups
        $task=Get-ScheduledTask -TaskPath '\' -TaskName 'Winrift-DriftCheck' -ErrorAction SilentlyContinue
        if($task){Unregister-ScheduledTask -TaskPath '\' -TaskName 'Winrift-DriftCheck' -Confirm:$false -ErrorAction Stop}
        Write-WinriftAtomicJson $marker @{schemaVersion=1;completedAt=[DateTimeOffset]::Now.ToString('o');preservedLegacySetup=$preserved;oldBackupsRetained=$true}
    }catch{Write-Log "Upgrade migration incomplete; existing data retained: $($_.Exception.Message)" -Level WARNING}
}
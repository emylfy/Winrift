function Show-InstallPrompt {
    $choice = Show-InteractiveMenu -Title "UniGetUI" -Items @(
        "A package manager UI for Windows that lets you",
        "discover, install, and update apps using winget,",
        "Chocolatey, and other sources.",
        "---",
        "1 › Install UniGetUI",
        "2 › Back to menu"
    )

    if ($choice -eq "1") { Install-UniGetUI }
}

function Install-UniGetUI {
    Clear-Host
    Write-Log -Message "Checking UniGetUI installation..." -Level INFO

    $installed = Install-WingetPackage "Devolutions.UniGetUI" "UniGetUI"

    if ($installed) {
        Write-Log -Message "Launching UniGetUI..." -Level INFO
        Start-Process "unigetui:"
    } else {
        Write-Log -Message "UniGetUI could not be installed via winget. Opening website for manual download..." -Level ERROR
        Start-Process "https://www.marticliment.com/unigetui/"
    }
    Wait-ForUser
}

function Get-UniGetUIExe {
    $local = "$env:LOCALAPPDATA\Programs\UniGetUI\UniGetUI.exe"
    if (Test-Path $local) { return $local }
    $cmd = Get-Command unigetui -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Export-WinriftQueueToUniGetUI {
    param([object[]]$Packages)
    $path=Read-Host 'Save a separate bundle file (full path, .ubundle)'
    if(-not $path) { return }
    $resolved=[IO.Path]::GetFullPath($path)
    $root=[IO.Path]::GetFullPath((Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))
    if($resolved.StartsWith($root.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)) { Write-Log 'Choose a location outside bundled Winrift assets.' -Level WARNING; Wait-ForUser; return }
    if(Test-Path -LiteralPath $resolved) { Write-Log 'Choose a new file; the existing file is preserved.' -Level WARNING; Wait-ForUser; return }
    if($env:WINRIFT_DRY_RUN -eq '1') { Write-Log "[DRY-RUN] Save bundle $resolved and open UniGetUI"; Wait-ForUser; return }
    $bundle=@{export_version=3;packages=@($Packages|ForEach-Object{@{Id=$_.Id;Name=$_.Name;ManagerName='Winget';Source=$(if ($_.Source -eq 'msstore') { 'msstore' } else { 'winget' })}})}
    [IO.File]::WriteAllText($resolved,($bundle|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))
    $exe=Get-UniGetUIExe
    if(-not $exe) {
        $choice=Show-InteractiveMenu -Title 'UniGetUI' -Items @('Y › Install UniGetUI','N › Back')
        if($choice -eq 'Y') { $null=Install-WingetPackage 'Devolutions.UniGetUI' 'UniGetUI'; $exe=Get-UniGetUIExe }
    }
    if($exe) { Start-Process -FilePath $exe -ArgumentList ('--import-bundle "'+$resolved+'"'); Write-Log 'Bundle handed off to UniGetUI. Save your edits to your chosen file.' }
    else { Write-Log "Bundle saved: $resolved. UniGetUI was not opened." }
    Wait-ForUser
}

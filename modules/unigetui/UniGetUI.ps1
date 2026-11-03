. "$PSScriptRoot\..\..\scripts\Common.ps1"
Initialize-Logging -ModuleName unigetui

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

function Get-InstalledAndBrokenIds {
    $installed=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $broken=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    if(Get-Command winget -ErrorAction SilentlyContinue) {
        $output=& winget list --accept-source-agreements --disable-interactivity 2>&1
        foreach($line in $output) {
            if($line -match '^.+?\s{2,}([A-Za-z0-9][\w.-]*\.[A-Za-z0-9][\w.-]*|[A-Za-z0-9]{12,14})\s{2,}\S+') { $null=$installed.Add($Matches[1]) }
        }
    }
    # Unknown version is still installed. No forced reinstall is inferred.
    Write-Output -NoEnumerate $installed
    Write-Output -NoEnumerate $broken
}

function Get-UniGetUIExe {
    $local = "$env:LOCALAPPDATA\Programs\UniGetUI\UniGetUI.exe"
    if (Test-Path $local) { return $local }
    $cmd = Get-Command unigetui -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

. "$PSScriptRoot\Apps.Catalog.ps1"
if ($MyInvocation.InvocationName -ne '.') { Show-AppCategoryMenu }

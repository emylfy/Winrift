function Export-WinriftProfile {
    Clear-Host

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm'
    $profileDir = Join-Path ([Environment]::GetFolderPath('Desktop')) "winrift-profile_$timestamp"
    New-Item -Path $profileDir -ItemType Directory -Force | Out-Null

    $exportItems = @(
        "1 › App list (winget export)",
        "2 › Tweak desired state",
        "3 › Windows Terminal config",
        "4 › PowerShell profile",
        "5 › Oh My Posh theme",
        "6 › FastFetch config",
        "7 › GlazeWM config",
        "8 › VSCode settings",
        "9 › VSCode extensions"
    )
    $selected = Show-MultiSelect -Title "Export Profile" -Items $exportItems

    if ($selected.Count -eq 0) {
        Remove-Item $profileDir -Recurse -Force -ErrorAction SilentlyContinue
        return
    }

    $docsDir = [Environment]::GetFolderPath('MyDocuments')
    $editorNames = @("Code", "Cursor", "Windsurf", "VSCodium", "Trae")

    foreach ($key in $selected) {
        switch ($key) {
            "1" {
                if (Get-Command winget -ErrorAction SilentlyContinue) {
                    $outFile = Join-Path $profileDir "apps.json"
                    & winget export -o $outFile --accept-source-agreements 2>&1 | Out-Null
                    if (Test-Path $outFile) { Write-Log -Message "Exported app list" -Level SUCCESS }
                    else { Write-Log -Message "winget export failed" -Level WARNING }
                }
            }
            "2" {
                $ds = Join-Path $env:USERPROFILE "Winrift\tweaks\desired_state.json"
                if (Test-Path $ds) {
                    Copy-Item $ds (Join-Path $profileDir "desired_state.json")
                    Write-Log -Message "Exported desired state" -Level SUCCESS
                } else { Write-Log -Message "No desired state found" -Level SKIP }
            }
            "3" {
                $wt = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
                if (Test-Path $wt) {
                    Copy-Item $wt (Join-Path $profileDir "terminal.json")
                    Write-Log -Message "Exported Windows Terminal config" -Level SUCCESS
                } else { Write-Log -Message "Windows Terminal config not found" -Level SKIP }
            }
            "4" {
                $exported = $false
                foreach ($psDir in @("PowerShell", "WindowsPowerShell")) {
                    $ps = Join-Path $docsDir "$psDir\Microsoft.PowerShell_profile.ps1"
                    if (Test-Path $ps) {
                        Copy-Item $ps (Join-Path $profileDir "Microsoft.PowerShell_profile.ps1")
                        Write-Log -Message "Exported PowerShell profile ($psDir)" -Level SUCCESS
                        $exported = $true; break
                    }
                }
                if (-not $exported) { Write-Log -Message "PowerShell profile not found" -Level SKIP }
            }
            "5" {
                $omp = "$env:USERPROFILE\.config\ohmyposh\zen.toml"
                if (Test-Path $omp) {
                    Copy-Item $omp (Join-Path $profileDir "zen.toml")
                    Write-Log -Message "Exported Oh My Posh theme" -Level SUCCESS
                } else { Write-Log -Message "Oh My Posh theme not found" -Level SKIP }
            }
            "6" {
                $ff = "$env:USERPROFILE\.config\fastfetch\config.jsonc"
                if (Test-Path $ff) {
                    Copy-Item $ff (Join-Path $profileDir "fastfetch.jsonc")
                    Write-Log -Message "Exported FastFetch config" -Level SUCCESS
                } else { Write-Log -Message "FastFetch config not found" -Level SKIP }
            }
            "7" {
                $glz = "$env:USERPROFILE\.glzr\glazewm\config.yaml"
                if (Test-Path $glz) {
                    Copy-Item $glz (Join-Path $profileDir "glazewm.yaml")
                    Write-Log -Message "Exported GlazeWM config" -Level SUCCESS
                } else { Write-Log -Message "GlazeWM config not found" -Level SKIP }
            }
            "8" {
                foreach ($ed in $editorNames) {
                    $sp = "$env:USERPROFILE\AppData\Roaming\$ed\User\settings.json"
                    if (Test-Path $sp) {
                        Copy-Item $sp (Join-Path $profileDir "$ed-settings.json")
                        Write-Log -Message "Exported $ed settings" -Level SUCCESS
                        break
                    }
                }
            }
            "9" {
                foreach ($cmd in @("code", "cursor", "windsurf", "codium")) {
                    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
                        $extList = & $cmd --list-extensions 2>$null
                        if ($extList) {
                            $extList | Set-Content (Join-Path $profileDir "extensions.txt")
                            Write-Log -Message "Exported extensions via $cmd" -Level SUCCESS
                        }
                        break
                    }
                }
            }
        }
    }

    # Metadata
    @{
        exportedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        hostname   = $env:COMPUTERNAME
        osBuild    = (Get-CimInstance Win32_OperatingSystem).BuildNumber
        items      = $selected
    } | ConvertTo-Json | Set-Content (Join-Path $profileDir "profile.json")

    Write-Host ""
    Write-Log -Message "Profile exported to: $profileDir" -Level SUCCESS
    Wait-ForUser
}

function Import-WinriftProfile {
    Clear-Host

    Add-Type -AssemblyName System.Windows.Forms
    $dialog = [System.Windows.Forms.FolderBrowserDialog]::new()
    $dialog.Description = "Select a winrift-profile folder"
    $dialog.RootFolder = "Desktop"
    if ($dialog.ShowDialog() -ne "OK") { return }
    $profileDir = $dialog.SelectedPath

    $metaFile = Join-Path $profileDir "profile.json"
    if (-not (Test-Path $metaFile)) {
        Write-Log -Message "Not a valid Winrift profile (missing profile.json)" -Level ERROR
        Wait-ForUser
        return
    }

    $meta = Get-Content $metaFile -Raw | ConvertFrom-Json
    Write-Log -Message "Profile from $($meta.hostname) at $($meta.exportedAt)" -Level INFO

    $files = Get-ChildItem $profileDir -File | Where-Object { $_.Name -ne "profile.json" }
    if ($files.Count -eq 0) {
        Write-Log -Message "Profile is empty." -Level INFO
        Wait-ForUser
        return
    }

    $keyToFile = @{}
    $items = @()
    foreach ($f in $files) {
        $k = ($items.Count + 1).ToString()
        $items += "$k › $($f.Name)"
        $keyToFile[$k] = $f
    }
    $selected = Show-MultiSelect -Title "Import Profile" -Items $items -Defaults ([bool[]](@($true) * $items.Count))

    if ($selected.Count -eq 0) { return }

    $docsDir = [Environment]::GetFolderPath('MyDocuments')

    foreach ($key in $selected) {
        $file = $keyToFile[$key]
        if ($null -eq $file) { continue }
        $src = $file.FullName

        switch -Wildcard ($file.Name) {
            "apps.json" {
                if (Get-Command winget -ErrorAction SilentlyContinue) {
                    & winget import -i $src --accept-package-agreements --accept-source-agreements --ignore-unavailable 2>&1 | Out-Host
                    Write-Log -Message "Imported app list" -Level SUCCESS
                }
            }
            "desired_state.json" {
                $dst = Join-Path $env:USERPROFILE "Winrift\tweaks\desired_state.json"
                New-Item -Path (Split-Path $dst) -ItemType Directory -Force | Out-Null
                Copy-Item $src $dst -Force
                Write-Log -Message "Imported desired state" -Level SUCCESS
            }
            "terminal.json" {
                $dst = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
                if (Test-Path (Split-Path $dst)) {
                    Copy-Item $src $dst -Force
                    Write-Log -Message "Imported Windows Terminal config" -Level SUCCESS
                }
            }
            "Microsoft.PowerShell_profile.ps1" {
                Copy-Item $src (Join-Path $docsDir "WindowsPowerShell\Microsoft.PowerShell_profile.ps1") -Force
                Write-Log -Message "Imported PowerShell profile" -Level SUCCESS
            }
            "zen.toml" {
                $dst = "$env:USERPROFILE\.config\ohmyposh\zen.toml"
                New-Item -Path (Split-Path $dst) -ItemType Directory -Force | Out-Null
                Copy-Item $src $dst -Force
                Write-Log -Message "Imported Oh My Posh theme" -Level SUCCESS
            }
            "fastfetch.jsonc" {
                $dst = "$env:USERPROFILE\.config\fastfetch\config.jsonc"
                New-Item -Path (Split-Path $dst) -ItemType Directory -Force | Out-Null
                Copy-Item $src $dst -Force
                Write-Log -Message "Imported FastFetch config" -Level SUCCESS
            }
            "glazewm.yaml" {
                $dst = "$env:USERPROFILE\.glzr\glazewm\config.yaml"
                New-Item -Path (Split-Path $dst) -ItemType Directory -Force | Out-Null
                Copy-Item $src $dst -Force
                Write-Log -Message "Imported GlazeWM config" -Level SUCCESS
            }
            "*-settings.json" {
                $edName = $file.Name -replace '-settings\.json$', ''
                $dst = "$env:USERPROFILE\AppData\Roaming\$edName\User\settings.json"
                if (Test-Path (Split-Path $dst)) {
                    Copy-Item $src $dst -Force
                    Write-Log -Message "Imported $edName settings" -Level SUCCESS
                }
            }
            "extensions.txt" {
                foreach ($cmd in @("code", "cursor", "windsurf", "codium")) {
                    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
                        Get-Content $src | Where-Object { $_.Trim() } | ForEach-Object {
                            & $cmd --install-extension $_ --force 2>&1 | Out-Null
                        }
                        Write-Log -Message "Imported extensions via $cmd" -Level SUCCESS
                        break
                    }
                }
            }
        }
    }
    Wait-ForUser
}

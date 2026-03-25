$scriptRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    . "$scriptRoot\scripts\Common.ps1"
}
Initialize-Logging -ModuleName "isobuilder"

$OSCDIMG_URL = "https://msdl.microsoft.com/download/symbols/oscdimg.exe/3D44737265000/oscdimg.exe"
$ADK_PAGE = "https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install"

function Get-OscdimgPath {
    # 1. Check Windows ADK installation
    if ([Environment]::Is64BitOperatingSystem) { $arch = "amd64" } else { $arch = "x86" }
    $adkPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\$arch\Oscdimg\oscdimg.exe"
    if (Test-Path $adkPath) {
        Write-Log -Message "Using oscdimg.exe from system ADK." -Level INFO -LogFile $script:LogFile
        return $adkPath
    }

    # 2. Check local copy next to this script
    $localPath = Join-Path $PSScriptRoot "oscdimg.exe"
    if (Test-Path $localPath) {
        Write-Log -Message "Using local oscdimg.exe." -Level INFO -LogFile $script:LogFile
        return $localPath
    }

    # 3. Not found — ask user how to proceed
    Show-MenuBox -Title "oscdimg.exe not found" -Items @(
        "oscdimg.exe is required to build bootable ISOs.",
        "It is a Microsoft tool included in the Windows ADK.",
        "",
        "Source: msdl.microsoft.com (Microsoft's official Symbol Server)",
        "Same source used by tiny11maker and Windows ADK tools.",
        "",
        "Y › Download from Microsoft",
        "N › Cancel",
        "A › Open ADK download page (install manually)"
    )

    while ($true) {
        $response = Read-Host "Your choice"
        switch ($response.ToUpper()) {
            "Y" { break }
            "N" { return $null }
            "A" {
                Start-Process $ADK_PAGE
                Write-Log -Message "Opened ADK download page. Install ADK, then re-run ISO Builder." -Level INFO -LogFile $script:LogFile
                return $null
            }
            default { Write-Host "  Please enter Y, N, or A." }
        }
        break
    }

    # Download
    Write-Log -Message "Downloading from: $OSCDIMG_URL" -Level INFO -LogFile $script:LogFile
    try {
        Invoke-WebRequest -Uri $OSCDIMG_URL -OutFile $localPath -UseBasicParsing -ErrorAction Stop
        if (-not (Test-Path $localPath)) {
            throw "File not found after download"
        }
        $sizeMB = [math]::Round((Get-Item $localPath).Length / 1KB)
        Write-Log -Message "Downloaded oscdimg.exe (${sizeMB} KB)" -Level SUCCESS -LogFile $script:LogFile
    }
    catch {
        Write-Log -Message "Download failed: $($_.Exception.Message)" -Level ERROR -LogFile $script:LogFile
        return $null
    }

    return $localPath
}

function Select-ISOFile {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Select Windows 11 ISO"
    $dialog.Filter = "ISO files (*.iso)|*.iso"
    $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")

    if ($dialog.ShowDialog() -eq "OK") {
        return $dialog.FileName
    }
    return $null
}

function Build-WinriftISO {
    $oscdimg = Get-OscdimgPath
    if (-not $oscdimg) {
        Wait-ForUser
        return
    }

    # Pick ISO
    Write-Log -Message "Select a Windows 11 ISO file..." -Level INFO -LogFile $script:LogFile
    $isoPath = Select-ISOFile
    if (-not $isoPath) {
        Write-Log -Message "No ISO selected." -Level WARNING -LogFile $script:LogFile
        Wait-ForUser
        return
    }
    Write-Log -Message "Selected: $isoPath" -Level INFO -LogFile $script:LogFile

    # Prepare scratch directory
    $scratchDir = Join-Path $env:TEMP "winrift-iso"
    if (Test-Path $scratchDir) {
        Remove-Item $scratchDir -Recurse -Force | Out-Null
    }
    New-Item -ItemType Directory -Path $scratchDir -Force | Out-Null

    $mountResult = $null
    try {
        # Mount ISO
        Write-Log -Message "Mounting ISO..." -Level INFO -LogFile $script:LogFile
        $mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru
        $driveLetter = ($mountResult | Get-Volume | Select-Object -First 1).DriveLetter

        if (-not $driveLetter) {
            Write-Log -Message "Failed to mount ISO." -Level ERROR -LogFile $script:LogFile
            Wait-ForUser
            return
        }
        $drivePath = "${driveLetter}:\"
        Write-Log -Message "Mounted at $drivePath" -Level SUCCESS -LogFile $script:LogFile

        # Copy ISO contents
        Write-Log -Message "Copying ISO contents (this may take a few minutes)..." -Level INFO -LogFile $script:LogFile
        Copy-Item -Path "$drivePath*" -Destination $scratchDir -Recurse -Force | Out-Null
        Write-Log -Message "Copy complete." -Level SUCCESS -LogFile $script:LogFile

        # Choose autounattend.xml
        $defaultXml = Join-Path $scriptRoot "docs\autounattend.xml"

        Show-MenuBox -Title "Answer File (autounattend.xml)" -Items @(
            "This file automates Windows 11 installation:",
            "  - Removes 25 bloatware apps (Cortana, Teams, News...)",
            "  - Disables telemetry, Copilot, and OneDrive auto-install",
            "  - Cleans taskbar, shows file extensions, opens to This PC",
            "  - Bypasses TPM/SecureBoot/RAM checks",
            "  - Creates Winrift desktop shortcut",
            "",
            "1 › Use Winrift default answer file",
            "2 › Use your own autounattend.xml",
            "3 › Cancel"
        )

        $xmlSource = $null
        while ($true) {
            $xmlChoice = Read-Host "Your choice"
            switch ($xmlChoice) {
                "1" {
                    if (-not (Test-Path $defaultXml)) {
                        Write-Log -Message "Default autounattend.xml not found at $defaultXml" -Level ERROR -LogFile $script:LogFile
                        Wait-ForUser
                        return
                    }
                    $xmlSource = $defaultXml
                    Write-Log -Message "Using Winrift default: $defaultXml" -Level INFO -LogFile $script:LogFile
                    break
                }
                "2" {
                    Add-Type -AssemblyName System.Windows.Forms
                    $xmlDialog = New-Object System.Windows.Forms.OpenFileDialog
                    $xmlDialog.Title = "Select your autounattend.xml"
                    $xmlDialog.Filter = "XML files (*.xml)|*.xml"
                    if ($xmlDialog.ShowDialog() -eq "OK") {
                        $xmlSource = $xmlDialog.FileName
                        Write-Log -Message "Using custom: $xmlSource" -Level INFO -LogFile $script:LogFile
                    } else {
                        Write-Log -Message "No file selected." -Level WARNING -LogFile $script:LogFile
                        Wait-ForUser
                        return
                    }
                    break
                }
                "3" { return }
                default { Write-Host "  Please enter 1, 2, or 3."; continue }
            }
            break
        }

        Copy-Item -Path $xmlSource -Destination "$scratchDir\autounattend.xml" -Force | Out-Null
        Write-Log -Message "Embedded autounattend.xml into ISO root." -Level SUCCESS -LogFile $script:LogFile

        # Build ISO
        $outputDir = [Environment]::GetFolderPath("Desktop")
        $outputPath = Join-Path $outputDir "winrift-win11.iso"

        # Avoid overwriting existing file
        $counter = 1
        while (Test-Path $outputPath) {
            $outputPath = Join-Path $outputDir "winrift-win11-$counter.iso"
            $counter++
        }

        Write-Log -Message "Building ISO (this may take several minutes)..." -Level INFO -LogFile $script:LogFile

        $bootBios = "$scratchDir\boot\etfsboot.com"
        $bootEfi = "$scratchDir\efi\microsoft\boot\efisys.bin"
        & $oscdimg -m -o -u2 -udfver102 -bootdata:"2#p0,e,b`"$bootBios`"#pEF,e,b`"$bootEfi`"" "$scratchDir" "$outputPath"

        if ($LASTEXITCODE -eq 0) {
            $sizeMB = [math]::Round((Get-Item $outputPath).Length / 1MB)
            Write-Log -Message "ISO created: $outputPath ($sizeMB MB)" -Level SUCCESS -LogFile $script:LogFile
        }
        else {
            Write-Log -Message "oscdimg failed with exit code $LASTEXITCODE." -Level ERROR -LogFile $script:LogFile
        }
    }
    catch {
        Write-Log -Message "Error: $($_.Exception.Message)" -Level ERROR -LogFile $script:LogFile
    }
    finally {
        # Unmount ISO
        if ($mountResult) {
            Dismount-DiskImage -ImagePath $isoPath -ErrorAction SilentlyContinue | Out-Null
            Write-Log -Message "ISO unmounted." -Level INFO -LogFile $script:LogFile
        }

        # Cleanup scratch directory
        if (Test-Path $scratchDir) {
            Write-Log -Message "Cleaning up temporary files..." -Level INFO -LogFile $script:LogFile
            Remove-Item $scratchDir -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }

    Wait-ForUser
}

# Menu
Clear-Host
Invoke-MenuLoop -Title "Winrift ISO Builder" -Items @(
    "1 › Build ISO - embed autounattend.xml into Windows 11 ISO",
    "2 › Back"
) -Actions @{
    "1" = { Build-WinriftISO }
} -ExitKey "2"

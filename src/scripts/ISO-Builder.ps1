function Show-Header {
    param($title)
    Write-Host "`n" -NoNewline
    Write-Host " $title " -BackgroundColor DarkBlue -ForegroundColor White
    Write-Host ""
}

function Show-Section {
    param($title)
    Write-Host "`n$title" -ForegroundColor Cyan
}

function Show-Status {
    param($message, $type)
    $symbol = switch ($type) {
        "success" { "✓"; break }
        "error" { "✗"; break }
        "warning" { "⚠"; break }
        default { "ℹ "; break }
    }
    
    $color = switch ($type) {
        "success" { "Green"; break }
        "error" { "Red"; break }
        "warning" { "Yellow"; break }
        default { "Cyan"; break }
    }
    
    Write-Host "[$symbol] " -NoNewline -ForegroundColor $color
    Write-Host $message
}

try {
    Show-Header "Windows ISO Builder by @emylfy"

    # ISO Input Handling
    Show-Section "STEP 1: ISO FILE CONFIGURATION"
    $isoPath = Read-Host "Enter the path to the ISO file"
    if (-not (Test-Path $isoPath)) {
        Show-Status "ISO file not found." "error"
        pause
        exit 1
    }
    Show-Status "Valid ISO file confirmed" "success"

    # Workspace Setup
    Show-Section "STEP 2: TEMPORARY WORKSPACE SETUP"
    $extractDir = Join-Path $env:USERPROFILE "Documents\ISO_Workspace"
    try {
        if (Test-Path $extractDir) {
            Remove-Item -Path $extractDir -Recurse -Force -ErrorAction Stop
            Show-Status "Cleaned existing workspace" "success"
        }
        New-Item -ItemType Directory -Path $extractDir -Force -ErrorAction Stop | Out-Null
        icacls $extractDir /grant "*S-1-1-0:(OI)(CI)F" /T | Out-Null
        Show-Status "Created secure workspace directory" "success"
    }
    catch {
        Show-Status "Workspace creation failed: $_" "error"
        Show-Status "Try running the script as Administrator" "warning"
        pause
        exit 1
    }

    # ISO Processing
    Show-Section "STEP 3: ISO EXTRACTION"
    try {
        $diskImage = Mount-DiskImage -ImagePath $isoPath -PassThru -ErrorAction Stop

        $retryCount = 0
        do {
            $driveLetter = (Get-Volume -DiskImage $diskImage -ErrorAction SilentlyContinue).DriveLetter
            if ($driveLetter) { break }
            Start-Sleep -Seconds 1
            $retryCount++
        } while ($retryCount -lt 5)

        if (-not $driveLetter) {
            throw "Failed to get mounted drive letter after 5 attempts"
        }
        
        $sourcePath = "${driveLetter}:\"
        Show-Status "Mounted ISO at $sourcePath" "success"

        Copy-Item -Path "$sourcePath*" -Destination $extractDir -Recurse -Force
        Show-Status "Copied ISO contents to workspace" "success"

        Dismount-DiskImage -ImagePath $isoPath | Out-Null
        Show-Status "Unmounted original ISO" "success"
    }
    catch {
        Show-Status "ISO processing error: $_" "error"
        pause
        exit 1
    }

    # XML Configuration
    Show-Section "STEP 4: ANSWER FILE SETUP"
    Write-Host "Enter the path to the XML file" -ForegroundColor DarkCyan
    Write-Host "[Press Enter to use pre-made from github.com/emylfy/simplify11]" -ForegroundColor DarkGray
    $xmlPath = Read-Host " "

    try {
        if ([string]::IsNullOrWhiteSpace($xmlPath)) {
            Show-Status "Downloading pre-made autounattend.xml..." "info"
            
            try {
                Invoke-WebRequest -Uri "https://raw.githubusercontent.com/emylfy/simplify11/main/src/docs/autounattend.xml" -OutFile "autounattend.xml" -ErrorAction Stop
                Move-Item -Path "autounattend.xml" -Destination $extractDir -Force
                Show-Status "XML downloaded successfully" "success"
            }
            catch {
                Show-Status "Download failed: $($_.Exception.Message)" "error"
                
                Write-Host "`nRecovery Options:" -ForegroundColor Yellow
                Write-Host "1. Open browser to download XML"
                Write-Host "2. Enter custom XML path"
                Write-Host "3. Exit"
                
                switch (Read-Host "Selection (1-3)") {
                    1 {
                        Start-Process "https://github.com/emylfy/simplify11/blob/main/src/docs/autounattend.xml"
                        Write-Host "Save the XML to directory: $extractDir" -ForegroundColor Cyan
                        do {
                            Start-Sleep -Seconds 2
                        } until (Test-Path (Join-Path $extractDir "autounattend.xml"))
                        Show-Status "Manual XML copy verified" "success"
                    }
                    2 { 
                        $xmlPath = Read-Host "Enter full XML path" 
                        Copy-Item -Path $xmlPath -Destination (Join-Path $extractDir "autounattend.xml") -Force
                        Show-Status "Custom XML copied successfully" "success"
                    }
                    3 { exit }
                    default { throw "Invalid selection" }
                }
            }
        }
        else {
            if (-not (Test-Path $xmlPath)) {
                throw "Custom XML file not found at: $xmlPath"
            }
            Copy-Item -Path $xmlPath -Destination (Join-Path $extractDir "autounattend.xml") -Force
            Show-Status "Custom XML applied successfully" "success"
        }

        $finalPath = Join-Path $extractDir "autounattend.xml"
        if (-not (Test-Path $finalPath)) {
            throw "XML file creation failed"
        }
        
        Set-ItemProperty -Path $finalPath -Name IsReadOnly -Value $false
    }
    catch {
        Show-Status "XML configuration error: $($_.Exception.Message)" "error"
        if (Test-Path $finalPath) { Remove-Item $finalPath -Force }
        pause
        exit 1
    }

    # Output Configuration
    Show-Section "STEP 5: OUTPUT CONFIGURATION"
    $defaultFullPath = Join-Path $env:USERPROFILE "Documents\custom.iso"
    Write-Host "Default save location: $defaultFullPath" -ForegroundColor Cyan
    $newIsoPath = Read-Host "Press Enter to use default path or enter custom full path"

    if ([string]::IsNullOrWhiteSpace($newIsoPath)) {
        $newIsoPath = $defaultFullPath
    }
    $newIsoPath = [System.IO.Path]::ChangeExtension($newIsoPath, "iso")

    if (Test-Path $newIsoPath) {
        $confirmation = Read-Host "File exists! Overwrite? (Y/N)"
        if ($confirmation -ne "Y") {
            Show-Status "Operation canceled." "warning"
            pause
            exit
        }
        Remove-Item $newIsoPath -Force -ErrorAction Stop
        Show-Status "Removed existing ISO file" "success"
    }

    # OSCDIMG Handling
    Show-Section "STEP 6: BUILD TOOLS SETUP"
    $oscdimg = $null
    if (-not (Get-Command oscdimg -ErrorAction SilentlyContinue)) {
        Write-Host "Download oscdimg.exe from:" -ForegroundColor Yellow
        Write-Host "https://github.com/ChrisTitusTech/winutil/releases/oscdimg.exe" -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue"

        $oscdimgPath = Join-Path $env:USERPROFILE "Downloads\oscdimg.exe"
        if (Test-Path $oscdimgPath) {
            $oscdimg = $oscdimgPath
            Show-Status "Found oscdimg.exe in Downloads" "success"
        }
        else {
            do {
                $oscdimg = Read-Host "Enter full path to oscdimg.exe"
            } while (-not (Test-Path $oscdimg))
            Show-Status "OSCDIMG path validated" "success"
        }
    }
    else {
        $oscdimg = "oscdimg"
        Show-Status "Using system OSCDIMG" "success"
    }

    # ISO Building
    Show-Section "STEP 7: ISO CONSTRUCTION"
    try {
        $bootFile = @("boot\etfsboot.com", "efi\microsoft\boot\efisys.bin") | 
            Where-Object { Test-Path (Join-Path $extractDir $_) } | 
            Select-Object -First 1
        if (-not $bootFile) {
            throw "Boot file not found in extracted ISO"
        }
        $bootPath = Join-Path $extractDir $bootFile
        Show-Status "Boot file located: $bootFile" "success"

        Write-Host "Building ISO with: $oscdimg" -ForegroundColor Cyan
        & "$oscdimg" -m -n -b"$bootPath" -lWin11 "$extractDir" "$newIsoPath"
        
        if ($LASTEXITCODE -ne 0) {
            throw "OSCDIMG failed with code $LASTEXITCODE"
        }
        Write-Host "`nISO successfully created: " -NoNewline -ForegroundColor Green
        Write-Host $newIsoPath -ForegroundColor White
    }
    catch {
        Show-Status "ISO creation failed: $_" "error"
        pause
        exit 1
    }
    finally {
        Remove-Item -Path $extractDir -Recurse -Force -ErrorAction SilentlyContinue
        Show-Status "Cleaned temporary workspace" "success"
    }

    pause
}
catch {
    Show-Status "Unexpected error: $_" "error"
    pause
    exit 1
}
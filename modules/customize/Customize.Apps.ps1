function Invoke-Rectify11 {
    Clear-Host
    Invoke-Tool "rectify11"
    Wait-ForUser
}

function Install-SpotX {
    Clear-Host
    Invoke-Tool "spotx"
    Wait-ForUser
}

function Install-Spicetify {
    Clear-Host
    Invoke-Tool "spicetify"
    Wait-ForUser
}

function Install-SteamMillennium {
    Clear-Host
    $result = Invoke-Tool "steam-millennium" -Wait -ErrorMessage "Failed to install Steam Millennium. Make sure Steam is installed"
    if (-not $result) {
        Wait-ForUser
        return
    }

    Clear-Host
    Show-MenuBox -Title "Space Theme Installation" -Items @(
        "Would you like to install Space Theme for Steam?",
        "[Y] Yes   [N] No"
    )
    $installChoice = Read-Host "Install Space Theme? (Y/N)"

    if ($installChoice -eq 'y') {
        Invoke-Tool "spacetheme"
    }
    Wait-ForUser
}

function Install-MacOSCursor {
    Clear-Host

    $tool = Get-ToolConfig "macos-cursor"
    if (-not $tool) {
        Write-Log -Message "macOS Cursor tool config not found." -Level ERROR
        Wait-ForUser
        return
    }

    $confirmed = Confirm-ExternalTool -Tool $tool
    if (-not $confirmed) {
        Write-Log -Message "User cancelled macOS Cursor download." -Level INFO
        return
    }

    $zipPath = Join-Path $env:TEMP $tool.filename
    $extractPath = Join-Path $env:TEMP "macos-cursor"

    try {
        # Download
        Write-Log -Message "Downloading $($tool.name) from $($tool.url)..." -Level INFO
        Invoke-WebRequest -Uri $tool.url -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        if (-not (Test-Path $zipPath)) {
            throw "Download failed: file not found after download"
        }
        if ($tool.sha256) {
            $actualHash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash
            if ($actualHash -ne $tool.sha256) {
                Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
                throw "Hash mismatch! Expected: $($tool.sha256), Got: $actualHash"
            }
            Write-Log -Message "Hash verified." -Level SUCCESS
        }

        # Extract
        Write-Log -Message "Extracting..." -Level INFO
        if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

        # Find available cursor themes (folders with .inf files)
        $infFiles = Get-ChildItem -Path $extractPath -Filter "*.inf" -Recurse
        if ($infFiles.Count -eq 0) {
            Write-Log -Message "No cursor .inf files found in archive." -Level ERROR
            Wait-ForUser
            return
        }

        # Let user pick theme
        $themes = $infFiles | ForEach-Object { [PSCustomObject]@{ Name = $_.Directory.Name; InfPath = $_.FullName } }

        if ($themes.Count -eq 1) {
            $selectedInf = $themes[0].InfPath
            Write-Log -Message "Found theme: $($themes[0].Name)" -Level INFO
        } else {
            $menuItems = @()
            for ($i = 0; $i -lt $themes.Count; $i++) {
                $menuItems += "[$($i + 1)] $($themes[$i].Name)"
            }
            $menuItems += "---"
            $menuItems += "[$($themes.Count + 1)] Cancel"

            Show-MenuBox -Title "Select cursor theme" -Items $menuItems
            $choice = Read-Host ">"

            $idx = 0
            if ([int]::TryParse($choice, [ref]$idx) -and $idx -ge 1 -and $idx -le $themes.Count) {
                $selectedInf = $themes[$idx - 1].InfPath
            } else {
                return
            }
        }

        # Parse .inf to extract cursor registry mappings
        Write-Log -Message "Installing cursor theme..." -Level INFO

        $cursorDir = Split-Path $selectedInf -Parent
        $cursorRegPath = "HKCU:\Control Panel\Cursors"
        $infContent = Get-Content $selectedInf -Raw

        # Copy cursor files to a persistent user location — validate theme name to prevent path traversal
        $themeName = (Split-Path $cursorDir -Leaf)
        if ($themeName -match '(\.\.|[\\\/])') {
            Write-Log -Message "Invalid theme directory name: $themeName" -Level ERROR
            Wait-ForUser
            return
        }
        $persistDir = Join-Path "$env:USERPROFILE\.cursors" $themeName
        if (-not (Test-Path $persistDir)) {
            New-Item -Path $persistDir -ItemType Directory -Force | Out-Null
        }
        Copy-Item -Path "$cursorDir\*" -Destination $persistDir -Recurse -Force
        Write-Log -Message "Cursor files copied to $persistDir" -Level SUCCESS

        # Parse .inf for HKCU,"Control Panel\Cursors","<Name>",,"%10%\...\<file>" lines
        $cursorMap = @{}
        $infContent -split "`r?`n" | ForEach-Object {
            if ($_ -match 'HKCU,\s*"Control Panel\\Cursors",\s*"([^"]+)",,\s*".*\\([^"\\]+)"') {
                $regName = $Matches[1]
                $fileName = $Matches[2]
                $cursorMap[$regName] = $fileName
            }
        }

        # Also check for the scheme name line: HKCU,"Control Panel\Cursors",,"<name>"
        $schemeName = $themeName
        if ($infContent -match 'HKCU,\s*"Control Panel\\Cursors",,\s*"([^"]+)"') {
            $schemeName = $Matches[1]
        }

        if ($cursorMap.Count -eq 0) {
            Write-Log -Message "Could not parse cursor mappings from .inf file. Trying file scan..." -Level WARNING
            # Fallback: scan for .cur/.ani files and use filename-based guessing
            $curFiles = Get-ChildItem -Path $persistDir -Include "*.cur","*.ani" -Recurse
            Write-Log -Message "Found $($curFiles.Count) cursor files in $persistDir" -Level INFO

            # Common filename mappings for apple_cursor
            $fallbackMap = @{
                "left_ptr"     = "Arrow";       "help"       = "Help"
                "wait"         = "Wait";         "progress"   = "AppStarting"
                "crosshair"    = "Crosshair";    "cross"      = "Crosshair"
                "text"         = "IBeam";        "xterm"      = "IBeam"
                "pencil"       = "NWPen";        "handwriting"= "NWPen"
                "circle"       = "No";           "not-allowed"= "No";   "forbidden" = "No"
                "size_ver"     = "SizeNS";       "ns-resize"  = "SizeNS"
                "size_hor"     = "SizeWE";       "ew-resize"  = "SizeWE"
                "size_fdiag"   = "SizeNWSE";     "nwse-resize"= "SizeNWSE"
                "size_bdiag"   = "SizeNESW";     "nesw-resize"= "SizeNESW"
                "size_all"     = "SizeAll";      "all-scroll" = "SizeAll"; "move" = "SizeAll"
                "up_arrow"     = "UpArrow";      "center_ptr" = "UpArrow"
                "hand"         = "Hand";         "pointer"    = "Hand";  "link" = "Hand"
            }

            foreach ($file in $curFiles) {
                $baseName = $file.BaseName.ToLower()
                if ($fallbackMap.ContainsKey($baseName)) {
                    $cursorMap[$fallbackMap[$baseName]] = $file.Name
                }
            }
        }

        if ($cursorMap.Count -eq 0) {
            Write-Log -Message "No cursor mappings found. Installation cannot proceed." -Level ERROR
            Wait-ForUser
            return
        }

        Write-Log -Message "Applying $($cursorMap.Count) cursor mappings..." -Level INFO

        # Set registry values for each cursor
        $applied = 0
        foreach ($regName in $cursorMap.Keys) {
            $curFile = Join-Path $persistDir $cursorMap[$regName]
            if (Test-Path $curFile) {
                Set-ItemProperty -Path $cursorRegPath -Name $regName -Value $curFile -Force
                $applied++
            }
        }

        # Set the scheme name
        Set-ItemProperty -Path $cursorRegPath -Name "(Default)" -Value $schemeName -Force

        Write-Log -Message "Set $applied cursor registry entries." -Level SUCCESS

        # Notify the system of cursor change
        if (-not ('CursorHelper' -as [type])) {
            Add-Type -TypeDefinition @"
                using System;
                using System.Runtime.InteropServices;
                public class CursorHelper {
                    [DllImport("user32.dll", SetLastError = true)]
                    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, string pvParam, uint fWinIni);
                }
"@
        }
        # SPI_SETCURSORS = 0x0057, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE = 0x03
        [CursorHelper]::SystemParametersInfo(0x0057, 0, $null, 0x03) | Out-Null

        Write-Log -Message "macOS cursor applied successfully!" -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to apply cursor: $($_.Exception.Message)" -Level ERROR
    } finally {
        # Cleanup temp files regardless of success or failure
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    Wait-ForUser
}


function Get-ToolConfig {
    param([string]$ToolId)
    # $PSScriptRoot always resolves to the directory of Common.Tools.ps1 (scripts/),
    # regardless of the caller's working directory, so "..\config\tools.json" is safe.
    $toolsFile = Join-Path $PSScriptRoot "..\config\tools.json"
    if (-not (Test-Path $toolsFile)) {
        Write-Log -Message "tools.json not found at $toolsFile" -Level ERROR
        return $null
    }
    $config = Get-Content $toolsFile -Raw | ConvertFrom-Json
    return $config.tools | Where-Object { $_.id -eq $ToolId }
}

function Invoke-SecureScript {
    param(
        [string]$Url,
        [string]$ToolName = "script",
        [string]$ExpectedHash = ""
    )

    $scriptContent = Invoke-WithSpinner -Message "Downloading $ToolName" -ScriptBlock {
        param($u)
        Invoke-RestMethod -Uri $u -TimeoutSec 60 -ErrorAction Stop
    } -ArgumentList $Url

    if ($ExpectedHash -ne "") {
        $stream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($scriptContent))
        $actualHash = (Get-FileHash -InputStream $stream -Algorithm SHA256).Hash
        $stream.Dispose()
        if ($actualHash -ne $ExpectedHash) {
            Write-Log -Message "Hash mismatch for $ToolName! Expected: $ExpectedHash, Got: $actualHash" -Level ERROR
            throw "Hash verification failed for $ToolName. The script may have been tampered with or updated."
        }
        Write-Log -Message "Hash verified for $ToolName" -Level SUCCESS
    }

    $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "winrift_irm_$([guid]::NewGuid().ToString('N').Substring(0,8)).ps1"
    try {
        Set-Content -Path $tempFile -Value $scriptContent -Encoding UTF8
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$tempFile`"" -Wait
    } finally {
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-SecureDownload {
    param(
        [string]$Url,
        [string]$OutFile,
        [string]$ToolName = "file",
        [string]$ExpectedHash = "",
        [int]$TimeoutSec = 60
    )

    Invoke-WithSpinner -Message "Downloading $ToolName" -ScriptBlock {
        param($u, $o, $t)
        Invoke-WebRequest -Uri $u -OutFile $o -TimeoutSec $t -ErrorAction Stop
    } -ArgumentList $Url, $OutFile, $TimeoutSec

    if (-not (Test-Path $OutFile)) {
        throw "Download failed: $OutFile not found after download"
    }

    if ($ExpectedHash -ne "") {
        $actualHash = (Get-FileHash -Path $OutFile -Algorithm SHA256).Hash
        if ($actualHash -ne $ExpectedHash) {
            Write-Log -Message "Hash mismatch for $ToolName! Expected: $ExpectedHash, Got: $actualHash" -Level WARNING
            Write-Log -Message "The downloaded file may have been tampered with or updated." -Level WARNING
            Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
            throw "Hash verification failed for $ToolName"
        }
        Write-Log -Message "Hash verified for $ToolName" -Level SUCCESS
    }
}

function Confirm-ExternalTool {
    param(
        [Parameter(Mandatory)][psobject]$Tool
    )

    while ($true) {
        $items = @(
            "This tool will fetch and run a script from the web.",
            "Tool:   $($Tool.name)",
            "URL:    $($Tool.url)"
        )
        if ($Tool.docs) { $items += "Source: $($Tool.docs)" }
        $items += "---"
        $items += "Y › Run"
        $items += "N › Cancel"
        if ($Tool.docs) { $items += "R › Open source in browser" }

        $response = Show-InteractiveMenu -Title "External script execution" -Items $items -HideKeys
        switch ($response) {
            "Y" { return $true }
            "R" {
                if ($Tool.docs) {
                    Start-Process $Tool.docs
                    Write-Host "$Green  Opened project source in browser.$Reset"
                    Start-Sleep -Milliseconds 500
                }
            }
            default { return $false }
        }
    }
}

function Invoke-Tool {
    param(
        [Parameter(Mandatory)][string]$ToolId,
        [string]$SuccessMessage,
        [string]$ErrorMessage,
        [scriptblock]$OnSuccess,
        [scriptblock]$PreRun,
        [switch]$Wait,
        [switch]$SkipConfirm
    )

    $tool = Get-ToolConfig $ToolId
    if (-not $tool) {
        Write-Log -Message "Tool '$ToolId' not found in tools.json" -Level ERROR
        return $false
    }

    $effectiveType = $tool.type
    if ($tool.interactive -eq $true -and $effectiveType -eq "irm") { $effectiveType = "irm-interactive" }

    if ($effectiveType -in @("irm", "irm-interactive", "download") -and -not $SkipConfirm) {
        $confirmed = Confirm-ExternalTool -Tool $tool
        if (-not $confirmed) {
            Write-Log -Message "User cancelled $($tool.name) launch." -Level INFO
            return $false
        }
    }

    if ($PreRun) { & $PreRun }

    try {
        $hash = $tool.sha256 ?? ""
        switch ($effectiveType) {
            "irm" {
                Invoke-SecureScript -Url $tool.url -ToolName $tool.name -ExpectedHash $hash
            }
            "irm-interactive" {
                $tempScript = Join-Path $env:TEMP "$($tool.id)_$([guid]::NewGuid().ToString('N').Substring(0,8)).ps1"
                try {
                    Write-Log -Message "Downloading $($tool.name)..." -Level INFO
                    Invoke-WebRequest -Uri $tool.url -OutFile $tempScript -TimeoutSec 60 -ErrorAction Stop
                    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" -Wait
                } finally {
                    Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
                }
            }
            "download" {
                $downloadPath = Join-Path $env:TEMP $tool.filename
                Invoke-SecureDownload -Url $tool.url -OutFile $downloadPath -ToolName $tool.name -ExpectedHash $hash
                if ($OnSuccess) {
                    & $OnSuccess $downloadPath | Out-Host
                } else {
                    $startArgs = @{ FilePath = $downloadPath }
                    if ($Wait) { $startArgs.Wait = $true }
                    Start-Process @startArgs
                }
            }
            "browser" {
                Start-Process $tool.url
            }
            default {
                Write-Log -Message "Unknown tool type: $($tool.type)" -Level ERROR
                return $false
            }
        }

        if ($tool.type -ne "browser") {
            $msg = $SuccessMessage ? $SuccessMessage : "$($tool.name) completed successfully."
            Write-Log -Message $msg -Level SUCCESS
        }
        if ($OnSuccess -and $tool.type -ne "download") {
            & $OnSuccess | Out-Host
        }
        return $true
    } catch {
        $msg = $ErrorMessage ? $ErrorMessage : "Failed to run $($tool.name)"
        Write-Log -Message "${msg}: $($_.Exception.Message)" -Level ERROR

        # Browser fallback when network/download fails (timeout, DNS, blocked
        # domain, hash mismatch, etc.). Prefers $tool.fallbackUrl if defined,
        # otherwise opens $tool.docs (the project's homepage) so the user can
        # at least find the tool manually.
        $fallbackUrl = $null
        if ($tool.fallbackUrl) {
            $fallbackUrl = $tool.fallbackUrl
        } elseif ($tool.docs) {
            $fallbackUrl = $tool.docs
        }
        if ($fallbackUrl) {
            Write-Log -Message "Opening $fallbackUrl in browser as fallback..." -Level INFO
            try { Start-Process $fallbackUrl } catch { $null = $_ }
        }
        return $false
    }
}

function Assert-WingetAvailable {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Log -Message "winget is not installed. Attempting to install..." -Level WARNING
        try {
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Write-Log -Message "winget installed successfully." -Level SUCCESS
                return $true
            }
        } catch {
            Write-Log -Message "Auto-install failed: $($_.Exception.Message)" -Level WARNING
        }
        Write-Log -Message "Opening Microsoft Store to install App Installer manually..." -Level INFO
        Start-Process "ms-windows-store://pdp?productid=9NBLGGH4NNS1"
        return $false
    }
    return $true
}

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$Name,
        [string]$Source = "",
        [switch]$ShowProgress
    )

    if (-not (Assert-WingetAvailable)) { return $false }

    try {
        $wingetArgs = @($PackageId, "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity")
        if (-not $ShowProgress) { $wingetArgs += "--silent" }
        if ($Source -ne "") { $wingetArgs += @("--source", $Source) }

        if ($ShowProgress) {
            Write-Host "$Cyan  Installing $Name...$Reset"
            & winget install @wingetArgs | Out-Host
        } else {
            # Silent install with animated spinner — winget runs in background
            # runspace, spinner animates in foreground.
            $exitCode = Invoke-WithSpinner -Message "Installing $Name" -ScriptBlock {
                param($wArgs)
                & winget install @wArgs 2>&1 | Out-Null
                $LASTEXITCODE
            } -ArgumentList (,@($wingetArgs))
            # Runspace returns as a collection; extract the int
            $LASTEXITCODE = ($exitCode -is [array]) ? [int]$exitCode[-1] : ($exitCode ? [int]$exitCode : 0)
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Log -Message "$Name installed." -Level SUCCESS
            return $true
        } elseif ($LASTEXITCODE -eq $WINGET_ALREADY_INSTALLED) {
            Write-Log -Message "$Name already installed." -Level SKIP
            return $true
        } else {
            Write-Log -Message "Failed to install $Name (exit code: $LASTEXITCODE)" -Level ERROR
            return $false
        }
    } catch {
        Write-Log -Message "Error installing ${Name}: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Invoke-NativeCommand {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [string]$SuccessMessage = "",
        [string]$ErrorMessage = ""
    )

    $label = $SuccessMessage ? ($SuccessMessage -replace '^\w+\s+', '') : "$Command $($Arguments[0])"
    try {
        $code = Invoke-WithSpinner -Message $label -ScriptBlock {
            param($cmd, $cmdArgs)
            & $cmd @cmdArgs 2>&1 | Out-Null
            $LASTEXITCODE
        } -ArgumentList $Command, (,@($Arguments))

        $exitCode = ($code -is [array]) ? [int]$code[-1] : ($code ? [int]$code : 0)
        if ($exitCode -ne 0) {
            $msg = $ErrorMessage ? $ErrorMessage : "Command failed: $Command $($Arguments -join ' ')"
            Write-Log -Message "$msg (exit code: $exitCode)" -Level ERROR
            return $false
        }
        if ($SuccessMessage) {
            Write-Log -Message $SuccessMessage -Level SUCCESS
        }
        return $true
    } catch {
        $msg = $ErrorMessage ? $ErrorMessage : "Command failed: $Command"
        Write-Log -Message "$msg - $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

$Purple = "$([char]0x1b)[38;5;141m"
$Reset = "$([char]0x1b)[0m"
$Red = "$([char]0x1b)[38;5;203m"
$Green = "$([char]0x1b)[38;5;120m"
$Yellow = "$([char]0x1b)[38;5;220m"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','SUCCESS','WARNING','ERROR','SKIP')]
        [string]$Level = 'INFO',
        [string]$LogFile = ""
    )

    $prefix = switch ($Level) {
        'SUCCESS' { "$Green[SUCCESS]$Reset" }
        'WARNING' { "$Yellow[WARNING]$Reset" }
        'ERROR'   { "$Red[FAILED]$Reset" }
        'SKIP'    { "$Yellow[SKIP]$Reset" }
        default   { "$Purple[INFO]$Reset" }
    }

    Write-Host "$prefix $Message"

    if ($LogFile -ne "") {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $plainLine = "[$timestamp] [$Level] $Message"
        try {
            Add-Content -Path $LogFile -Value $plainLine -ErrorAction SilentlyContinue
        } catch { Write-Warning "Failed to write to log file: $($_.Exception.Message)" }
    }
}

function Invoke-ReturnToMenu {
    $launchDirFile = "$env:TEMP\winrift_launchdir.txt"
    if (Test-Path $launchDirFile) {
        $rootPath = (Get-Content $launchDirFile -Raw).Trim()
        $mainScript = Join-Path $rootPath "winrift.ps1"
        if (Test-Path $mainScript) {
            & $mainScript
            return
        }
    }
    exit
}

function Show-MenuBox {
    param(
        [string]$Title,
        [string[]]$Items,
        [int]$Width = 56
    )

    $border = "$Purple +" + ("-" * $Width) + "+$Reset"
    $totalPad = $Width - 2 - $Title.Length
    $leftPad = [math]::Floor($totalPad / 2)
    $rightPad = $totalPad - $leftPad
    $titlePadded = (" " * $leftPad) + $Title + (" " * $rightPad)
    Write-Host ""
    Write-Host $border
    Write-Host "$Purple '$Purple $titlePadded $Purple'$Reset"
    Write-Host $border
    foreach ($item in $Items) {
        if ($item -match '^---\s+(.+?)\s*-*$') {
            $text = " $($Matches[1].TrimEnd('- ')) "
            $totalDashes = $Width - $text.Length
            $leftDashes = [math]::Floor($totalDashes / 2)
            $rightDashes = $totalDashes - $leftDashes
            Write-Host "$Purple +$("-" * $leftDashes)$text$("-" * $rightDashes)+$Reset"
        } elseif ($item -eq "---") {
            Write-Host $border
        } else {
            $itemPadded = $item.PadRight($Width - 2)
            Write-Host "$Purple '$Reset $itemPadded $Purple'$Reset"
        }
    }
    Write-Host $border
}

function New-SafeRestorePoint {
    Write-Host "`n$Purple Creating System Restore Point before applying tweaks...$Reset"
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Winrift - Before System Tweaks $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Log -Message "System Restore Point created successfully." -Level SUCCESS
    } catch {
        Write-Log -Message "Could not create restore point: $($_.Exception.Message)" -Level WARNING
        Write-Log -Message "Proceeding without restore point. Consider creating one manually." -Level WARNING
    }
    Write-Host ""
}

function Assert-AdminOrElevate {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Not running as admin. Elevating..." -ForegroundColor Yellow
        . "$PSScriptRoot\AdminLaunch.ps1"
        Start-AdminProcess -ScriptPath $PSCommandPath
        exit
    }
}

function Initialize-Logging {
    param([string]$ModuleName)
    $logDir = Join-Path $env:USERPROFILE "Winrift\logs"
    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    $script:LogFile = Join-Path $logDir "${ModuleName}_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
    Start-Transcript -Path $script:LogFile -Append | Out-Null
    Write-Log -Message "Session log: $script:LogFile" -Level INFO
}

function Invoke-MenuLoop {
    param(
        [string]$Title,
        [string[]]$Items,
        [hashtable]$Actions,
        [string]$Prompt = ">",
        [string]$ExitKey = $null,
        [scriptblock]$OnExit = $null
    )
    while ($true) {
        Clear-Host
        Show-MenuBox -Title $Title -Items $Items
        $choice = Read-Host $Prompt
        if ($ExitKey -and $choice -eq $ExitKey) {
            if ($OnExit) { & $OnExit }
            return
        }
        if ($Actions.ContainsKey($choice)) {
            & $Actions[$choice]
        }
    }
}

function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Type,
        $Value,
        [string]$Message
    )

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -Force

        $written = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
        if ($null -eq $written) {
            Write-Log -Message "Failed to verify $Name at $Path - value not found after write" -Level ERROR
        } else {
            Write-Log -Message $Message -Level SUCCESS
        }
    }
    catch {
        Write-Log -Message "Failed to set $Name at $Path. Error: $_" -Level ERROR
    }
}

function Get-ToolConfig {
    param([string]$ToolId)
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

    Write-Log -Message "Downloading $ToolName from $Url..." -Level INFO
    $scriptContent = Invoke-RestMethod -Uri $Url -ErrorAction Stop

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

    & ([ScriptBlock]::Create($scriptContent))
}

function Invoke-SecureDownload {
    param(
        [string]$Url,
        [string]$OutFile,
        [string]$ToolName = "file",
        [string]$ExpectedHash = ""
    )

    Write-Log -Message "Downloading $ToolName from $Url..." -Level INFO
    Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -ErrorAction Stop

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

    $boxWidth = 57
    $urlLine = "URL:    $($Tool.url)"
    if ($urlLine.Length -gt ($boxWidth - 4)) {
        $boxWidth = $urlLine.Length + 4
    }
    $border = "$Yellow +" + ("-" * $boxWidth) + "+$Reset"

    Write-Host ""
    Write-Host $border
    Write-Host "$Yellow '$Yellow  WARNING: External script execution                     $Yellow'$Reset"
    Write-Host $border
    $line1 = "This tool will fetch and run a script from the web.".PadRight($boxWidth - 2)
    Write-Host "$Yellow '$Reset $line1$Yellow'$Reset"
    $toolLine = "Tool:   $($Tool.name)".PadRight($boxWidth - 2)
    Write-Host "$Yellow '$Reset $toolLine$Yellow'$Reset"
    $urlPadded = $urlLine.PadRight($boxWidth - 2)
    Write-Host "$Yellow '$Reset $urlPadded$Yellow'$Reset"
    if ($Tool.docs) {
        $docsLine = "Source: $($Tool.docs)".PadRight($boxWidth - 2)
        Write-Host "$Yellow '$Reset $docsLine$Yellow'$Reset"
    }
    Write-Host $border
    Write-Host ""
    Write-Host "  [Y] Run   [N] Cancel   [R] Review project source"
    Write-Host ""

    while ($true) {
        $response = Read-Host "Your choice"
        switch ($response.ToUpper()) {
            "Y" { return $true }
            "N" { return $false }
            "R" {
                if ($Tool.docs) {
                    Start-Process $Tool.docs
                    Write-Host "$Green  Opened project source in browser.$Reset"
                    Write-Host "  [Y] Run   [N] Cancel"
                } else {
                    Write-Host "$Yellow  No documentation URL available for this tool.$Reset"
                }
            }
            default {
                Write-Host "  Please enter Y, N, or R."
            }
        }
    }
}

function Invoke-Tool {
    param(
        [Parameter(Mandatory)][string]$ToolId,
        [string]$SuccessMessage,
        [string]$ErrorMessage,
        [scriptblock]$OnSuccess,
        [switch]$Wait
    )

    $tool = Get-ToolConfig $ToolId
    if (-not $tool) {
        Write-Log -Message "Tool '$ToolId' not found in tools.json" -Level ERROR
        return $false
    }

    if ($tool.type -in @("irm", "download")) {
        $confirmed = Confirm-ExternalTool -Tool $tool
        if (-not $confirmed) {
            Write-Log -Message "User cancelled $($tool.name) launch." -Level INFO
            return $false
        }
    }

    try {
        if ($tool.sha256) { $hash = $tool.sha256 } else { $hash = "" }
        switch ($tool.type) {
            "irm" {
                Invoke-SecureScript -Url $tool.url -ToolName $tool.name -ExpectedHash $hash
            }
            "download" {
                $downloadPath = Join-Path $env:TEMP $tool.filename
                Invoke-SecureDownload -Url $tool.url -OutFile $downloadPath -ToolName $tool.name -ExpectedHash $hash
                if ($OnSuccess) {
                    & $OnSuccess $downloadPath
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

        if ($SuccessMessage) { $msg = $SuccessMessage } else { $msg = "$($tool.name) completed successfully." }
        Write-Log -Message $msg -Level SUCCESS
        if ($OnSuccess -and $tool.type -ne "download") {
            & $OnSuccess
        }
        return $true
    } catch {
        if ($ErrorMessage) { $msg = $ErrorMessage } else { $msg = "Failed to run $($tool.name)" }
        Write-Log -Message "${msg}: $($_.Exception.Message)" -Level ERROR
        if ($tool.fallbackUrl) {
            Write-Log -Message "Opening fallback page..." -Level INFO
            Start-Process $tool.fallbackUrl
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

function Invoke-NativeCommand {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [string]$SuccessMessage = "",
        [string]$ErrorMessage = ""
    )

    try {
        $output = & $Command @Arguments 2>&1
        if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            if ($ErrorMessage) { $msg = $ErrorMessage } else { $msg = "Command failed: $Command $($Arguments -join ' ')" }
            Write-Log -Message "$msg (exit code: $LASTEXITCODE)" -Level ERROR
            return $false
        }
        if ($SuccessMessage) {
            Write-Log -Message $SuccessMessage -Level SUCCESS
        }
        return $true
    } catch {
        if ($ErrorMessage) { $msg = $ErrorMessage } else { $msg = "Command failed: $Command" }
        Write-Log -Message "$msg - $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

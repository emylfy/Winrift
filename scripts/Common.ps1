[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ProgressPreference = 'SilentlyContinue'

$Purple = "$([char]0x1b)[38;5;141m"
$Dim = "$([char]0x1b)[38;5;243m"
$Reset = "$([char]0x1b)[0m"
$Red = "$([char]0x1b)[38;5;203m"
$Green = "$([char]0x1b)[38;5;120m"
$Yellow = "$([char]0x1b)[38;5;220m"

# Winget exit code for "package already installed"
$WINGET_ALREADY_INSTALLED = -1978335189

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

function Wait-ForUser {
    Read-Host "Press Enter to continue"
}

function Show-MenuBox {
    param(
        [string]$Title,
        [string[]]$Items,
        [int]$Width = 0
    )

    $h = [string][char]0x2500  # ─
    $v = [string][char]0x2502  # │
    $tl = [string][char]0x256D # ╭
    $tr = [string][char]0x256E # ╮
    $bl = [string][char]0x2570 # ╰
    $br = [string][char]0x256F # ╯

    if ($Width -le 0) {
        $maxLen = $Title.Length + 2
        foreach ($item in $Items) {
            if ($item -match '^---\s+(.+?)\s*-*$') {
                $sectionLen = ("  $($Matches[1].TrimEnd('- '))").Length
                if ($sectionLen -gt $maxLen) { $maxLen = $sectionLen }
            } elseif ($item -ne "---") {
                $plainLen = ($item -replace '\x1b\[[0-9;]*m', '').Length
                if ($plainLen -gt $maxLen) { $maxLen = $plainLen }
            }
        }
        $Width = [math]::Max($maxLen + 3, 40)
    }

    # Top border with title: ╭─ Title ───...───╮
    $titleText = "$h $Title "
    $topFill = $Width - $titleText.Length
    if ($topFill -lt 0) { $topFill = 0 }
    Write-Host ""
    Write-Host "$Dim $tl$h $Purple$Title$Dim $($h * $topFill)$tr$Reset"

    # Top padding
    Write-Host "$Dim $v$Reset$(" " * $Width)$Dim$v$Reset"

    foreach ($item in $Items) {
        if ($item -match '^---\s+(.+?)\s*-*$') {
            # Section header: empty line + colored text
            $sectionText = $Matches[1].TrimEnd('- ')
            Write-Host "$Dim $v$Reset$(" " * $Width)$Dim$v$Reset"
            $pad = $Width - ("  $sectionText").Length
            if ($pad -lt 0) { $pad = 0 }
            Write-Host "$Dim $v$Reset  $Purple$sectionText$Reset$(" " * $pad)$Dim$v$Reset"
        } elseif ($item -eq "---") {
            # Plain divider: just an empty line
            Write-Host "$Dim $v$Reset$(" " * $Width)$Dim$v$Reset"
        } else {
            $plainItem = $item -replace '\x1b\[[0-9;]*m', ''
            $pad = ($Width - 1) - $plainItem.Length
            if ($pad -lt 0) { $pad = 0 }
            $itemPadded = $item + (" " * $pad)
            Write-Host "$Dim $v$Reset $itemPadded$Dim$v$Reset"
        }
    }

    # Bottom padding + border
    Write-Host "$Dim $v$Reset$(" " * $Width)$Dim$v$Reset"
    Write-Host "$Dim $bl$($h * $Width)$br$Reset"
}

$script:RestorePointCreated = $false

function New-SafeRestorePoint {
    if ($script:RestorePointCreated) {
        Write-Log -Message "Restore point already created this session" -Level SKIP
        return
    }
    Write-Host "`n$Purple Creating System Restore Point before applying tweaks...$Reset"
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Winrift - Before System Tweaks $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop -WarningAction SilentlyContinue
        Write-Log -Message "System Restore Point created successfully." -Level SUCCESS
        $script:RestorePointCreated = $true
    } catch {
        Write-Log -Message "Could not create restore point: $($_.Exception.Message)" -Level WARNING
        $script:RestorePointCreated = $true  # Don't retry — Windows blocks within 1440 min anyway
    }
    Write-Host ""
}

function Assert-AdminOrElevate {
    param([string]$ScriptPath)
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Not running as admin. Elevating..." -ForegroundColor Yellow
        . "$PSScriptRoot\AdminLaunch.ps1"
        if (-not $ScriptPath) { $ScriptPath = (Get-PSCallStack)[1].ScriptName }
        Start-AdminProcess -ScriptPath $ScriptPath
        exit
    }
}

function Initialize-Logging {
    param([string]$ModuleName)
    $logDir = Join-Path $env:USERPROFILE "Winrift\logs"
    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    $script:LogFile = Join-Path $logDir "${ModuleName}_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
    try {
        Start-Transcript -Path $script:LogFile -Append -ErrorAction Stop | Out-Null
    } catch {
        Write-Verbose "Transcript not started: $($_.Exception.Message)"
    }
    Write-Log -Message "Session log: $script:LogFile" -Level INFO
}

function Invoke-MenuLoop {
    param(
        [string]$Title,
        [string[]]$Items,
        [hashtable]$Actions,
        [string]$Prompt = " ",
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

$script:TweakBackupEntries = [System.Collections.Generic.List[hashtable]]::new()
$script:DesiredStateEntries = [System.Collections.Generic.List[hashtable]]::new()
$script:DesiredStateCategory = "Uncategorized"
$_baseDir = $env:USERPROFILE
if (-not $_baseDir) { $_baseDir = $env:HOME }
if (-not $_baseDir) { $_baseDir = [System.IO.Path]::GetTempPath() }
$script:TweakBackupDir = Join-Path $_baseDir "Winrift\tweaks"
$script:DesiredStateDir = Join-Path $_baseDir "Winrift\tweaks"

function Start-TweakSession {
    # Don't clear if entries already accumulated this session
    $script:DesiredStateCategory = "Uncategorized"
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
        # Capture previous value for rollback
        $existed = Test-Path $Path
        $prevValue = $null
        $prevType = $null
        if ($existed) {
            $prop = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($null -ne $prop -and $null -ne $prop.$Name) {
                $prevValue = $prop.$Name
                $prevType = (Get-Item $Path).GetValueKind($Name).ToString()
            }
        }
        $script:TweakBackupEntries.Add(@{
            Path      = $Path
            Name      = $Name
            PrevValue = $prevValue
            PrevType  = $prevType
            Existed   = ($null -ne $prevValue)
        })

        if (-not $existed) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -Force -ErrorAction Stop

        $written = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
        if ($null -eq $written) {
            Write-Log -Message "Failed to verify $Name at $Path - value not found after write" -Level ERROR
        } else {
            $script:DesiredStateEntries.Add(@{
                Path     = $Path
                Name     = $Name
                Value    = $Value
                Type     = $Type
                Category = $script:DesiredStateCategory
            })
            Write-Log -Message $Message -Level SUCCESS
        }
    }
    catch {
        Write-Log -Message "Failed to set $Name at $Path. Error: $_" -Level ERROR
    }
}

function Save-TweakBackup {
    if ($script:TweakBackupEntries.Count -eq 0) { return $null }
    [System.IO.Directory]::CreateDirectory($script:TweakBackupDir) | Out-Null
    $backup = @{
        timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        entries   = @($script:TweakBackupEntries)
    }
    $fileName = "backup_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
    $filePath = Join-Path $script:TweakBackupDir $fileName
    $backup | ConvertTo-Json -Depth 5 | Set-Content -Path $filePath -Encoding UTF8
    Write-Log -Message "Tweak backup saved: $filePath ($($script:TweakBackupEntries.Count) entries)" -Level SUCCESS
}

function Save-DesiredState {
    if ($script:DesiredStateEntries.Count -eq 0) { return }
    [System.IO.Directory]::CreateDirectory($script:DesiredStateDir) | Out-Null
    $filePath = Join-Path $script:DesiredStateDir "desired_state.json"

    $existing = @()
    if (Test-Path $filePath) {
        try {
            $json = Get-Content $filePath -Raw | ConvertFrom-Json
            if ($json.entries) { $existing = @($json.entries) }
        } catch {
            Write-Log -Message "Could not read existing desired state, starting fresh." -Level WARNING
        }
    }

    $lookup = [ordered]@{}
    foreach ($entry in $existing) {
        $key = "$($entry.Path)|$($entry.Name)"
        $lookup[$key] = $entry
    }

    $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
    foreach ($entry in $script:DesiredStateEntries) {
        $key = "$($entry.Path)|$($entry.Name)"
        $lookup[$key] = @{
            Path      = $entry.Path
            Name      = $entry.Name
            Value     = $entry.Value
            Type      = $entry.Type
            Category  = $entry.Category
            UpdatedAt = $now
        }
    }

    $state = @{
        version     = 1
        lastUpdated = $now
        entries     = @($lookup.Values)
    }
    $state | ConvertTo-Json -Depth 5 | Set-Content -Path $filePath -Encoding UTF8
    Write-Log -Message "Desired state updated: $filePath ($($lookup.Count) total entries)" -Level SUCCESS
}

function Restore-TweakBackup {
    if (-not (Test-Path $script:TweakBackupDir)) {
        Write-Log -Message "No tweak backups found." -Level INFO
        Wait-ForUser
        return
    }

    $backups = Get-ChildItem -Path $script:TweakBackupDir -Filter "backup_*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($backups.Count -eq 0) {
        Write-Log -Message "No tweak backups found." -Level INFO
        Wait-ForUser
        return
    }

    $menuItems = @()
    for ($i = 0; $i -lt [math]::Min($backups.Count, 10); $i++) {
        $b = Get-Content $backups[$i].FullName -Raw | ConvertFrom-Json
        $count = $b.entries.Count
        $menuItems += "$($i + 1) › $($b.timestamp) ($count changes)"
    }
    $cancelIdx = [math]::Min($backups.Count, 10) + 1
    $menuItems += "---"
    $menuItems += "$cancelIdx › Cancel"

    Show-MenuBox -Title "Restore Tweak Backup" -Items $menuItems
    $choice =  Read-Host " "

    $idx = 0
    if (-not ([int]::TryParse($choice, [ref]$idx)) -or $idx -lt 1 -or $idx -gt $backups.Count -or $idx -eq $cancelIdx) { return }

    $selected = Get-Content $backups[$idx - 1].FullName -Raw | ConvertFrom-Json
    $restored = 0
    $errors = 0

    foreach ($entry in $selected.entries) {
        try {
            if ($entry.Existed -and $null -ne $entry.PrevValue) {
                $type = if ($entry.PrevType) { $entry.PrevType } else { "String" }
                Set-ItemProperty -Path $entry.Path -Name $entry.Name -Type $type -Value $entry.PrevValue -Force
                $restored++
            } elseif (-not $entry.Existed) {
                Remove-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
                $restored++
            }
        } catch {
            $errors++
        }
    }

    Write-Log -Message "Restored $restored of $($selected.entries.Count) registry values. Errors: $errors" -Level $(if ($errors -eq 0) { 'SUCCESS' } else { 'WARNING' })
    Write-Log -Message "A system restart is recommended for changes to take effect." -Level INFO
    Wait-ForUser
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

    & ([ScriptBlock]::Create($scriptContent)) | Out-Host
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

    $items = @(
        "This tool will fetch and run a script from the web.",
        "Tool:   $($Tool.name)",
        "URL:    $($Tool.url)"
    )
    if ($Tool.docs) { $items += "Source: $($Tool.docs)" }
    $items += "---"
    $items += "Y › Run   N › Cancel   R › Review source"

    Show-MenuBox -Title "External script execution" -Items $items
    Write-Host ""

    while ($true) {
        $response = Read-Host " "
        switch ($response.ToUpper()) {
            "Y" { return $true }
            "N" { return $false }
            "R" {
                if ($Tool.docs) {
                    Start-Process $Tool.docs
                    Write-Host "$Green  Opened project source in browser.$Reset"
                } else {
                    Write-Host "$Yellow  No documentation URL available.$Reset"
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
        [switch]$Wait,
        [switch]$SkipConfirm
    )

    $tool = Get-ToolConfig $ToolId
    if (-not $tool) {
        Write-Log -Message "Tool '$ToolId' not found in tools.json" -Level ERROR
        return $false
    }

    if ($tool.type -in @("irm", "download") -and -not $SkipConfirm) {
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
            if ($SuccessMessage) { $msg = $SuccessMessage } else { $msg = "$($tool.name) completed successfully." }
            Write-Log -Message $msg -Level SUCCESS
        }
        if ($OnSuccess -and $tool.type -ne "download") {
            & $OnSuccess | Out-Host
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

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$Name,
        [string]$Source = "",
        [switch]$ShowProgress
    )

    if (-not (Assert-WingetAvailable)) { return $false }

    Write-Host -NoNewline "$Purple  Installing $Name...$Reset"
    try {
        $wingetArgs = @($PackageId, "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity")
        if (-not $ShowProgress) { $wingetArgs += "--silent" }
        if ($Source -ne "") { $wingetArgs += @("--source", $Source) }
        if ($ShowProgress) {
            Write-Host ""
            & winget install @wingetArgs | Out-Host
        } else {
            & winget install @wingetArgs 2>&1 | Out-Null
        }
        if ($LASTEXITCODE -eq 0) {
            Write-Host " $Green done$Reset"
            return $true
        } elseif ($LASTEXITCODE -eq $WINGET_ALREADY_INSTALLED) {
            Write-Host " $Yellow already installed$Reset"
            return $true
        } else {
            Write-Host " $Red failed$Reset (exit code: $LASTEXITCODE)"
            return $false
        }
    } catch {
        Write-Host " $Red error$Reset"
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

    try {
        $null = & $Command @Arguments 2>&1
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

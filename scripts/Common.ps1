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
    $launchDirFile = "$env:TEMP\simplify11_launchdir.txt"
    if (Test-Path $launchDirFile) {
        $rootPath = (Get-Content $launchDirFile -Raw).Trim()
        $mainScript = Join-Path $rootPath "simplify11.ps1"
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
    $titlePadded = $Title.PadRight($Width - 2)
    Write-Host ""
    Write-Host $border
    Write-Host "$Purple '$Purple $titlePadded $Purple'$Reset"
    Write-Host $border
    foreach ($item in $Items) {
        if ($item -eq "---") {
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
        Checkpoint-Computer -Description "Simplify11 - Before System Tweaks $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
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
    $logDir = Join-Path $env:USERPROFILE "Simplify11\logs"
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
        Write-Log -Message $Message -Level SUCCESS
    }
    catch {
        Write-Log -Message "Failed to set $Name at $Path. Error: $_" -Level ERROR
    }
}

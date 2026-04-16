[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'

# ANSI color palette. Truecolor (24-bit) when the terminal supports it
# (Windows Terminal, VS Code, any COLORTERM=truecolor terminal); falls back
# to 256-color for legacy ConHost / cmd sessions.
$Bold  = "$([char]0x1b)[1m"
$Reset = "$([char]0x1b)[0m"
$_tc = [bool]$env:WT_SESSION -or ($env:COLORTERM -match 'truecolor|24bit') -or ($env:TERM_PROGRAM -eq 'vscode')
if ($_tc) {
    $Dim    = "$([char]0x1b)[38;2;90;90;100m"
    $Red    = "$([char]0x1b)[38;2;232;65;65m"
    $Green  = "$([char]0x1b)[38;2;80;200;120m"
    $Yellow = "$([char]0x1b)[38;2;250;200;75m"
    $Cyan   = "$([char]0x1b)[38;2;0;175;255m"
    $Ice    = "$([char]0x1b)[38;2;200;230;255m"
} else {
    $Dim    = "$([char]0x1b)[38;5;240m"
    $Red    = "$([char]0x1b)[0;31m"
    $Green  = "$([char]0x1b)[0;32m"
    $Yellow = "$([char]0x1b)[0;33m"
    $Cyan   = "$([char]0x1b)[38;5;39m"
    $Ice    = "$([char]0x1b)[38;5;195m"
}
Remove-Variable _tc

# Winget exit code for "package already installed"
$WINGET_ALREADY_INSTALLED = -1978335189

function Initialize-NerdFont {
    $script:HasNerdFont = $false
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $families = [System.Drawing.Text.InstalledFontCollection]::new().Families
        $script:HasNerdFont = [bool]($families | Where-Object {
            $_.Name -match 'Nerd Font|NF\b|Caskaydia|MesloLG|JetBrains.*NF|FiraCode NF|Maple Mono NF'
        })
    } catch { $null = $_ }
    $nf = $script:HasNerdFont
    $script:MenuIcons = @{
        audit     = $nf ? "$([char]::ConvertFromUtf32(0xF0510)) " : "? "
        tweaks    = $nf ? "$([char]::ConvertFromUtf32(0xF08D6)) " : "* "
        security  = $nf ? "$([char]::ConvertFromUtf32(0xF0496)) " : "# "
        drivers   = $nf ? "$([char]::ConvertFromUtf32(0xF12A2)) " : "> "
        benchmark = $nf ? "$([char]::ConvertFromUtf32(0xF03D6)) " : "% "
        bundles   = $nf ? "$([char]::ConvertFromUtf32(0xF187)) "  : "+ "
        customize = $nf ? "$([char]::ConvertFromUtf32(0xF1535)) " : ": "
        iso       = $nf ? "$([char]::ConvertFromUtf32(0xF1477)) " : "o "
    }
}

# Breadcrumb navigation stack — `$script:` is per-script-scope, so when functions
# from Common.ps1 are called from a child script (invoked via `& script.ps1`),
# the child has its own empty `$script:Breadcrumbs`. Each function defensively
# initializes it on first use within its calling scope.
$script:Breadcrumbs = [System.Collections.Generic.List[string]]::new()

function Push-Breadcrumb {
    param([string]$Name)
    if ($null -eq $script:Breadcrumbs) {
        $script:Breadcrumbs = [System.Collections.Generic.List[string]]::new()
    }
    $script:Breadcrumbs.Add($Name)
    $Host.UI.RawUI.WindowTitle = ($script:Breadcrumbs -join " $([char]0x203A) ")
}

function Pop-Breadcrumb {
    if ($null -eq $script:Breadcrumbs -or $script:Breadcrumbs.Count -eq 0) { return }
    $script:Breadcrumbs.RemoveAt($script:Breadcrumbs.Count - 1)
    if ($script:Breadcrumbs.Count -gt 0) {
        $Host.UI.RawUI.WindowTitle = ($script:Breadcrumbs -join " $([char]0x203A) ")
    }
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','SUCCESS','WARNING','ERROR','SKIP')]
        [string]$Level = 'INFO',
        [string]$LogFile = ""
    )

    $glyph = switch ($Level) {
        'SUCCESS' { "$Green$([char]0x2713)$Reset" }   # ✓
        'WARNING' { "$Yellow!$Reset" }
        'ERROR'   { "$Red$([char]0x2717)$Reset" }     # ✗
        'SKIP'    { "$Dim-$Reset" }
        default   { "$Cyan$([char]0x203A)$Reset" }    # ›
    }

    Write-Host "  $glyph  $Message"

    $effectiveLog = ($LogFile -ne "") ? $LogFile : ($script:LogFile ? $script:LogFile : "")
    if ($effectiveLog -ne "") {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $plainLine = "[$timestamp] [$Level] $Message"
        try {
            Add-Content -Path $effectiveLog -Value $plainLine -ErrorAction SilentlyContinue
        } catch { Write-Warning "Failed to write to log file: $($_.Exception.Message)" }
    }
}

function Wait-ForUser {
    Write-Host "  $Dim Press any key to continue...$Reset" -NoNewline
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
}

function Invoke-WithSpinner {
    # Runs $ScriptBlock in a background runspace while animating a braille
    # spinner on the current line. Returns whatever the scriptblock outputs.
    # Throws if the scriptblock threw.
    #
    # Uses [PowerShell]::Create() instead of Start-Job — starts in ~10ms
    # (vs 200-500ms for Start-Job's child process), same isolation.
    # -ArgumentList values are passed as $args inside the scriptblock.
    param(
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [string]$Message = "Working",
        [object[]]$ArgumentList = @()
    )
    # When running under Pester (or any context that sets WINRIFT_NO_SPINNER),
    # skip the background runspace and run synchronously. Pester mocks are
    # scope-local and don't propagate into child runspaces.
    if ($env:WINRIFT_NO_SPINNER) {
        return (& $ScriptBlock @ArgumentList)
    }

    $frames = @([char]0x280B, [char]0x2819, [char]0x2839, [char]0x2838, [char]0x283C, [char]0x2834, [char]0x2826, [char]0x2827, [char]0x2807, [char]0x280F)

    $ps = [PowerShell]::Create()
    try {
        $null = $ps.AddScript($ScriptBlock)
        foreach ($arg in $ArgumentList) {
            $null = $ps.AddArgument($arg)
        }
        $handle = $ps.BeginInvoke()

        $i = 0
        while (-not $handle.IsCompleted) {
            Write-Host -NoNewline "`r$Cyan  $($frames[$i % $frames.Count])$Reset $Message..."
            Start-Sleep -Milliseconds 80
            $i++
        }
        Write-Host -NoNewline ("`r" + (" " * ($Message.Length + 10)) + "`r")

        $result = $ps.EndInvoke($handle)

        if ($ps.HadErrors) {
            $errMsg = ($ps.Streams.Error | ForEach-Object { $_.Exception.Message }) -join '; '
            throw $errMsg
        }

        return $result
    } finally {
        $ps.Dispose()
    }
}

$script:RestorePointCreated = $false

function New-SafeRestorePoint {
    if ($script:RestorePointCreated) {
        Write-Log -Message "Restore point already created this session" -Level SKIP
        return
    }
    Write-Host ""
    try {
        Invoke-WithSpinner -Message "Creating System Restore Point" -ScriptBlock {
            Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description "Winrift - Before System Tweaks $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop -WarningAction SilentlyContinue
        }
        Write-Log -Message "System Restore Point created successfully." -Level SUCCESS
        $script:RestorePointCreated = $true
    } catch {
        Write-Log -Message "Could not create restore point: $($_.Exception.Message)" -Level WARNING
        $script:RestorePointCreated = $true  # Don't retry — Windows blocks within 1440 min anyway
    }
    Write-Host ""
}

function Initialize-Logging {
    param([string]$ModuleName)
    $logDir = Join-Path ($env:LOCALAPPDATA ?? $env:TMPDIR ?? "/tmp") "Winrift/logs"
    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    $script:LogFile = Join-Path $logDir "${ModuleName}_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
    try {
        Start-Transcript -Path $script:LogFile -Append -ErrorAction Stop | Out-Null
    } catch {
        Write-Verbose "Transcript not started: $($_.Exception.Message)"
    }
    Write-Log -Message "Session log: $script:LogFile" -Level INFO
}

# Sub-modules — dot-sourced so all functions share the caller's scope
. "$PSScriptRoot\Common.TUI.ps1"
. "$PSScriptRoot\Common.Registry.ps1"
. "$PSScriptRoot\Common.Tools.ps1"

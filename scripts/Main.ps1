param(
    [switch]$DryRun,
    [switch]$NoConfirm,
    [switch]$Uninstall
)

# Admin elevation — fail fast before any expensive I/O
# Loads only AdminLaunch.ps1 (~55 lines, no deps) so the non-admin process
# exits as cheaply as possible without going through Common.ps1 / transcript.
# Without this, the user sees several [STARTUP] lines flash by before the
# UAC prompt — looks like the script hung or crashed.
. "$PSScriptRoot\AdminLaunch.ps1"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Winrift requires administrator privileges. Requesting elevation..." -ForegroundColor Yellow

    $passthrough = @()
    if ($DryRun)    { $passthrough += "-DryRun" }
    if ($NoConfirm) { $passthrough += "-NoConfirm" }
    if ($Uninstall) { $passthrough += "-Uninstall" }

    try {
        Start-AdminProcess -ScriptPath $PSCommandPath -Arguments $passthrough -NoExit
    } catch {
        Write-Host "Elevation cancelled or failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    exit 0
}

# Startup transcript — captures everything, even pre-Common.ps1 failures
$script:StartupLogStarted = $false
try {
    $logDir = Join-Path $env:LOCALAPPDATA "Winrift\logs"
    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    $script:StartupLog = Join-Path $logDir "winrift_startup_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')_$PID.log"
    Start-Transcript -Path $script:StartupLog -Force -ErrorAction Stop | Out-Null
    $script:StartupLogStarted = $true
} catch {
    Write-Warning "Failed to start startup transcript: $($_.Exception.Message)"
}

$ErrorActionPreference = 'Stop'

try {
    . "$PSScriptRoot\Common.ps1"

    if ($DryRun) { $env:WINRIFT_DRY_RUN = "1" }
    if ($NoConfirm) { $env:WINRIFT_NO_CONFIRM = "1" }

    Initialize-NerdFont

    # Background thread: samples CPU/RAM/procs every 10 seconds.
    # Only queries CIM when .Active = $true (set by the main menu); sleeps otherwise
    # so sub-modules don't waste CIM calls the user never sees.
    $script:SysStats = [hashtable]::Synchronized(@{ CPU = '...'; RAM = '...'; Procs = '...'; Active = $false })
    $script:StatsJob = Start-ThreadJob -ScriptBlock {
        param($s)
        while ($true) {
            if ($s.Active) {
                try {
                    $os  = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
                    $cpu = (Get-CimInstance Win32_Processor -ErrorAction Stop | Measure-Object -Property LoadPercentage -Average).Average
                    $s.CPU   = "$([Math]::Round($cpu))%"
                    $s.RAM   = "$([Math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100))%"
                    $s.Procs = (Get-Process -ErrorAction Stop).Count
                } catch { $null = $_ }
            }
            Start-Sleep -Seconds 10
        }
    } -ArgumentList $script:SysStats

    # Background job: scans system state for dynamic sidebar descriptions.
    # Covers audit cache, drift state, benchmark reports, GPU, Defender, Copilot/Recall.
    $script:MenuState = $null
    $script:MenuStateUpdated = $false
    $script:MenuStateScript = {
        param($DataDir)
        $r = @{}

        # Audit cache
        try {
            $f = Join-Path $DataDir "audit\last.json"
            if (Test-Path $f) {
                $d = Get-Content $f -Raw | ConvertFrom-Json
                $fl = @($d.findings)
                $r['audit'] = @{
                    critical  = @($fl | Where-Object { $_.Severity -eq 'critical' }).Count
                    warning   = @($fl | Where-Object { $_.Severity -eq 'warning' }).Count
                    info      = @($fl | Where-Object { $_.Severity -eq 'info' }).Count
                    total     = $fl.Count
                    timestamp = $d.timestamp
                }
            }
        } catch { $null = $_ }

        # Drift state + live registry comparison
        try {
            $f = Join-Path $DataDir "tweaks\desired_state.json"
            if (Test-Path $f) {
                $d = Get-Content $f -Raw | ConvertFrom-Json
                $entries = @($d.entries)
                $cats = @($entries | ForEach-Object { $_.Category } | Select-Object -Unique).Count
                $drifted = 0
                foreach ($e in $entries) {
                    try {
                        $v = (Get-ItemProperty -Path $e.Path -Name $e.Name -ErrorAction Stop).$($e.Name)
                        if ("$v" -ne "$($e.Value)") { $drifted++ }
                    } catch { $drifted++ }
                }
                $r['tweaks'] = @{ entries = $entries.Count; categories = $cats; drifted = $drifted }
            }
        } catch { $null = $_ }

        # Last benchmark report
        try {
            $bd = Join-Path $DataDir "benchmarks"
            if (Test-Path $bd) {
                $rp = @(Get-ChildItem $bd -Filter "report_*.md" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
                if ($rp.Count -gt 0) { $r['benchmark'] = @{ date = $rp[0].LastWriteTime.ToString('yyyy-MM-dd HH:mm') } }
            }
        } catch { $null = $_ }

        # GPU via registry
        try {
            $ck = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
            if (Test-Path $ck) {
                Get-ChildItem $ck -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object {
                    try {
                        $desc = (Get-ItemProperty $_.PSPath -ErrorAction Stop).DriverDesc
                        if ($desc -and -not $r.ContainsKey('gpu')) { $r['gpu'] = $desc }
                    } catch { $null = $_ }
                }
            }
        } catch { $null = $_ }

        # Defender
        try {
            $dp = Get-MpPreference -ErrorAction Stop
            $r['defender'] = $dp.DisableRealtimeMonitoring ? 'disabled' : 'active'
        } catch { $r['defender'] = 'unknown' }

        # Copilot & Recall
        try {
            $r['copilot'] = (Get-AppxPackage -Name "*Copilot*" -ErrorAction SilentlyContinue) ? 'installed' : 'removed'
        } catch { $r['copilot'] = 'unknown' }
        try {
            $r['recall'] = (Get-AppxPackage -Name "*Recall*" -ErrorAction SilentlyContinue) ? 'installed' : 'removed'
        } catch { $r['recall'] = 'unknown' }

        return $r
    }
    $script:MenuStateJob = Start-ThreadJob -ScriptBlock $script:MenuStateScript -ArgumentList (Join-Path $env:LOCALAPPDATA "Winrift")

    if ($Uninstall) {
        Write-Host ""
        Write-Log -Message "Uninstalling Winrift..." -Level INFO
        $shortcut = Join-Path ([Environment]::GetFolderPath('StartMenu')) "Programs\Winrift.lnk"
        if (Test-Path $shortcut) { Remove-Item $shortcut -Force; Write-Log -Message "Removed Start Menu shortcut" -Level SUCCESS }
        $dataDir = Join-Path $env:LOCALAPPDATA "Winrift"
        if (Test-Path $dataDir) { Remove-Item $dataDir -Recurse -Force; Write-Log -Message "Removed data directory: $dataDir" -Level SUCCESS }
        try { Unregister-ScheduledTask -TaskName "Winrift-DriftCheck" -Confirm:$false -ErrorAction Stop; Write-Log -Message "Removed drift check scheduled task" -Level SUCCESS } catch { $null = $_ }
        Write-Log -Message "Winrift uninstalled." -Level SUCCESS
        exit 0
    }

    # Capture root path — one level up from scripts/ to repo root
    $script:Root = Split-Path $PSScriptRoot -Parent


    # Load version from version.json
    $script:UpdateAvailable = $null
    $script:UpdateCheckJob = $null
    $versionInfo = $null
    $versionFile = Join-Path $script:Root "config\version.json"
    if (Test-Path $versionFile) {
        $versionInfo = Get-Content $versionFile -Raw | ConvertFrom-Json
        $full = $versionInfo.version
        $script:AppVersion = ($full -split '\.')[0..1] -join '.'

        # Kick off update check in background — does not block startup.
        if ($versionInfo.repo) {
            $script:UpdateCheckJob = Start-ThreadJob -ScriptBlock {
                param($Repo, $LocalVer)
                try {
                    $url = "https://raw.githubusercontent.com/$Repo/main/config/version.json"
                    $remote = Invoke-RestMethod -Uri $url -TimeoutSec 5 -ErrorAction Stop
                    if ($remote.version -and $remote.version -ne $LocalVer) {
                        return $remote.version
                    }
                } catch { $null = $_ }
                return $null
            } -ArgumentList $versionInfo.repo, $versionInfo.version
        }
    } else {
        $script:AppVersion = "unknown"
    }

function Invoke-Module {
    param([string]$ScriptPath, [switch]$UserProcess)
    if (-not (Test-Path $ScriptPath)) {
        Write-Log -Message "Module not found: $ScriptPath" -Level ERROR
        Write-Host "$Yellow This module may not be included in your installation.$Reset"
        $null = Read-Host "Press Enter to continue"
        return
    }
    if ($UserProcess) {
        Start-UserProcess -ScriptPath $ScriptPath
    } else {
        & $ScriptPath
        $Host.UI.RawUI.WindowTitle = "Winrift v$script:AppVersion"
    }
}

function Get-UpdateCheckResult {
    if ($null -eq $script:UpdateCheckJob) { return }
    if ($script:UpdateCheckJob.State -eq 'Completed') {
        $result = Receive-Job $script:UpdateCheckJob -ErrorAction SilentlyContinue
        Remove-Job $script:UpdateCheckJob -Force -ErrorAction SilentlyContinue
        $script:UpdateCheckJob = $null
        if ($result) { $script:UpdateAvailable = $result }
    } elseif ($script:UpdateCheckJob.State -in 'Failed','Stopped') {
        Remove-Job $script:UpdateCheckJob -Force -ErrorAction SilentlyContinue
        $script:UpdateCheckJob = $null
    }
}

function Get-MenuStateResult {
    if ($null -eq $script:MenuStateJob) { return }
    if ($script:MenuStateJob.State -eq 'Completed') {
        $result = Receive-Job $script:MenuStateJob -ErrorAction SilentlyContinue
        Remove-Job $script:MenuStateJob -Force -ErrorAction SilentlyContinue
        $script:MenuStateJob = $null
        if ($result) { $script:MenuState = $result; $script:MenuStateUpdated = $true }
    } elseif ($script:MenuStateJob.State -in 'Failed','Stopped') {
        Remove-Job $script:MenuStateJob -Force -ErrorAction SilentlyContinue
        $script:MenuStateJob = $null
    }
}

function Start-MenuStateCheck {
    if ($script:MenuStateJob) {
        Remove-Job $script:MenuStateJob -Force -ErrorAction SilentlyContinue
    }
    $script:MenuStateJob = Start-ThreadJob -ScriptBlock $script:MenuStateScript -ArgumentList (Join-Path $env:LOCALAPPDATA "Winrift")
}

function Build-MenuDescriptions {
    $d = @{}
    $st = $script:MenuState
    $dot = "$Dim$([char]0x00B7)$Reset"
    $ok = "$Green$([char]0x2713)$Reset"

    if ($st -and $st.ContainsKey('audit')) {
        $a = $st['audit']
        if ($a.total -eq 0) {
            $d[0] = @("$ok All checks passed.", "${Dim}No issues found.$Reset")
        } else {
            $parts = @()
            if ($a.critical -gt 0) { $parts += "$Red$([char]0x2717) $($a.critical) critical$Reset" }
            if ($a.warning -gt 0)  { $parts += "$Yellow! $($a.warning) warning$Reset" }
            if ($a.info -gt 0)     { $parts += "$Cyan$([char]0x203A) $($a.info) info$Reset" }
            $lines = @($parts -join "  ")
            try {
                $ts = [datetime]::Parse($a.timestamp)
                $when = ($ts.Date -eq (Get-Date).Date) ? "today $($ts.ToString('HH:mm'))" : $ts.ToString('MMM d')
                $lines += "${Dim}Scanned $when$Reset"
            } catch { $null = $_ }
            $lines += ""
            $lines += "Select issues and apply fixes,"
            $lines += "or press ${Ice}C$Reset to fix all critical."
            $d[0] = $lines
        }
    } else {
        $d[0] = @(
            "Scan your system for issues.",
            "${Dim}Privacy $dot Performance $dot Memory$Reset",
            "${Dim}Storage $dot Startup $dot Network$Reset", "",
            "Each issue has a fix you can",
            "apply right from here."
        )
    }

    if ($st -and $st.ContainsKey('tweaks')) {
        $t = $st['tweaks']
        $lines = @("$Cyan$($t.categories)$Reset categories $dot $Cyan$($t.entries)$Reset values applied")
        if ($t.drifted -gt 0) {
            $lines += "$Yellow! $($t.drifted) drifted$Reset"
        } else {
            $lines += "$ok No drift"
        }
        $lines += ""
        $lines += "${Dim}Pick more categories or$Reset"
        $lines += "${Dim}restore previous backup.$Reset"
        $d[1] = $lines
    } else {
        $d[1] = @(
            "Optimize performance, input,",
            "storage, GPU, network, power.", "",
            "${Dim}13 categories. Pick one, apply$Reset",
            "${Dim}all safe, or use the wizard.$Reset", "",
            "${Dim}Restore point created before$Reset",
            "${Dim}any changes. Full undo available.$Reset"
        )
    }

    if ($st -and ($st.ContainsKey('defender') -or $st.ContainsKey('copilot'))) {
        $def = $st.ContainsKey('defender') ? $st['defender'] : 'unknown'
        $defC = switch ($def) { 'active' { $Yellow } 'disabled' { $Green } default { $Dim } }
        $cop = $st.ContainsKey('copilot') ? $st['copilot'] : 'unknown'
        $rec = $st.ContainsKey('recall')  ? $st['recall']  : 'unknown'
        $copC = ($cop -eq 'removed') ? $Green : $Yellow
        $recC = ($rec -eq 'removed') ? $Green : $Yellow
        $d[2] = @(
            "Defender: $defC$def$Reset",
            "Copilot: $copC$cop$Reset $dot Recall: $recC$rec$Reset", "",
            "${Dim}Disable Defender, remove AI,$Reset",
            "${Dim}harden 200+ privacy settings,$Reset",
            "${Dim}or find the fastest DNS.$Reset"
        )
    } else {
        $d[2] = @(
            "Manage Defender, remove Copilot",
            "and Recall, harden privacy,",
            "benchmark and apply fastest DNS.", "",
            "${Dim}Each tool runs only when selected.$Reset"
        )
    }

    if ($st -and $st.ContainsKey('gpu')) {
        $d[3] = @(
            "$Cyan$($st['gpu'])$Reset", "",
            "NVIDIA $dot AMD $dot Intel + 11 OEM",
            "${Dim}Opens official download pages.$Reset"
        )
    } else {
        $d[3] = @(
            "NVIDIA $dot AMD $dot Intel + 11 OEM",
            "${Dim}Opens official download pages.$Reset"
        )
    }

    if ($st -and $st.ContainsKey('benchmark')) {
        $d[4] = @(
            "Last run: $Cyan$($st['benchmark'].date)$Reset", "",
            "Run again to compare with the",
            "previous snapshot.", "",
            "${Dim}CPU $dot RAM $dot Boot $dot Processes$Reset",
            "${Dim}Services $dot DPC $dot Ctx switches$Reset"
        )
    } else {
        $d[4] = @(
            "Measure your system before and",
            "after tweaks to see the difference.", "",
            "${Dim}CPU $dot RAM $dot Boot $dot Processes$Reset",
            "${Dim}Services $dot DPC $dot Ctx switches$Reset"
        )
    }

    $d[6] = @(
        "Install apps by category:",
        "$Cyan Dev$Reset $dot $Green Browsers$Reset $dot $Yellow Utilities$Reset",
        "$Cyan Gaming$Reset $dot $Green Media$Reset $dot $Yellow Productivity$Reset",
        "$Cyan Communications$Reset", "",
        "${Dim}Browse, search, or open in UniGetUI.$Reset"
    )

    $d[7] = @(
        "$Cyan GlazeWM$Reset $dot $Green Oh My Posh$Reset $dot $Yellow Nerd Fonts$Reset",
        "$Cyan Themes$Reset $dot $Green Editors$Reset $dot $Yellow Wallpapers$Reset", "",
        "${Dim}Desktop, terminal, and app theming.$Reset",
        "${Dim}Runs without admin.$Reset",
        "${Dim}Profile backup & restore.$Reset"
    )

    $d[8] = @(
        "Build a clean Windows 11 ISO",
        "${Dim}Removes bloat, disables telemetry,$Reset",
        "${Dim}bypasses hardware checks.$Reset", "",
        "${Dim}Built-in or custom answer file.$Reset"
    )

    $d[10] = @(
        "$Cyan WinUtil$Reset $dot $Cyan Sparkle$Reset $dot $Cyan GTweak$Reset",
        "$Cyan WinScript$Reset", "",
        "${Dim}Popular community tools.$Reset",
        "${Dim}Each opens in a new window.$Reset"
    )

    $d[11] = @(
        "$Cyan Tweaks guide$Reset $dot $Cyan Answer file$Reset",
        "$Cyan Benchmark methodology$Reset $dot $Cyan Wiki$Reset", "",
        "${Dim}Opens in browser.$Reset"
    )

    return $d
}

function Invoke-SelfUpdate {
    param([string]$Version)
    $zipUrl  = "https://github.com/$($versionInfo.repo)/archive/refs/heads/main.zip"
    $tempZip = Join-Path $env:TEMP "winrift_update_$(Get-Random).zip"
    $tempDir = Join-Path $env:TEMP "winrift_update_$(Get-Random)"
    try {
        Invoke-WithSpinner -Message "Downloading v$Version" -ScriptBlock {
            param($url, $out)
            Invoke-WebRequest -Uri $url -OutFile $out -TimeoutSec 120 -ErrorAction Stop
        } -ArgumentList $zipUrl, $tempZip

        Write-Log -Message "Extracting..." -Level INFO
        Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force

        $srcDir = Get-ChildItem $tempDir -Directory | Select-Object -First 1
        if (-not $srcDir) {
            Write-Log -Message "Downloaded archive is empty or malformed. Aborting update." -Level ERROR
            Wait-ForUser
            return
        }

        $srcVersionFile = Join-Path $srcDir.FullName "config\version.json"
        if (Test-Path $srcVersionFile) {
            $newVersion = (Get-Content $srcVersionFile -Raw | ConvertFrom-Json).version
            if ($newVersion -ne $Version) {
                Write-Log -Message "Version mismatch: expected $Version, downloaded $newVersion. Aborting update." -Level ERROR
                Wait-ForUser
                return
            }
        } else {
            $zipSize = (Get-Item $tempZip).Length
            if ($zipSize -lt 50000) {
                Write-Log -Message "Downloaded zip is unexpectedly small ($zipSize bytes). Aborting update." -Level ERROR
                Wait-ForUser
                return
            }
        }

        Get-ChildItem $srcDir.FullName | Where-Object { $_.Name -ne 'logs' } | ForEach-Object {
            Copy-Item $_.FullName $script:Root -Recurse -Force
        }

        Write-Log -Message "Updated to v$Version. Restarting..." -Level SUCCESS
        Start-Sleep -Seconds 1
        Start-AdminProcess -ScriptPath $PSCommandPath -NoExit
        exit 0
    } catch {
        Write-Log -Message "Update failed: $($_.Exception.Message)" -Level ERROR
        Wait-ForUser
    } finally {
        Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Show-CommunityToolsMenu {
    $launcherPath = "$script:Root\modules\tools\ExternalLauncher.ps1"

    Invoke-MenuLoop -Title "Community Tools" -Items @(
        "1 › WinUtil - Tweaks, Apps & Fixes",
        "2 › Sparkle - Optimize & Debloat",
        "3 › GTweak - Debloat & Tweak",
        "4 › WinScript - Custom Script Builder",
        "---",
        "5 › Back to main menu"
    ) -Actions @{
        "1" = { Start-AdminProcess -ScriptPath $launcherPath -Arguments @("-ToolId", "winutil") }
        "2" = { Start-AdminProcess -ScriptPath $launcherPath -Arguments @("-ToolId", "sparkle") }
        "3" = { Start-AdminProcess -ScriptPath $launcherPath -Arguments @("-ToolId", "gtweak") }
        "4" = {
            & "$script:Root\modules\tools\WinScript.ps1"
            $Host.UI.RawUI.WindowTitle = "Winrift v$script:AppVersion"
        }
    } -ExitKey "5"
}

function Show-DocsMenu {
    Invoke-MenuLoop -Title "Docs & Guides" -Items @(
        "1 › Tweaks Guide - What each tweak does",
        "2 › Answer File Guide - Windows installation",
        "3 › Testing & Benchmarks - Methodology & results",
        "4 › Wiki - Full documentation",
        "---",
        "5 › Uninstall Winrift",
        "---",
        "6 › Back to main menu"
    ) -Actions @{
        "1" = { Start-Process "https://github.com/emylfy/winrift/blob/main/docs/tweaks_guide.md" }
        "2" = { Start-Process "https://github.com/emylfy/winrift/blob/main/docs/autounattend_guide.md" }
        "3" = { Start-Process "https://github.com/emylfy/winrift/blob/main/docs/tests.md" }
        "4" = { Start-Process "https://github.com/emylfy/Winrift/wiki" }
        "5" = {
            $confirm = Show-InteractiveMenu -Title "Uninstall Winrift" -HideKeys -Items @(
                "This will remove:", "  Start Menu shortcut", "  Data directory", "  Drift check task", "---", "Y › Uninstall", "N › Cancel"
            )
            if ($confirm -eq "Y") {
                & "$script:Root\scripts\uninstall.ps1"
                Wait-ForUser
                exit 0
            }
        }
    } -ExitKey "6"
}

function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Winrift v$script:AppVersion"
    Get-UpdateCheckResult

    $ic = $script:MenuIcons
    $menuItems = @(
        "1 › $($ic.audit)System Audit",
        "2 › $($ic.tweaks)System Tweaks",
        "3 › $($ic.security)Security & Privacy",
        "4 › $($ic.drivers)Drivers",
        "5 › $($ic.benchmark)Benchmark",
        "--- ---",
        "6 › $($ic.bundles)App Bundles",
        "7 › $($ic.customize)Customize",
        "8 › $($ic.iso)ISO Builder",
        "--- ---",
        "9 › Community Tools",
        "0 › Docs & Guides"
    )
    # Pause background stats sampling while a sub-module is active, resume on return.
    $pauseStats = { $script:SysStats.Active = $false }
    $resumeStats = { $script:SysStats.Active = $true }
    $actions = @{
        "1" = { & $pauseStats; Invoke-Module "$script:Root\modules\system\Audit.Menu.ps1"; Start-MenuStateCheck; & $resumeStats }
        "2" = { & $pauseStats; Invoke-Module "$script:Root\modules\system\Tweaks.ps1"; Start-MenuStateCheck; & $resumeStats }
        "3" = { & $pauseStats; Invoke-Module "$script:Root\modules\security\SecurityMenu.ps1"; Start-MenuStateCheck; & $resumeStats }
        "4" = { & $pauseStats; Invoke-Module "$script:Root\modules\drivers\Drivers.ps1"; & $resumeStats }
        "5" = { & $pauseStats; Invoke-Module "$script:Root\modules\system\Benchmark.ps1"; Start-MenuStateCheck; & $resumeStats }
        "6" = { & $pauseStats; Invoke-Module "$script:Root\modules\unigetui\UniGetUI.ps1" -UserProcess; & $resumeStats }
        "7" = { & $pauseStats; Invoke-Module "$script:Root\modules\customize\Customize.Menu.ps1" -UserProcess; & $resumeStats }
        "8" = { & $pauseStats; Invoke-Module "$script:Root\modules\iso\ISOBuilder.ps1"; & $resumeStats }
        "9" = { & $pauseStats; Show-CommunityToolsMenu; & $resumeStats }
        "0" = { & $pauseStats; Show-DocsMenu; & $resumeStats }
    }

    $script:MenuDescriptions = Build-MenuDescriptions
    $script:SysStats.Active = $true

    $titleSuffix = {
        Get-MenuStateResult
        if ($script:MenuStateUpdated) {
            $script:MenuStateUpdated = $false
            $newDesc = Build-MenuDescriptions
            foreach ($k in $newDesc.Keys) { $script:MenuDescriptions[$k] = $newDesc[$k] }
        }
        $s = $script:SysStats
        ($s.CPU -ne '...') ? "$($s.CPU) CPU  $($s.RAM) RAM  $($s.Procs) procs" : $null
    }

    if ($script:UpdateAvailable) {
        $menuItems += "---"
        $menuItems += "U › $Green Update available: v$($script:UpdateAvailable)$Reset"
        $actions["U"] = { Invoke-SelfUpdate -Version $script:UpdateAvailable }
    }

    Invoke-MenuLoop -Title "Winrift v$script:AppVersion" -Items $menuItems -Actions $actions -Descriptions $script:MenuDescriptions -SplitAt 26 -TitleSuffix $titleSuffix -HideKeys
}

    Show-MainMenu
} catch {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Red
    Write-Host " FATAL: Winrift startup failed" -ForegroundColor Red
    Write-Host "================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error:    $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Type:     $($_.Exception.GetType().FullName)" -ForegroundColor DarkGray
    if ($_.InvocationInfo) {
        Write-Host "At:       $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor DarkGray
        Write-Host "Line:     $($_.InvocationInfo.Line.Trim())" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    Write-Host ""
    if ($script:StartupLogStarted) {
        Write-Host "Full log: $script:StartupLog" -ForegroundColor Cyan
        Write-Host ""
    }
    $null = Read-Host "Press Enter to exit"
    exit 1
} finally {
    if ($script:UpdateCheckJob) {
        try { Remove-Job $script:UpdateCheckJob -Force -ErrorAction SilentlyContinue } catch { $null = $_ }
    }
    if ($script:MenuStateJob) {
        try { Remove-Job $script:MenuStateJob -Force -ErrorAction SilentlyContinue } catch { $null = $_ }
    }
    if ($script:StatsJob) {
        try { Stop-Job $script:StatsJob -ErrorAction SilentlyContinue; Remove-Job $script:StatsJob -Force -ErrorAction SilentlyContinue } catch { $null = $_ }
    }
    if ($script:StartupLogStarted) {
        try { Stop-Transcript | Out-Null } catch { $null = $_ }
    }
}

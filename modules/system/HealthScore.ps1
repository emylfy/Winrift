if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    . "$PSScriptRoot\..\..\scripts\Common.ps1"
}
# Get-PerformanceSnapshot is provided by Benchmark.ps1 which dot-sources this file

$_healthBase = $env:USERPROFILE
if (-not $_healthBase) { $_healthBase = $env:HOME }
if (-not $_healthBase) { $_healthBase = [System.IO.Path]::GetTempPath() }
$script:HealthDir = Join-Path $_healthBase "Winrift\health"

# --- Scoring Engine ---

function Get-ThresholdScore {
    param(
        [double]$Value,
        [array]$Bands  # @( @{ max=25; score=100 }, @{ max=50; score=80 }, ... ) ascending by max
    )
    if ($Bands.Count -eq 0) { return 50 }

    # Below first band
    if ($Value -le $Bands[0].max) { return $Bands[0].score }

    # Above last band
    if ($Value -gt $Bands[-1].max) { return $Bands[-1].score }

    # Interpolate between adjacent bands
    for ($i = 1; $i -lt $Bands.Count; $i++) {
        if ($Value -le $Bands[$i].max) {
            $lo = $Bands[$i - 1]
            $hi = $Bands[$i]
            $range = $hi.max - $lo.max
            if ($range -eq 0) { return $hi.score }
            $ratio = ($Value - $lo.max) / $range
            return [int][math]::Round($lo.score + ($hi.score - $lo.score) * $ratio)
        }
    }
    return $Bands[-1].score
}

function Format-ScoreBar {
    param([int]$Score, [int]$Width = 11)
    $clamped = [math]::Max(0, [math]::Min(100, $Score))
    $filled = [math]::Round(($clamped / 100) * $Width)
    $empty = $Width - $filled
    return ([string][char]0x2588) * $filled + ([string][char]0x2591) * $empty
}

# --- Category Scorers ---

function Get-LatencyScore {
    param([hashtable]$Metrics)
    $dpcBands = @(
        @{ max = 25;   score = 100 }, @{ max = 50;   score = 80 },
        @{ max = 100;  score = 60 },  @{ max = 500;  score = 40 },
        @{ max = 2000; score = 20 },  @{ max = 10000; score = 5 }
    )
    $csBands = @(
        @{ max = 9000;  score = 100 }, @{ max = 15000; score = 80 },
        @{ max = 30000; score = 60 },  @{ max = 60000; score = 40 },
        @{ max = 120000; score = 20 }
    )
    $intBands = @(
        @{ max = 5000;  score = 100 }, @{ max = 10000; score = 80 },
        @{ max = 25000; score = 60 },  @{ max = 50000; score = 40 },
        @{ max = 100000; score = 20 }
    )

    $dpcScore = Get-ThresholdScore -Value $Metrics.dpcRate -Bands $dpcBands
    $csScore  = Get-ThresholdScore -Value $Metrics.contextSwitches -Bands $csBands
    $intScore = Get-ThresholdScore -Value $Metrics.interrupts -Bands $intBands

    $score = [int][math]::Round($dpcScore * 0.5 + $csScore * 0.3 + $intScore * 0.2)

    $detail = "DPC $($Metrics.dpcRate)/s"
    if ($score -ge 80) { $detail += " - excellent" }
    elseif ($score -ge 50) { $detail += " - moderate" }
    else { $detail += " - high" }

    return @{
        name = "Latency"; score = $score; detail = $detail
        breakdown = @{
            dpcRate         = @{ value = $Metrics.dpcRate; score = $dpcScore }
            contextSwitches = @{ value = $Metrics.contextSwitches; score = $csScore }
            interrupts      = @{ value = $Metrics.interrupts; score = $intScore }
        }
    }
}

function Get-MemoryScore {
    param([hashtable]$Metrics)
    $ramPct = if ($Metrics.ramTotalMB -gt 0) { ($Metrics.ramUsedMB / $Metrics.ramTotalMB) * 100 } else { 50 }
    $commitRatio = if ($Metrics.ramTotalMB -gt 0) { $Metrics.committedGB / ($Metrics.ramTotalMB / 1024) } else { 0.5 }

    $ramBands = @(
        @{ max = 20; score = 100 }, @{ max = 35; score = 85 },
        @{ max = 50; score = 65 },  @{ max = 70; score = 40 },
        @{ max = 85; score = 20 },  @{ max = 100; score = 5 }
    )
    $commitBands = @(
        @{ max = 0.3; score = 100 }, @{ max = 0.5; score = 80 },
        @{ max = 0.75; score = 60 }, @{ max = 1.0; score = 40 },
        @{ max = 2.0; score = 20 }
    )
    $pfBands = @(
        @{ max = 500;   score = 100 }, @{ max = 2000;  score = 80 },
        @{ max = 5000;  score = 60 },  @{ max = 15000; score = 40 },
        @{ max = 50000; score = 20 }
    )

    $ramScore    = Get-ThresholdScore -Value $ramPct -Bands $ramBands
    $commitScore = Get-ThresholdScore -Value $commitRatio -Bands $commitBands
    $pfScore     = Get-ThresholdScore -Value $Metrics.pageFaults -Bands $pfBands

    $score = [int][math]::Round($ramScore * 0.4 + $commitScore * 0.4 + $pfScore * 0.2)
    $detail = "$([math]::Round($Metrics.committedGB, 1))GB committed"
    if ($score -lt 50) { $detail += " - high" }

    return @{
        name = "Memory"; score = $score; detail = $detail
        breakdown = @{
            ramUsagePercent = @{ value = [math]::Round($ramPct, 1); score = $ramScore }
            committedRatio  = @{ value = [math]::Round($commitRatio, 2); score = $commitScore }
            pageFaults      = @{ value = $Metrics.pageFaults; score = $pfScore }
        }
    }
}

function Get-ProcessBloatScore {
    param([hashtable]$Metrics)
    $procBands = @(
        @{ max = 80;  score = 100 }, @{ max = 100; score = 85 },
        @{ max = 140; score = 65 },  @{ max = 200; score = 40 },
        @{ max = 350; score = 20 }
    )
    $svcBands = @(
        @{ max = 120; score = 100 }, @{ max = 155; score = 80 },
        @{ max = 190; score = 60 },  @{ max = 250; score = 35 },
        @{ max = 400; score = 15 }
    )

    $procScore = Get-ThresholdScore -Value $Metrics.processCount -Bands $procBands
    $svcScore  = Get-ThresholdScore -Value $Metrics.serviceCount -Bands $svcBands

    $score = [int][math]::Round($procScore * 0.6 + $svcScore * 0.4)
    $detail = "$($Metrics.processCount) processes"

    return @{
        name = "Process Bloat"; score = $score; detail = $detail
        breakdown = @{
            processCount = @{ value = $Metrics.processCount; score = $procScore }
            serviceCount = @{ value = $Metrics.serviceCount; score = $svcScore }
        }
    }
}

function Get-StartupScore {
    param([hashtable]$Metrics)
    $appBands = @(
        @{ max = 3;  score = 100 }, @{ max = 8;  score = 80 },
        @{ max = 15; score = 55 },  @{ max = 25; score = 30 },
        @{ max = 50; score = 10 }
    )
    $taskBands = @(
        @{ max = 30;  score = 100 }, @{ max = 50;  score = 75 },
        @{ max = 80;  score = 50 },  @{ max = 120; score = 30 },
        @{ max = 200; score = 10 }
    )

    $appScore  = Get-ThresholdScore -Value $Metrics.startupApps -Bands $appBands
    $taskScore = Get-ThresholdScore -Value $Metrics.scheduledTasks -Bands $taskBands

    $score = [int][math]::Round($appScore * 0.6 + $taskScore * 0.4)
    $detail = "$($Metrics.startupApps) startup apps"

    return @{
        name = "Startup"; score = $score; detail = $detail
        breakdown = @{
            startupApps    = @{ value = $Metrics.startupApps; score = $appScore }
            scheduledTasks = @{ value = $Metrics.scheduledTasks; score = $taskScore }
        }
    }
}

function Get-PrivacyScore {
    param([hashtable]$HealthData)
    $p = $HealthData.privacy
    $score = 100
    $issues = @()

    if ($p.telemetryLevel -ne 0)   { $score -= 25; $issues += "telemetry active" }
    if ($p.diagnosticData -ne 0)   { $score -= 15 }
    if ($p.copilotPresent)         { $score -= 20; $issues += "Copilot present" }
    if (-not $p.recallDisabled)    { $score -= 15; $issues += "Recall active" }
    if ($p.activityHistory -ne 0)  { $score -= 10 }
    if ($p.advertisingId -ne 0)    { $score -= 15 }

    $score = [math]::Max(0, $score)
    $detail = if ($issues.Count -gt 0) { $issues -join ", " } else { "all private" }

    return @{
        name = "Privacy"; score = $score; detail = $detail
        breakdown = @{
            telemetryLevel  = @{ value = $p.telemetryLevel; score = $(if ($p.telemetryLevel -eq 0) { 25 } else { 0 }) }
            copilotPresent  = @{ value = $p.copilotPresent; score = $(if (-not $p.copilotPresent) { 20 } else { 0 }) }
            recallDisabled  = @{ value = $p.recallDisabled; score = $(if ($p.recallDisabled) { 15 } else { 0 }) }
            advertisingId   = @{ value = $p.advertisingId; score = $(if ($p.advertisingId -eq 0) { 15 } else { 0 }) }
        }
    }
}

function Get-StorageScore {
    param([hashtable]$HealthData)
    $s = $HealthData.storage
    $score = 0
    $details = @()

    if ($s.hasSSD)               { $score += 30 }
    if ($s.hasNVMe)              { $score += 20; $details += "NVMe detected" }
    elseif ($s.hasSSD)           { $details += "SSD detected" }
    else                         { $details += "HDD only" }
    if ($s.trimEnabled)          { $score += 25; $details += "TRIM on" }
    if ($s.prefetcherDisabled)   { $score += 15 }
    if ($s.lastAccessDisabled)   { $score += 10 }

    $detail = $details -join ", "

    return @{
        name = "Storage"; score = $score; detail = $detail
        breakdown = @{
            hasSSD              = @{ value = $s.hasSSD; score = $(if ($s.hasSSD) { 30 } else { 0 }) }
            hasNVMe             = @{ value = $s.hasNVMe; score = $(if ($s.hasNVMe) { 20 } else { 0 }) }
            trimEnabled         = @{ value = $s.trimEnabled; score = $(if ($s.trimEnabled) { 25 } else { 0 }) }
            prefetcherDisabled  = @{ value = $s.prefetcherDisabled; score = $(if ($s.prefetcherDisabled) { 15 } else { 0 }) }
            lastAccessDisabled  = @{ value = $s.lastAccessDisabled; score = $(if ($s.lastAccessDisabled) { 10 } else { 0 }) }
        }
    }
}

function Get-NetworkScore {
    param([hashtable]$HealthData)
    $n = $HealthData.network
    $score = 0
    $details = @()

    if ($n.throttlingDisabled)  { $score += 40; $details += "throttling disabled" }
    if ($n.noLazyMode)         { $score += 25 }
    if ($n.nagleDisabled)      { $score += 20; $details += "Nagle off" }
    if ($n.tcpAutoTuning)      { $score += 15 }

    $detail = if ($details.Count -gt 0) { $details -join ", " } else { "default config" }

    return @{
        name = "Network"; score = $score; detail = $detail
        breakdown = @{
            throttlingDisabled = @{ value = $n.throttlingDisabled; score = $(if ($n.throttlingDisabled) { 40 } else { 0 }) }
            noLazyMode         = @{ value = $n.noLazyMode; score = $(if ($n.noLazyMode) { 25 } else { 0 }) }
            nagleDisabled      = @{ value = $n.nagleDisabled; score = $(if ($n.nagleDisabled) { 20 } else { 0 }) }
            tcpAutoTuning      = @{ value = $n.tcpAutoTuning; score = $(if ($n.tcpAutoTuning) { 15 } else { 0 }) }
        }
    }
}

# --- Data Collectors ---

function Get-SystemHealthData {
    # Privacy checks (registry reads)
    $telemetryLevel = 3  # default: Full
    try {
        $val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue).AllowTelemetry
        if ($null -ne $val) { $telemetryLevel = $val }
    } catch {}

    $diagnosticData = 1
    try {
        $val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue).AllowTelemetry
        if ($null -ne $val) { $diagnosticData = $val }
    } catch {}

    $copilotPresent = $false
    try {
        $copilotPresent = ($null -ne (Get-AppxPackage -Name '*Copilot*' -ErrorAction SilentlyContinue))
    } catch {}

    $recallDisabled = $false
    try {
        $val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -ErrorAction SilentlyContinue).DisableAIDataAnalysis
        if ($val -eq 1) { $recallDisabled = $true }
    } catch {}

    $activityHistory = 1
    try {
        $val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -ErrorAction SilentlyContinue).EnableActivityFeed
        if ($null -ne $val) { $activityHistory = $val }
    } catch {}

    $advertisingId = 1
    try {
        $val = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
        if ($null -ne $val) { $advertisingId = $val }
    } catch {}

    # Storage checks
    $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    $hasSSD  = ($disks | Where-Object { $_.MediaType -eq 'SSD' -or $_.BusType -eq 'NVMe' } | Measure-Object).Count -gt 0
    $hasNVMe = ($disks | Where-Object { $_.BusType -eq 'NVMe' } | Measure-Object).Count -gt 0

    $trimEnabled = $false
    try {
        $trimOutput = & fsutil behavior query DisableDeleteNotify 2>&1
        $trimEnabled = ($trimOutput | Out-String) -match '= 0'
    } catch {}

    $prefetcherDisabled = $false
    try {
        $val = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -ErrorAction SilentlyContinue).EnablePrefetcher
        if ($val -eq 0) { $prefetcherDisabled = $true }
    } catch {}

    $lastAccessDisabled = $false
    try {
        $laOutput = & fsutil behavior query disablelastaccess 2>&1
        $lastAccessDisabled = ($laOutput | Out-String) -match '= 1'
    } catch {}

    # Network checks
    $throttlingDisabled = $false
    try {
        $val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -ErrorAction SilentlyContinue).NetworkThrottlingIndex
        if ($val -eq 4294967295 -or $val -eq -1) { $throttlingDisabled = $true }
    } catch {}

    $noLazyMode = $false
    try {
        $val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NoLazyMode" -ErrorAction SilentlyContinue).NoLazyMode
        if ($val -eq 1) { $noLazyMode = $true }
    } catch {}

    $nagleDisabled = $false
    try {
        $interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
        foreach ($iface in $interfaces) {
            $ack = (Get-ItemProperty -Path $iface.PSPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue).TcpAckFrequency
            if ($ack -eq 1) { $nagleDisabled = $true; break }
        }
    } catch {}

    $tcpAutoTuning = $false
    try {
        $tcpOutput = & netsh interface tcp show global 2>&1
        $tcpAutoTuning = ($tcpOutput | Out-String) -match 'normal'
    } catch {}

    return @{
        privacy = @{
            telemetryLevel  = $telemetryLevel
            diagnosticData  = $diagnosticData
            copilotPresent  = $copilotPresent
            recallDisabled  = $recallDisabled
            activityHistory = $activityHistory
            advertisingId   = $advertisingId
        }
        storage = @{
            hasSSD             = $hasSSD
            hasNVMe            = $hasNVMe
            trimEnabled        = $trimEnabled
            prefetcherDisabled = $prefetcherDisabled
            lastAccessDisabled = $lastAccessDisabled
        }
        network = @{
            throttlingDisabled = $throttlingDisabled
            noLazyMode         = $noLazyMode
            nagleDisabled      = $nagleDisabled
            tcpAutoTuning      = $tcpAutoTuning
        }
    }
}

# --- Aggregation ---

function Get-CategoryScores {
    param(
        [hashtable]$Metrics,
        [hashtable]$HealthData
    )
    return @(
        (Get-LatencyScore      -Metrics $Metrics),
        (Get-MemoryScore       -Metrics $Metrics),
        (Get-ProcessBloatScore -Metrics $Metrics),
        (Get-StartupScore      -Metrics $Metrics),
        (Get-PrivacyScore      -HealthData $HealthData),
        (Get-StorageScore      -HealthData $HealthData),
        (Get-NetworkScore      -HealthData $HealthData)
    )
}

function Get-CompositeScore {
    param([array]$CategoryScores)
    $weights = @{
        "Latency" = 20; "Memory" = 15; "Process Bloat" = 10; "Startup" = 10
        "Privacy" = 20; "Storage" = 10; "Network" = 15
    }
    $totalWeight = 0
    $weightedSum = 0
    foreach ($cat in $CategoryScores) {
        if ($cat.score -ge 0 -and $weights.ContainsKey($cat.name)) {
            $w = $weights[$cat.name]
            $weightedSum += $cat.score * $w
            $totalWeight += $w
        }
    }
    if ($totalWeight -eq 0) { return 0 }
    return [int][math]::Round($weightedSum / $totalWeight)
}

# --- Display ---

function Show-HealthScoreReport {
    param(
        [int]$CompositeScore,
        [array]$CategoryScores
    )

    $items = @(
        "",
        "  Winrift System Score: $CompositeScore/100",
        ""
    )

    foreach ($cat in $CategoryScores) {
        $bar = Format-ScoreBar -Score $cat.score
        $color = if ($cat.score -ge 80) { $Green } elseif ($cat.score -ge 50) { $Yellow } else { $Red }
        $scorePad = "$($cat.score)".PadLeft(3)
        $namePad = $cat.name.PadRight(15)
        $items += "  $namePad $scorePad/100  $color$bar$Reset  $($cat.detail)"
    }
    $items += ""

    Show-MenuBox -Title "System Health Score" -Items $items -Width 66
}

# --- Persistence ---

function Save-HealthScore {
    param(
        [int]$CompositeScore,
        [array]$CategoryScores,
        [hashtable]$RawMetrics,
        [hashtable]$RawHealthData
    )

    [System.IO.Directory]::CreateDirectory($script:HealthDir) | Out-Null

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $data = @{
        timestamp      = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        hostname       = $env:COMPUTERNAME
        osVersion      = if ($os) { $os.Version } else { "unknown" }
        osBuild        = if ($os) { $os.BuildNumber } else { "unknown" }
        compositeScore = $CompositeScore
        categories     = $CategoryScores
        rawMetrics     = $RawMetrics
    }

    $fileName = "score_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
    $filePath = Join-Path $script:HealthDir $fileName
    $data | ConvertTo-Json -Depth 5 | Set-Content -Path $filePath -Encoding UTF8
    Write-Log -Message "Health score saved: $filePath" -Level SUCCESS
}

# --- Entry Point ---

function Invoke-HealthScore {
    Write-Host ""
    Write-Log -Message "Running System Health Score scan..." -Level INFO
    Write-Host ""

    # Quick performance sampling (3 samples, 2s)
    $snapshot = Get-PerformanceSnapshot -Samples 3 -IntervalSeconds 2
    $metrics = $snapshot.metrics

    # Instant checks (registry, WMI)
    Write-Log -Message "Checking system configuration..." -Level INFO
    $healthData = Get-SystemHealthData

    # Score
    $categoryScores = Get-CategoryScores -Metrics $metrics -HealthData $healthData
    $compositeScore = Get-CompositeScore -CategoryScores $categoryScores

    # Display
    Show-HealthScoreReport -CompositeScore $compositeScore -CategoryScores $categoryScores

    # Save
    Save-HealthScore -CompositeScore $compositeScore -CategoryScores $categoryScores -RawMetrics $metrics -RawHealthData $healthData

    Wait-ForUser
}

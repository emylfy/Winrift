if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    . "$PSScriptRoot\..\..\scripts\Common.ps1"
}

$script:BenchmarkDir = Join-Path $env:USERPROFILE "Winrift\benchmarks"

function Get-PerformanceSnapshot {
    param(
        [int]$Samples = 10,
        [int]$IntervalSeconds = 3
    )

    Write-Log -Message "Collecting performance metrics ($Samples samples, ${IntervalSeconds}s interval)..." -Level INFO
    Write-Host ""

    # --- Instant metrics ---
    Write-Log -Message "Reading system info..." -Level INFO
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRamMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
    $freeRamMB = [math]::Round($os.FreePhysicalMemory / 1024, 0)
    $usedRamMB = $totalRamMB - $freeRamMB

    $processCount = (Get-CimInstance Win32_Process -Property Name).Count
    $serviceCount = @(Get-CimInstance Win32_Service -Filter "State='Running'" -Property Name).Count

    $startupCount = 0
    try {
        $startupCount = @(Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue).Count
    } catch { }

    $scheduledTaskCount = 0
    try {
        $scheduledTaskCount = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Ready' }).Count
    } catch { }

    $bootTime = $os.LastBootUpTime
    $uptimeMinutes = [math]::Round(((Get-Date) - $bootTime).TotalMinutes, 1)

    # --- Sampled metrics via performance counters ---
    Write-Log -Message "Sampling performance counters..." -Level INFO

    $counterMap = [ordered]@{
        '\Processor(_Total)\% Processor Time'        = 'cpuIdleLoad'
        '\Memory\Committed Bytes'                    = 'committedGB'
        '\PhysicalDisk(_Total)\Avg. Disk sec/Read'   = 'diskReadLatencyMs'
        '\PhysicalDisk(_Total)\Avg. Disk sec/Write'  = 'diskWriteLatencyMs'
        '\Processor(_Total)\DPC Rate'                = 'dpcRate'
        '\System\Context Switches/sec'               = 'contextSwitches'
        '\Processor(_Total)\Interrupts/sec'          = 'interrupts'
        '\Memory\Page Faults/sec'                    = 'pageFaults'
    }

    $counters = @($counterMap.Keys)
    $sampleData = @{}
    foreach ($key in $counterMap.Values) {
        $sampleData[$key] = [System.Collections.Generic.List[double]]::new($Samples)
    }

    # Build wildcard-to-key lookup from counter paths
    $wildcardMap = @{}
    foreach ($path in $counterMap.Keys) {
        $leaf = ($path -split '\\')[-1].ToLower()
        $wildcardMap["*$leaf"] = $counterMap[$path]
    }

    for ($i = 1; $i -le $Samples; $i++) {
        $pct = [math]::Round(($i / $Samples) * 100)
        Write-Host "`r  Sampling: $i/$Samples ($pct%)" -NoNewline

        try {
            $data = Get-Counter -Counter $counters -ErrorAction Stop

            foreach ($sample in $data.CounterSamples) {
                $sampleLeaf = ($sample.Path -split '\\')[-1].ToLower()
                foreach ($wc in $wildcardMap.Keys) {
                    if ("*$sampleLeaf" -like $wc) {
                        $sampleData[$wildcardMap[$wc]].Add($sample.CookedValue)
                        break
                    }
                }
            }
        } catch {
            Write-Log -Message "Counter sample $i failed: $($_.Exception.Message)" -Level WARNING
        }

        if ($i -lt $Samples) { Start-Sleep -Seconds $IntervalSeconds }
    }
    Write-Host ""

    $snapshot = [ordered]@{
        timestamp        = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        hostname         = $env:COMPUTERNAME
        osVersion        = $os.Version
        osBuild          = $os.BuildNumber
        samplesCollected = $Samples
        intervalSeconds  = $IntervalSeconds
        metrics          = [ordered]@{
            cpuIdleLoad        = [math]::Round(($sampleData['cpuIdleLoad']    | Measure-Object -Average).Average, 2)
            ramUsedMB          = $usedRamMB
            ramTotalMB         = $totalRamMB
            committedGB        = [math]::Round(($sampleData['committedGB']    | Measure-Object -Average).Average / 1GB, 2)
            processCount       = $processCount
            serviceCount       = $serviceCount
            startupApps        = $startupCount
            scheduledTasks     = $scheduledTaskCount
            uptimeMinutes      = $uptimeMinutes
            diskReadLatencyMs  = [math]::Round(($sampleData['diskReadLatencyMs']  | Measure-Object -Average).Average * 1000, 3)
            diskWriteLatencyMs = [math]::Round(($sampleData['diskWriteLatencyMs'] | Measure-Object -Average).Average * 1000, 3)
            dpcRate            = [math]::Round(($sampleData['dpcRate']            | Measure-Object -Average).Average, 0)
            contextSwitches    = [math]::Round(($sampleData['contextSwitches']    | Measure-Object -Average).Average, 0)
            interrupts         = [math]::Round(($sampleData['interrupts']         | Measure-Object -Average).Average, 0)
            pageFaults         = [math]::Round(($sampleData['pageFaults']         | Measure-Object -Average).Average, 0)
        }
    }

    Write-Log -Message "Snapshot collected successfully." -Level SUCCESS
    return $snapshot
}

function Save-Snapshot {
    param(
        [Parameter(Mandatory)][ValidateSet('Before','After')][string]$Phase,
        [Parameter(Mandatory)][hashtable]$Snapshot
    )

    [System.IO.Directory]::CreateDirectory($script:BenchmarkDir) | Out-Null

    $phaseLower = $Phase.ToLower()
    $copy = $Snapshot.Clone()
    $copy.phase = $phaseLower
    $fileName = "${phaseLower}_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
    $filePath = Join-Path $script:BenchmarkDir $fileName

    $copy | ConvertTo-Json -Depth 5 | Set-Content -Path $filePath -Encoding UTF8
    Write-Log -Message "Snapshot saved: $filePath" -Level SUCCESS
    return $filePath
}

function Compare-Snapshots {
    param(
        [string]$BeforeFile,
        [string]$AfterFile
    )

    if (-not $BeforeFile -or -not $AfterFile) {
        $files = Get-ChildItem -Path $script:BenchmarkDir -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime

        if (-not $BeforeFile) {
            $BeforeFile = ($files | Where-Object { $_.Name -like "before_*" } | Select-Object -Last 1).FullName
        }
        if (-not $AfterFile) {
            $AfterFile = ($files | Where-Object { $_.Name -like "after_*" } | Select-Object -Last 1).FullName
        }
    }

    if (-not $BeforeFile -or -not (Test-Path $BeforeFile)) {
        Write-Log -Message "Before snapshot not found. Run: Invoke-Benchmark -Phase Before" -Level ERROR
        return $null
    }
    if (-not $AfterFile -or -not (Test-Path $AfterFile)) {
        Write-Log -Message "After snapshot not found. Run: Invoke-Benchmark -Phase After" -Level ERROR
        return $null
    }

    $before = Get-Content $BeforeFile -Raw | ConvertFrom-Json
    $after = Get-Content $AfterFile -Raw | ConvertFrom-Json

    $metricLabels = [ordered]@{
        cpuIdleLoad        = @{ label = "CPU idle load";         unit = "%";    fmt = "{0:N1}" }
        ramUsedMB          = @{ label = "RAM usage";             unit = "MB";   fmt = "{0:N0}" }
        committedGB        = @{ label = "Committed memory";      unit = "GB";   fmt = "{0:N2}" }
        processCount       = @{ label = "Running processes";     unit = "";     fmt = "{0:N0}" }
        serviceCount       = @{ label = "Running services";      unit = "";     fmt = "{0:N0}" }
        startupApps        = @{ label = "Startup apps";          unit = "";     fmt = "{0:N0}" }
        scheduledTasks     = @{ label = "Scheduled tasks";       unit = "";     fmt = "{0:N0}" }
        diskReadLatencyMs  = @{ label = "Disk read latency";     unit = "ms";   fmt = "{0:N3}" }
        diskWriteLatencyMs = @{ label = "Disk write latency";    unit = "ms";   fmt = "{0:N3}" }
        dpcRate            = @{ label = "DPC rate";              unit = "/s";   fmt = "{0:N0}" }
        contextSwitches    = @{ label = "Context switches";      unit = "/s";   fmt = "{0:N0}" }
        interrupts         = @{ label = "Interrupts";            unit = "/s";   fmt = "{0:N0}" }
        pageFaults         = @{ label = "Page faults";           unit = "/s";   fmt = "{0:N0}" }
    }

    $results = foreach ($key in $metricLabels.Keys) {
        $bVal = $before.metrics.$key
        $aVal = $after.metrics.$key
        $meta = $metricLabels[$key]

        $delta = $aVal - $bVal
        $changePct = if ($bVal -ne 0) { [math]::Round(($delta / $bVal) * 100, 1) } else { 0 }

        [PSCustomObject]@{
            Label     = $meta.label
            Unit      = $meta.unit
            Format    = $meta.fmt
            Before    = $bVal
            After     = $aVal
            Delta     = $delta
            ChangePct = $changePct
        }
    }

    return [PSCustomObject]@{
        BeforeFile      = $BeforeFile
        AfterFile       = $AfterFile
        BeforeTimestamp  = $before.timestamp
        AfterTimestamp   = $after.timestamp
        Hostname         = $before.hostname
        Results          = $results
    }
}

function Export-BenchmarkReport {
    param(
        [Parameter(Mandatory)][PSCustomObject]$Comparison
    )

    $width = 66

    function Format-Value {
        param($Val, $Fmt, $Unit)
        $formatted = $Fmt -f $Val
        if ($Unit) { return "$formatted $Unit" } else { return $formatted }
    }

    # Single pass: build formatted rows, then render both outputs
    $formattedRows = foreach ($r in $Comparison.Results) {
        $bStr = Format-Value $r.Before $r.Format $r.Unit
        $aStr = Format-Value $r.After $r.Format $r.Unit

        if ($r.ChangePct -lt 0) {
            $changeStr = "$([char]0x25BC) $([math]::Abs($r.ChangePct))%"
        } elseif ($r.ChangePct -gt 0) {
            $changeStr = "$([char]0x25B2) $($r.ChangePct)%"
        } else {
            $changeStr = "0%"
        }

        [PSCustomObject]@{ Label = $r.Label; Before = $bStr; After = $aStr; Change = $changeStr }
    }

    # Console output via Show-MenuBox
    $headerLine = "  {0,-24} {1,10} {2,10} {3,10}" -f "Metric", "Before", "After", "Change"
    $items = @($headerLine, "---")
    foreach ($row in $formattedRows) {
        $items += "  {0,-24} {1,10} {2,10} {3,10}" -f $row.Label, $row.Before, $row.After, $row.Change
    }
    $items += "---"
    $items += "  Before: $($Comparison.BeforeTimestamp)"
    $items += "  After:  $($Comparison.AfterTimestamp)"

    Show-MenuBox -Title "Winrift Performance Report" -Items $items -Width $width

    # Markdown report
    [System.IO.Directory]::CreateDirectory($script:BenchmarkDir) | Out-Null

    $reportPath = Join-Path $script:BenchmarkDir "report_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').md"
    $md = @(
        "# Winrift Performance Report"
        ""
        "- **Host:** $($Comparison.Hostname)"
        "- **Before:** $($Comparison.BeforeTimestamp)"
        "- **After:** $($Comparison.AfterTimestamp)"
        ""
        "| Metric | Before | After | Change |"
        "| :--- | ---: | ---: | ---: |"
    )
    foreach ($row in $formattedRows) {
        $md += "| $($row.Label) | $($row.Before) | $($row.After) | $($row.Change) |"
    }

    $md -join "`n" | Set-Content -Path $reportPath -Encoding UTF8
    Write-Log -Message "Report saved: $reportPath" -Level SUCCESS
    return $reportPath
}

function Invoke-Benchmark {
    param(
        [Parameter(Mandatory)][ValidateSet('Before','After','Compare')][string]$Phase
    )

    switch ($Phase) {
        'Before' {
            Write-Log -Message "Starting BEFORE benchmark..." -Level INFO
            $snapshot = Get-PerformanceSnapshot
            $savedPath = Save-Snapshot -Phase Before -Snapshot $snapshot
            Write-Host ""
            Write-Log -Message "Baseline recorded. Now apply tweaks, reboot, then run Benchmark (After)." -Level INFO
            Write-Host ""
            Write-Host "  Saved to: $savedPath"
            Write-Host ""
            Read-Host "  Press Enter to continue"
        }
        'After' {
            Write-Log -Message "Starting AFTER benchmark..." -Level INFO
            $snapshot = Get-PerformanceSnapshot
            Save-Snapshot -Phase After -Snapshot $snapshot
            Write-Host ""

            $comparison = Compare-Snapshots
            if ($comparison) {
                $reportPath = Export-BenchmarkReport -Comparison $comparison
                Write-Host ""
                Write-Host "  Report saved to: $reportPath"
                Write-Host ""
                Read-Host "  Press Enter to continue"
            }
        }
        'Compare' {
            $comparison = Compare-Snapshots
            if ($comparison) {
                $reportPath = Export-BenchmarkReport -Comparison $comparison
                Write-Host ""
                Write-Host "  Report saved to: $reportPath"
                Write-Host ""
                Read-Host "  Press Enter to continue"
            }
        }
    }
}

function Show-BenchmarkMenu {
    $Host.UI.RawUI.WindowTitle = "Winrift - Benchmark"
    Invoke-MenuLoop -Title "Benchmark - Measure, Tweak, Verify" -Items @(
        "[1] Run Benchmark (Before tweaks)",
        "[2] Run Benchmark (After tweaks)",
        "[3] View Last Report",
        "---",
        "[4] Back"
    ) -Prompt "Enter your choice (1-4)" -Actions @{
        "1" = { Invoke-Benchmark -Phase Before }
        "2" = { Invoke-Benchmark -Phase After }
        "3" = { Invoke-Benchmark -Phase Compare }
    } -ExitKey "4"
}

# Standalone entry point (skipped when dot-sourced from Tweaks.ps1)
if ($MyInvocation.InvocationName -ne '.') {
    Assert-AdminOrElevate
    Show-BenchmarkMenu
    Invoke-ReturnToMenu
}

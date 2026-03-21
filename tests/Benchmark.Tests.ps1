BeforeAll {
    . "$PSScriptRoot\..\scripts\Common.ps1"
    . "$PSScriptRoot\..\modules\system\Benchmark.ps1"
}

Describe 'Get-PerformanceSnapshot' {
    It 'is defined' {
        Get-Command Get-PerformanceSnapshot -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'has Samples and IntervalSeconds parameters' {
        $cmd = Get-Command Get-PerformanceSnapshot
        $cmd.Parameters.Keys | Should -Contain 'Samples'
        $cmd.Parameters.Keys | Should -Contain 'IntervalSeconds'
    }
}

Describe 'Save-Snapshot' {
    It 'is defined with Phase and Snapshot parameters' {
        $cmd = Get-Command Save-Snapshot -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
        $cmd.Parameters.Keys | Should -Contain 'Phase'
        $cmd.Parameters.Keys | Should -Contain 'Snapshot'
    }

    It 'Phase validates Before and After' {
        $cmd = Get-Command Save-Snapshot
        $attrs = $cmd.Parameters['Phase'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
        $attrs.ValidValues | Should -Contain 'Before'
        $attrs.ValidValues | Should -Contain 'After'
    }
}

Describe 'Compare-Snapshots' {
    It 'is defined' {
        Get-Command Compare-Snapshots -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'returns comparison from two JSON files' {
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester_bench_$(Get-Random)"
        New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null

        $beforeData = @{
            timestamp = '2026-01-01T10:00:00'
            hostname  = 'TEST-PC'
            phase     = 'before'
            metrics   = @{
                cpuIdleLoad        = 5.0
                ramUsedMB          = 3000
                ramTotalMB         = 16000
                committedGB        = 4.5
                processCount       = 150
                serviceCount       = 90
                startupApps        = 12
                scheduledTasks     = 45
                uptimeMinutes      = 120
                diskReadLatencyMs  = 0.8
                diskWriteLatencyMs = 1.2
                dpcRate            = 1200
                contextSwitches    = 15000
                interrupts         = 8000
                pageFaults         = 5000
            }
        }

        $afterData = @{
            timestamp = '2026-01-01T11:00:00'
            hostname  = 'TEST-PC'
            phase     = 'after'
            metrics   = @{
                cpuIdleLoad        = 2.0
                ramUsedMB          = 2200
                ramTotalMB         = 16000
                committedGB        = 3.2
                processCount       = 100
                serviceCount       = 72
                startupApps        = 8
                scheduledTasks     = 38
                uptimeMinutes      = 125
                diskReadLatencyMs  = 0.5
                diskWriteLatencyMs = 0.9
                dpcRate            = 800
                contextSwitches    = 11000
                interrupts         = 6000
                pageFaults         = 3000
            }
        }

        $beforeFile = Join-Path $tmpDir "before_test.json"
        $afterFile = Join-Path $tmpDir "after_test.json"

        $beforeData | ConvertTo-Json -Depth 5 | Set-Content $beforeFile -Encoding UTF8
        $afterData | ConvertTo-Json -Depth 5 | Set-Content $afterFile -Encoding UTF8

        try {
            $result = Compare-Snapshots -BeforeFile $beforeFile -AfterFile $afterFile
            $result | Should -Not -BeNullOrEmpty
            $result.Results | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -BeGreaterThan 0

            $cpuResult = $result.Results | Where-Object { $_.Label -eq 'CPU idle load' }
            $cpuResult.Before | Should -Be 5.0
            $cpuResult.After | Should -Be 2.0
            $cpuResult.ChangePct | Should -BeLessThan 0

            $ramResult = $result.Results | Where-Object { $_.Label -eq 'RAM usage' }
            $ramResult.Before | Should -Be 3000
            $ramResult.After | Should -Be 2200
        } finally {
            Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Export-BenchmarkReport' {
    It 'is defined with Comparison parameter' {
        $cmd = Get-Command Export-BenchmarkReport -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
        $cmd.Parameters.Keys | Should -Contain 'Comparison'
    }
}

Describe 'Invoke-Benchmark' {
    It 'is defined with Phase parameter' {
        $cmd = Get-Command Invoke-Benchmark -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
        $cmd.Parameters.Keys | Should -Contain 'Phase'
    }

    It 'Phase validates Before, After, and Compare' {
        $cmd = Get-Command Invoke-Benchmark
        $attrs = $cmd.Parameters['Phase'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
        $attrs.ValidValues | Should -Contain 'Before'
        $attrs.ValidValues | Should -Contain 'After'
        $attrs.ValidValues | Should -Contain 'Compare'
    }
}

Describe 'Show-BenchmarkMenu' {
    It 'is defined' {
        Get-Command Show-BenchmarkMenu -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/Common.ps1')
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/system/HealthScore.ps1')
}

Describe 'HealthScore.ps1 function exports' {
    BeforeAll {
        $filePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/system/HealthScore.ps1'
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $filePath, [ref]$null, [ref]$null
        )
        $functionDefs = $ast.FindAll(
            { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true
        )
        $script:functionNames = $functionDefs | ForEach-Object { $_.Name }
    }

    It 'defines function <_>' -ForEach @(
        'Get-ThresholdScore', 'Format-ScoreBar',
        'Get-LatencyScore', 'Get-MemoryScore', 'Get-ProcessBloatScore',
        'Get-StartupScore', 'Get-PrivacyScore', 'Get-StorageScore', 'Get-NetworkScore',
        'Get-SystemHealthData', 'Get-CategoryScores', 'Get-CompositeScore',
        'Show-HealthScoreReport',
        'Save-HealthScore', 'Invoke-HealthScore'
    ) {
        $script:functionNames | Should -Contain $_
    }
}

Describe 'Get-ThresholdScore' {
    It 'returns top score below first band' {
        $bands = @( @{ max = 25; score = 100 }, @{ max = 50; score = 80 } )
        Get-ThresholdScore -Value 10 -Bands $bands | Should -Be 100
    }

    It 'returns bottom score above last band' {
        $bands = @( @{ max = 25; score = 100 }, @{ max = 50; score = 80 }, @{ max = 100; score = 20 } )
        Get-ThresholdScore -Value 200 -Bands $bands | Should -Be 20
    }

    It 'interpolates between bands' {
        $bands = @( @{ max = 0; score = 100 }, @{ max = 100; score = 0 } )
        $result = Get-ThresholdScore -Value 50 -Bands $bands
        $result | Should -Be 50
    }
}

Describe 'Format-ScoreBar' {
    It 'returns correct length' {
        (Format-ScoreBar -Score 50).Length | Should -Be 11
    }

    It 'all filled at 100' {
        $bar = Format-ScoreBar -Score 100
        $bar | Should -Not -Match ([regex]::Escape([string][char]0x2591))
    }

    It 'all empty at 0' {
        $bar = Format-ScoreBar -Score 0
        $bar | Should -Not -Match ([regex]::Escape([string][char]0x2588))
    }

    It 'clamps values above 100' {
        (Format-ScoreBar -Score 150).Length | Should -Be 11
    }
}

Describe 'Get-LatencyScore' {
    It 'returns high score for excellent metrics' {
        $metrics = @{ dpcRate = 15; contextSwitches = 7000; interrupts = 3000 }
        $result = Get-LatencyScore -Metrics $metrics
        $result.score | Should -BeGreaterOrEqual 90
        $result.name | Should -Be "Latency"
    }

    It 'returns low score for poor metrics' {
        $metrics = @{ dpcRate = 1500; contextSwitches = 50000; interrupts = 40000 }
        $result = Get-LatencyScore -Metrics $metrics
        $result.score | Should -BeLessThan 40
    }
}

Describe 'Get-MemoryScore' {
    It 'returns high score for low usage' {
        $metrics = @{ ramUsedMB = 2000; ramTotalMB = 16000; committedGB = 3.0; pageFaults = 500 }
        $result = Get-MemoryScore -Metrics $metrics
        $result.score | Should -BeGreaterOrEqual 75
    }

    It 'returns low score for high usage' {
        $metrics = @{ ramUsedMB = 14000; ramTotalMB = 16000; committedGB = 18.0; pageFaults = 20000 }
        $result = Get-MemoryScore -Metrics $metrics
        $result.score | Should -BeLessThan 30
    }
}

Describe 'Get-PrivacyScore' {
    It 'returns 100 when all settings are optimized' {
        $data = @{ privacy = @{
            telemetryLevel = 0; diagnosticData = 0; copilotPresent = $false
            recallDisabled = $true; activityHistory = 0; advertisingId = 0
        }}
        $result = Get-PrivacyScore -HealthData $data
        $result.score | Should -Be 100
    }

    It 'deducts points for active telemetry' {
        $data = @{ privacy = @{
            telemetryLevel = 3; diagnosticData = 0; copilotPresent = $false
            recallDisabled = $true; activityHistory = 0; advertisingId = 0
        }}
        $result = Get-PrivacyScore -HealthData $data
        $result.score | Should -Be 75
    }

    It 'deducts points for Copilot' {
        $data = @{ privacy = @{
            telemetryLevel = 0; diagnosticData = 0; copilotPresent = $true
            recallDisabled = $true; activityHistory = 0; advertisingId = 0
        }}
        $result = Get-PrivacyScore -HealthData $data
        $result.score | Should -Be 80
    }
}

Describe 'Get-CompositeScore' {
    It 'returns 100 when all categories are 100' {
        $scores = @(
            @{ name = 'Latency'; score = 100 }, @{ name = 'Memory'; score = 100 },
            @{ name = 'Process Bloat'; score = 100 }, @{ name = 'Startup'; score = 100 },
            @{ name = 'Privacy'; score = 100 }, @{ name = 'Storage'; score = 100 },
            @{ name = 'Network'; score = 100 }
        )
        Get-CompositeScore -CategoryScores $scores | Should -Be 100
    }

    It 'returns 0 when all categories are 0' {
        $scores = @(
            @{ name = 'Latency'; score = 0 }, @{ name = 'Memory'; score = 0 },
            @{ name = 'Process Bloat'; score = 0 }, @{ name = 'Startup'; score = 0 },
            @{ name = 'Privacy'; score = 0 }, @{ name = 'Storage'; score = 0 },
            @{ name = 'Network'; score = 0 }
        )
        Get-CompositeScore -CategoryScores $scores | Should -Be 0
    }

    It 'applies correct weighting' {
        # Privacy (weight 20) = 100, everything else = 0
        $scores = @(
            @{ name = 'Latency'; score = 0 }, @{ name = 'Memory'; score = 0 },
            @{ name = 'Process Bloat'; score = 0 }, @{ name = 'Startup'; score = 0 },
            @{ name = 'Privacy'; score = 100 }, @{ name = 'Storage'; score = 0 },
            @{ name = 'Network'; score = 0 }
        )
        Get-CompositeScore -CategoryScores $scores | Should -Be 20
    }
}

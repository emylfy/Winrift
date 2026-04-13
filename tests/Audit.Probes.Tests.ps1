BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/system/Audit.Probes.ps1')

    # Pester 5 cannot Mock a command that doesn't exist in the current session.
    # On non-Windows pwsh, Get-Service / Get-ItemProperty / Get-AppxPackage are
    # absent — provide thin stubs so mocks bind. On Windows these stubs are
    # shadowed by the real cmdlets and never called directly.
    if (-not (Get-Command Get-Service -ErrorAction SilentlyContinue)) {
        function Get-Service { param($Name) throw "stub" }
    }
    if (-not (Get-Command Get-ItemProperty -ErrorAction SilentlyContinue)) {
        function Get-ItemProperty { param($Path, $Name) throw "stub" }
    }
}

Describe 'Test-RegistryValueEquals' {
    It 'returns found=true when current value matches expected' {
        Mock _Get-RegistryValueOrDefault { 1 }
        $r = Test-RegistryValueEquals -path 'HKLM:\foo' -name 'Bar' -expected 1
        $r.found | Should -BeTrue
    }
    It 'returns found=false when current value differs from expected' {
        Mock _Get-RegistryValueOrDefault { 2 }
        $r = Test-RegistryValueEquals -path 'HKLM:\foo' -name 'Bar' -expected 1
        $r.found | Should -BeFalse
    }
    It 'uses treat_missing_as when value is null' {
        Mock _Get-RegistryValueOrDefault { 'fallback' }
        $r = Test-RegistryValueEquals -path 'HKLM:\foo' -name 'Bar' -expected 'fallback' -treat_missing_as 'fallback'
        $r.found | Should -BeTrue
    }
}

Describe 'Test-RegistryValueNotEquals' {
    It 'returns found=true when current does not match expected' {
        Mock _Get-RegistryValueOrDefault { 0 }
        $r = Test-RegistryValueNotEquals -path 'HKLM:\foo' -name 'Bar' -expected 1
        $r.found | Should -BeTrue
    }
    It 'returns found=false when current matches expected' {
        Mock _Get-RegistryValueOrDefault { 1 }
        $r = Test-RegistryValueNotEquals -path 'HKLM:\foo' -name 'Bar' -expected 1
        $r.found | Should -BeFalse
    }
}

Describe 'Test-RegistryValueGreaterThan' {
    It 'returns found=true when current > threshold' {
        Mock _Get-RegistryValueOrDefault { 5 }
        $r = Test-RegistryValueGreaterThan -path 'HKLM:\foo' -name 'Bar' -threshold 3
        $r.found | Should -BeTrue
    }
    It 'returns found=false when current <= threshold' {
        Mock _Get-RegistryValueOrDefault { 3 }
        $r = Test-RegistryValueGreaterThan -path 'HKLM:\foo' -name 'Bar' -threshold 3
        $r.found | Should -BeFalse
    }
    It 'returns found=false when current is non-numeric' {
        Mock _Get-RegistryValueOrDefault { 'not-a-number' }
        $r = Test-RegistryValueGreaterThan -path 'HKLM:\foo' -name 'Bar' -threshold 3
        $r.found | Should -BeFalse
    }
}

Describe 'Test-ServiceRunning' {
    It 'returns found=true when service is Running' {
        Mock Get-Service { [PSCustomObject]@{ Status = 'Running' } }
        $r = Test-ServiceRunning -name 'Foo'
        $r.found | Should -BeTrue
    }
    It 'returns found=false when service is Stopped' {
        Mock Get-Service { [PSCustomObject]@{ Status = 'Stopped' } }
        $r = Test-ServiceRunning -name 'Foo'
        $r.found | Should -BeFalse
    }
    It 'returns found=false when service does not exist' {
        Mock Get-Service { throw 'not found' }
        $r = Test-ServiceRunning -name 'Foo'
        $r.found | Should -BeFalse
        $r.evidence | Should -Match 'not installed'
    }
}

Describe 'Test-RegistryValueExists' {
    It 'returns found=true when value exists' {
        Mock Get-ItemProperty { [PSCustomObject]@{ Bar = 'value' } }
        $r = Test-RegistryValueExists -path 'HKLM:\foo' -name 'Bar'
        $r.found | Should -BeTrue
    }
    It 'returns found=false when value missing' {
        Mock Get-ItemProperty { throw 'not found' }
        $r = Test-RegistryValueExists -path 'HKLM:\foo' -name 'Bar'
        $r.found | Should -BeFalse
    }
}

Describe 'Test-ProcessRSSExceeds with dynamic_cost' {
    It 'returns dynamic_cost.ram_mb when process found' {
        if (-not (Get-Command Get-Process -ErrorAction SilentlyContinue)) { return }
        Mock Get-Process { @([PSCustomObject]@{ WorkingSet64 = 100MB }) } -ParameterFilter { $Name -eq 'fakeproc' }
        $r = Test-ProcessRSSExceeds -name_pattern 'fakeproc' -threshold_mb 50
        $r.found | Should -BeTrue
        $r.ContainsKey('dynamic_cost') | Should -BeTrue
        $r.dynamic_cost.ram_mb | Should -Be 100
    }
}

Describe 'Get-RegistryRunCount' {
    It 'returns dynamic_cost.startup_count' {
        if (-not (Get-Command Get-ItemProperty -ErrorAction SilentlyContinue)) {
            function Get-ItemProperty { param($Path) throw "stub" }
        }
        Mock Test-Path { $true }
        Mock Get-ItemProperty {
            [PSCustomObject]@{ Discord = 'x'; Steam = 'x'; OneDrive = 'x'; Spotify = 'x' }
        }
        $r = Get-RegistryRunCount -path 'HKCU:\fake' -threshold 3
        $r.found | Should -BeTrue
        $r.dynamic_cost.startup_count | Should -BeGreaterThan 0
    }
    It 'returns found=false when count <= threshold' {
        Mock Test-Path { $true }
        Mock Get-ItemProperty {
            [PSCustomObject]@{ OnlyOne = 'x' }
        }
        $r = Get-RegistryRunCount -path 'HKCU:\fake' -threshold 5
        $r.found | Should -BeFalse
    }
}

Describe 'Probes return shape' {
    It 'all probes return a hashtable with found and evidence keys' {
        Mock _Get-RegistryValueOrDefault { 0 }
        $probes = @(
            { Test-RegistryValueEquals -path 'X' -name 'Y' -expected 0 }
            { Test-RegistryValueNotEquals -path 'X' -name 'Y' -expected 1 }
            { Test-RegistryValueGreaterThan -path 'X' -name 'Y' -threshold -1 }
        )
        foreach ($p in $probes) {
            $r = & $p
            $r | Should -BeOfType [hashtable]
            $r.ContainsKey('found') | Should -BeTrue
            $r.ContainsKey('evidence') | Should -BeTrue
        }
    }
}

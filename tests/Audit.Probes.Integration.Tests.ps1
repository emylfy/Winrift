BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/system/Audit.Probes.ps1')
}

# Integration tests run probes against the LIVE Windows system. They assert
# the return shape and that probes don't throw — not specific values, since
# state varies between machines. Skipped on non-Windows because the underlying
# cmdlets (Get-Service, Get-AppxPackage, fsutil, powercfg, Get-DnsClientServerAddress,
# Get-MMAgent, Get-Process for some) are Windows-only.
#
# Run on Windows with: Invoke-Pester -Path tests/Audit.Probes.Integration.Tests.ps1 -Tag Integration
#
# These complement the unit tests in Audit.Probes.Tests.ps1 (which mock the
# underlying cmdlets) by exercising the real Windows code paths.

$skip = $true
if ($PSVersionTable.PSEdition -eq 'Desktop' -or $env:OS -eq 'Windows_NT') { $skip = $false }
if ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows) { $skip = $false }

Describe 'Test-RegistryValueEquals (live)' -Tag Integration -Skip:$skip {
    It 'reads a guaranteed-existing key without throwing' {
        $r = Test-RegistryValueEquals -path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
                                       -name 'CurrentBuildNumber' -expected 0
        $r | Should -BeOfType [hashtable]
        $r.ContainsKey('found') | Should -BeTrue
        $r.evidence | Should -Not -BeNullOrEmpty
    }
    It 'returns found=false for a key that does not exist' {
        $r = Test-RegistryValueEquals -path 'HKLM:\SOFTWARE\Definitely\Does\Not\Exist' `
                                       -name 'X' -expected 0
        $r.found | Should -BeFalse
    }
}

Describe 'Test-ServiceRunning (live)' -Tag Integration -Skip:$skip {
    It 'detects a known always-running service (Spooler or Themes)' {
        # Themes is a UWP service that's almost always running on consumer Windows
        $r = Test-ServiceRunning -name 'Themes'
        $r | Should -BeOfType [hashtable]
        $r.evidence | Should -Match 'Themes service'
    }
    It 'returns found=false for non-existent service' {
        $r = Test-ServiceRunning -name 'NonExistentService_xyz_999'
        $r.found | Should -BeFalse
    }
}

Describe 'Test-AppxPackageInstalled (live)' -Tag Integration -Skip:$skip {
    It 'queries Get-AppxPackage without throwing' {
        $r = Test-AppxPackageInstalled -pattern 'Microsoft.Windows.Shell*'
        $r | Should -BeOfType [hashtable]
        $r.ContainsKey('found') | Should -BeTrue
    }
}

Describe 'Test-FsutilBehavior (live)' -Tag Integration -Skip:$skip {
    It 'queries DisableDeleteNotify (TRIM) via fsutil' {
        $r = Test-FsutilBehavior -key 'DisableDeleteNotify' -expected 1
        $r | Should -BeOfType [hashtable]
        $r.evidence | Should -Match 'DisableDeleteNotify'
    }
}

Describe 'Test-ProcessRSSExceeds (live)' -Tag Integration -Skip:$skip {
    It 'measures explorer.exe RSS and returns dynamic_cost' {
        $r = Test-ProcessRSSExceeds -name_pattern 'explorer' -threshold_mb 1
        $r | Should -BeOfType [hashtable]
        $r.found | Should -BeTrue   # explorer is always > 1 MB
        $r.ContainsKey('dynamic_cost') | Should -BeTrue
        $r.dynamic_cost.ram_mb | Should -BeGreaterThan 0
    }
}

Describe 'Test-MMAgentFeature (live)' -Tag Integration -Skip:$skip {
    It 'queries Get-MMAgent without throwing' {
        $r = Test-MMAgentFeature -property 'MemoryCompression' -expected $true
        $r | Should -BeOfType [hashtable]
        $r.ContainsKey('found') | Should -BeTrue
    }
}

Describe 'Test-DnsServersFromList (live)' -Tag Integration -Skip:$skip {
    It 'queries Get-DnsClientServerAddress without throwing' {
        $r = Test-DnsServersFromList -known_good_csv '1.1.1.1,8.8.8.8'
        $r | Should -BeOfType [hashtable]
        $r.ContainsKey('found') | Should -BeTrue
    }
}

Describe 'Get-RegistryRunCount (live)' -Tag Integration -Skip:$skip {
    It 'enumerates HKCU Run key' {
        $r = Get-RegistryRunCount -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -threshold 0
        $r | Should -BeOfType [hashtable]
        $r.ContainsKey('dynamic_cost') | Should -BeTrue
        $r.dynamic_cost.startup_count | Should -BeGreaterOrEqual 0
    }
}

Describe 'Invoke-Audit (full live run)' -Tag Integration -Skip:$skip {
    BeforeAll {
        . (Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/system/Audit.Engine.ps1')
    }
    It 'runs the entire audit without throwing' {
        { @(Invoke-Audit) } | Should -Not -Throw
    }
    It 'returns at least one finding (any vanilla Windows install has issues)' {
        $results = @(Invoke-Audit)
        # Smoke check — fresh Windows nearly always trips at least Telemetry,
        # NtfsDisableLastAccessUpdate, NetworkThrottlingIndex, etc.
        $results.Count | Should -BeGreaterThan 0
    }
    It 'each result has Id/Category/Severity/Title/Evidence/Remediation' {
        $results = @(Invoke-Audit)
        foreach ($r in $results) {
            $r.Id          | Should -Not -BeNullOrEmpty
            $r.Category    | Should -Not -BeNullOrEmpty
            $r.Severity    | Should -BeIn @('critical','warning','info')
            $r.Title       | Should -Not -BeNullOrEmpty
            $r.Evidence    | Should -Not -BeNullOrEmpty
            $r.Remediation | Should -Not -BeNullOrEmpty
        }
    }
}

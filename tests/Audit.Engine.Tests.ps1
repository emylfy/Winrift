BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/system/Audit.Engine.ps1')
}

Describe 'Get-AuditFindingsPath' {
    It 'returns a path under repo config/' {
        $path = Get-AuditFindingsPath
        $path | Should -Match 'config[/\\]audit_findings\.json$'
    }
    It 'points to an existing file' {
        Test-Path (Get-AuditFindingsPath) | Should -BeTrue
    }
}

Describe 'Read-AuditFindings' {
    It 'parses the canonical findings file and returns an array' {
        $f = Read-AuditFindings
        $f | Should -Not -BeNullOrEmpty
        $f.Count | Should -BeGreaterThan 0
    }
    It 'each finding has required fields' {
        $f = Read-AuditFindings
        foreach ($entry in $f) {
            $entry.id          | Should -Not -BeNullOrEmpty
            $entry.category    | Should -Not -BeNullOrEmpty
            $entry.severity    | Should -BeIn @('critical','warning','info')
            $entry.title       | Should -Not -BeNullOrEmpty
            $entry.detect      | Should -Not -BeNullOrEmpty
            $entry.detect.probe | Should -Not -BeNullOrEmpty
            $entry.remediation | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Invoke-AuditProbe' {
    It 'returns found=false for unknown probe' {
        $detect = [PSCustomObject]@{ probe = 'No-SuchProbeExists'; args = $null }
        $r = Invoke-AuditProbe -Detect $detect
        $r.found | Should -BeFalse
        $r.evidence | Should -Match 'unknown probe'
    }
    It 'dispatches a known probe and returns its result' {
        # Define a stub probe in the current scope
        function Test-AuditStubProbe { param($x) return @{ found = $true; evidence = "stub:$x" } }
        $detect = [PSCustomObject]@{
            probe = 'Test-AuditStubProbe'
            args  = [PSCustomObject]@{ x = 'hello' }
        }
        $r = Invoke-AuditProbe -Detect $detect
        $r.found | Should -BeTrue
        $r.evidence | Should -Be 'stub:hello'
    }
    It 'catches throwing probes and returns found=false' {
        function Test-AuditThrowingProbe { throw 'kaboom' }
        $detect = [PSCustomObject]@{ probe = 'Test-AuditThrowingProbe'; args = $null }
        $r = Invoke-AuditProbe -Detect $detect
        $r.found | Should -BeFalse
        $r.evidence | Should -Match 'kaboom'
    }
}

Describe 'Invoke-Audit' {
    It 'returns an array of PSCustomObjects with expected fields' {
        $results = @(Invoke-Audit)
        # On a non-Windows host many findings won't apply but the call must succeed
        foreach ($r in $results) {
            $r.Id          | Should -Not -BeNullOrEmpty
            $r.Category    | Should -Not -BeNullOrEmpty
            $r.Severity    | Should -BeIn @('critical','warning','info')
            $r.Evidence    | Should -Not -BeNullOrEmpty
            $r.Remediation | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Audit cache' {
    BeforeAll {
        $script:origCache = $env:WINRIFT_AUDIT_CACHE_OVERRIDE
        # Use a temp dir so we don't pollute the user's real cache
        $script:tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "winrift-test-$([Guid]::NewGuid())"
        New-Item -Path $script:tmpDir -ItemType Directory -Force | Out-Null
        $env:USERPROFILE = $script:tmpDir
    }
    AfterAll {
        Remove-Item -Path $script:tmpDir -Recurse -Force -ErrorAction SilentlyContinue
        if ($script:origCache) { $env:USERPROFILE = $script:origCache }
    }
    It 'Save-AuditCache writes a parseable JSON file' {
        $sample = @([PSCustomObject]@{
            Id = 'test-1'; Category = 'privacy'; Severity = 'info'
            Title = 'Test'; Description = 'desc'; Evidence = 'evid'
            Cost = @{ type = 'qualitative' }
            Remediation = @{ type = 'inline'; target = 'Write-Host hi' }
        })
        Save-AuditCache -Findings $sample
        Test-Path (Get-AuditCachePath) | Should -BeTrue
    }
    It 'Read-AuditCache returns previously saved findings' {
        $cached = Read-AuditCache
        $cached | Should -Not -BeNullOrEmpty
        $cached[0].Id | Should -Be 'test-1'
    }
    It 'Read-AuditCache returns $null when cache absent' {
        Remove-Item (Get-AuditCachePath) -Force -ErrorAction SilentlyContinue
        Read-AuditCache | Should -BeNullOrEmpty
    }
}

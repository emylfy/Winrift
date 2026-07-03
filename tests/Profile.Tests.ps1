BeforeAll {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    . (Join-Path $repoRoot 'scripts/Common.ps1')
    . (Join-Path $repoRoot 'modules/profile/Profile.ps1')
    $script:examplePath = Join-Path $repoRoot 'config/profiles/example.json'
}

Describe 'Read-WinriftProfile' {
    It 'parses the bundled example profile' {
        $p = Read-WinriftProfile -Path $script:examplePath
        $p.name | Should -Be 'example'
        @($p.tweaks).Count | Should -BeGreaterThan 0
        @($p.apps).Count | Should -BeGreaterThan 0
        @($p.configs) | Should -Contain 'terminal'
    }

    It 'throws on a missing file' {
        { Read-WinriftProfile -Path (Join-Path $TestDrive 'nope.json') } | Should -Throw
    }

    It 'throws on invalid JSON' {
        $bad = Join-Path $TestDrive 'bad.json'
        Set-Content -Path $bad -Value '{ not valid json'
        { Read-WinriftProfile -Path $bad } | Should -Throw
    }
}

Describe 'Get-WinriftConfigMap' {
    It 'defines the known config sets with source and target' {
        $map = Get-WinriftConfigMap
        foreach ($key in @('terminal', 'pwsh', 'ohmyposh', 'fastfetch', 'glazewm', 'vscode')) {
            $map.ContainsKey($key) | Should -BeTrue
            $map[$key].SourceDir | Should -Not -BeNullOrEmpty
            $map[$key].Files | Should -Not -BeNullOrEmpty
            $map[$key].Target | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Invoke-DesiredStateApply (dry-run)' {
    BeforeAll { $env:WINRIFT_DRY_RUN = '1' }
    AfterAll { Remove-Item Env:\WINRIFT_DRY_RUN -ErrorAction SilentlyContinue }

    It 'returns the count of entries and writes nothing in dry-run' {
        $entries = @(
            [PSCustomObject]@{ Path = 'HKCU:\Software\WinriftTestDoesNotExist'; Name = 'X'; Value = 1; Type = 'DWord'; Category = 'Test' }
        )
        $count = Invoke-DesiredStateApply -Entries $entries
        $count | Should -Be 1
        Test-Path 'HKCU:\Software\WinriftTestDoesNotExist' | Should -BeFalse
    }
}

Describe 'Invoke-WinriftProfileApply (dry-run)' {
    BeforeAll { $env:WINRIFT_DRY_RUN = '1' }
    AfterAll { Remove-Item Env:\WINRIFT_DRY_RUN -ErrorAction SilentlyContinue }

    It 'applies the example profile without throwing' {
        $p = Read-WinriftProfile -Path $script:examplePath
        { Invoke-WinriftProfileApply -ProfileObject $p 6>&1 | Out-Null } | Should -Not -Throw
    }

    It 'does not create a new registry key for a profile tweak in dry-run' {
        $bogus = 'HKCU:\Software\WinriftDryRunProbe'
        $p = [PSCustomObject]@{
            name    = 'probe'
            privacy = $false
            tweaks  = @([PSCustomObject]@{ Path = $bogus; Name = 'V'; Value = 1; Type = 'DWord'; Category = 'Test' })
            apps    = @()
            configs = @()
        }
        Invoke-WinriftProfileApply -ProfileObject $p 6>&1 | Out-Null
        Test-Path $bogus | Should -BeFalse
    }
}

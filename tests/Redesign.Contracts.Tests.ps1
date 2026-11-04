BeforeAll {
    . "$PSScriptRoot\..\scripts\Common.ps1"
}
Describe 'Macrift style menu geometry' {
    It 'keeps every active item visible at normal and narrow sizes' {
        $items = @(0..39 | ForEach-Object { "$_ › Item $_" })
        foreach ($size in @(@(80,25), @(30,12), @(12,7), @(5,4))) {
            foreach ($index in 0..39) {
                $frame = Get-WinriftMenuFrame -Title Winrift -Items $items -HighlightIndex $index -Width $size[0] -Height $size[1]
                $frame.Lines.Count | Should -BeLessThan $size[1]
                foreach ($line in $frame.Lines) {
                    ($line -replace '\x1b\[[0-9;]*m','').Length | Should -BeLessThan $size[0]
                }
                if ($size[1] -ge 7) {
                    $index | Should -BeGreaterOrEqual $frame.Top
                    $index | Should -BeLessThan ($frame.Top + [math]::Max(1, $size[1] - 7))
                }
            }
        }
    }
    It 'separates cursor and round selection markers' {
        $frame = Get-WinriftMenuFrame -Title Test -Items @('a › Alpha','b › Beta') -HighlightIndex 0 -Checked @($false,$true)
        $plain = ($frame.Lines -join "`n") -replace '\x1b\[[0-9;]*m',''
        $plain | Should -Match '▌ ○ Alpha'
        $plain | Should -Match '● Beta'
        $plain | Should -Not -Match 'a ›|b ›|\[ \]|\[x\]|[╭╮╰╯│]'
    }
}
Describe 'Atomic state' {
    It 'retains the last valid version on replacement' {
        $path = Join-Path $TestDrive 'state.json'
        Write-WinriftAtomicJson $path @{ schemaVersion=1; value='before' }
        Write-WinriftAtomicJson $path @{ schemaVersion=1; value='after' }
        (Read-WinriftJson $path).value | Should -Be after
        (Read-WinriftJson "$path.previous").value | Should -Be before
    }
    It 'preserves and rejects corrupt state' {
        $path = Join-Path $TestDrive 'corrupt.json'
        [IO.File]::WriteAllText($path, '{broken')
        { Read-WinriftJson $path } | Should -Throw
        [IO.File]::ReadAllText($path) | Should -Be '{broken'
    }
}
Describe 'Registry results and conflict-safe Undo' {
    BeforeEach {
        $script:oldStateRoot = $env:WINRIFT_STATE_ROOT
        $script:oldDryRun = $env:WINRIFT_DRY_RUN
        $env:WINRIFT_STATE_ROOT = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $env:WINRIFT_DRY_RUN = $null
        $script:registryTestPath = 'HKCU:\Software\WinriftTests\' + [guid]::NewGuid().ToString('N')
    }
    AfterEach {
        if (Test-Path -LiteralPath $script:registryTestPath) { Remove-Item -LiteralPath $script:registryTestPath -Recurse -Force }
        $env:WINRIFT_STATE_ROOT = $script:oldStateRoot
        $env:WINRIFT_DRY_RUN = $script:oldDryRun
    }
    It 'verifies zero and correct value type, then removes a previously absent value' {
        Set-RegistryValue $script:registryTestPath Flag DWord 0 'Test flag'
        $script:LastActionResult.Status | Should -Be Applied
        $record = @(Get-WinriftHistory)[0]
        $record.status | Should -Be Applied
        (Get-WinriftRegistrySnapshot $script:registryTestPath Flag).Type | Should -Be DWord
        Restore-WinriftRegistryAction $record | Should -Be Restored
        (Get-WinriftRegistrySnapshot $script:registryTestPath Flag).Exists | Should -BeFalse
    }
    It 'refuses to overwrite later edits' {
        Set-RegistryValue $script:registryTestPath Flag DWord 1 'Test flag'
        $record = @(Get-WinriftHistory)[0]
        Set-ItemProperty -LiteralPath $script:registryTestPath -Name Flag -Type DWord -Value 2
        Restore-WinriftRegistryAction $record | Should -Be Conflict
        (Get-ItemProperty -LiteralPath $script:registryTestPath).Flag | Should -Be 2
    }
    It 'does not write state or registry during dry-run' {
        $env:WINRIFT_DRY_RUN = '1'
        Set-RegistryValue $script:registryTestPath Flag DWord 1 'Test flag'
        $script:LastActionResult.Status | Should -Be DryRun
        Test-Path -LiteralPath $script:registryTestPath | Should -BeFalse
        Test-Path -LiteralPath $env:WINRIFT_STATE_ROOT | Should -BeFalse
    }
    It 'does not apply when journaling fails' {
        Mock Save-WinriftActionRecord { throw 'disk full' }
        Set-RegistryValue $script:registryTestPath Flag DWord 1 'Test flag'
        $script:LastActionResult.Status | Should -Be Failed
        Test-Path -LiteralPath $script:registryTestPath | Should -BeFalse
    }
    It 'treats signed and unsigned DWORD representations identically' {
        Test-WinriftRegistrySnapshot @{Exists=$true;Type='DWord';Value=-1} @{Exists=$true;Type='DWord';Value='4294967295'} | Should -BeTrue
    }
}
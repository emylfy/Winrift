BeforeAll {
    $path = Join-Path $PSScriptRoot '..\scripts\apply.ps1'
    $ast = [Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$null)
    # Load the resolver only; never apply a profile during these tests.
    foreach ($definition in $ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
        . ([scriptblock]::Create($definition.Extent.Text))
    }
}

Describe 'Headless bootstrap version selection' {
    BeforeEach {
        $script:root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:scripts = Join-Path $script:root 'scripts'
        [IO.Directory]::CreateDirectory($script:scripts) | Out-Null
        [IO.File]::WriteAllText((Join-Path $script:root 'Winrift.ps1'), '# test fixture only')
        [IO.File]::WriteAllText((Join-Path $script:scripts 'Main.ps1'), '# test fixture only')
        Mock Invoke-RestMethod { throw 'Unexpected network request' }
    }

    It 'uses the local checkout without downloading or replacing it' {
        Get-WinriftApplyRoot -ScriptDirectory $script:scripts | Should -Be $script:root
        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
    }

    It 'requests stable download-only mode even when the environment selects main' {
        $previousChannel = $env:WINRIFT_CHANNEL
        try {
            $env:WINRIFT_CHANNEL = 'main'
            Mock Invoke-RestMethod {
                $escaped = $script:root.Replace("'", "''")
                # This fixture enforces the real launcher's invocation contract.
                return "param([switch]`$DownloadOnly, [string]`$Channel); if (-not `$DownloadOnly -or `$Channel -ne 'stable') { throw 'Incorrect launch mode' }; '$escaped'"
            }
            Get-WinriftApplyRoot | Should -Be $script:root
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://github.com/emylfy/winrift/releases/latest/download/launch.ps1'
            }
        } finally { $env:WINRIFT_CHANNEL = $previousChannel }
    }

    It 'propagates a download failure rather than falling back to an arbitrary cache' {
        Mock Invoke-RestMethod { throw 'offline' }
        { Get-WinriftApplyRoot } | Should -Throw '*offline*'
    }

    It 'rejects a launcher that returns no installation' {
        Mock Invoke-RestMethod { 'param([switch]$DownloadOnly, [string]$Channel); return' }
        { Get-WinriftApplyRoot } | Should -Throw '*usable Winrift installation*'
    }

    It 'rejects a launcher that returns a missing installation' {
        Mock Invoke-RestMethod { "param([switch]`$DownloadOnly, [string]`$Channel); 'missing-winrift-test-directory'" }
        { Get-WinriftApplyRoot } | Should -Throw '*usable Winrift installation*'
    }
}

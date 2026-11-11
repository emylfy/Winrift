Describe 'Copy-ConfigFiles' {
    BeforeAll {
        $script:oldStateRoot=$env:WINRIFT_STATE_ROOT
        $env:WINRIFT_STATE_ROOT=Join-Path $TestDrive 'state'
        . (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/Common.ps1')
        . (Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/customize/Customize.Configs.ps1')
    }

    AfterAll { $env:WINRIFT_STATE_ROOT=$script:oldStateRoot }
    It 'copies files to target directory' {
        $src = Join-Path $TestDrive 'source'
        $dst = Join-Path $TestDrive 'target'
        New-Item -Path $src -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $src 'test.txt') -Value 'hello'

        Copy-ConfigFiles -SourceDir $src -FileNames @('test.txt') -TargetDir $dst -ConfigName 'Test' -Reviewed

        Join-Path $dst 'test.txt' | Should -Exist
        Get-Content (Join-Path $dst 'test.txt') | Should -Be 'hello'
    }

    It 'creates .bak backup when target file exists' {
        $src = Join-Path $TestDrive 'source2'
        $dst = Join-Path $TestDrive 'target2'
        New-Item -Path $src -ItemType Directory -Force | Out-Null
        New-Item -Path $dst -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $src 'cfg.json') -Value 'new'
        Set-Content -Path (Join-Path $dst 'cfg.json') -Value 'old'

        Copy-ConfigFiles -SourceDir $src -FileNames @('cfg.json') -TargetDir $dst -ConfigName 'Test' -Reviewed

        Get-Content (Join-Path $dst 'cfg.json') | Should -Be 'new'
        Join-Path $dst 'cfg.json.bak' | Should -Exist
        Get-Content (Join-Path $dst 'cfg.json.bak') | Should -Be 'old'
    }

    It 'supports renaming files via TargetFileNames' {
        $src = Join-Path $TestDrive 'source3'
        $dst = Join-Path $TestDrive 'target3'
        New-Item -Path $src -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $src 'input.json') -Value 'data'

        Copy-ConfigFiles -SourceDir $src -FileNames @('input.json') -TargetDir $dst `
                         -TargetFileNames @('output.json') -ConfigName 'Test' -Reviewed

        Join-Path $dst 'output.json' | Should -Exist
        Join-Path $dst 'input.json' | Should -Not -Exist
    }

    It 'creates target directory if it does not exist' {
        $src = Join-Path $TestDrive 'source4'
        $dst = Join-Path $TestDrive 'target4/nested/deep'
        New-Item -Path $src -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $src 'f.txt') -Value 'ok'

        Copy-ConfigFiles -SourceDir $src -FileNames @('f.txt') -TargetDir $dst -ConfigName 'Test' -Reviewed

        Join-Path $dst 'f.txt' | Should -Exist
    }
}

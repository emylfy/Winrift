BeforeAll {
    $launcher = Join-Path $PSScriptRoot '..\scripts\launch.ps1'
    $ast = [Management.Automation.Language.Parser]::ParseFile($launcher, [ref]$null, [ref]$null)
    # Load only the standalone downloader functions; never launch downloaded code.
    foreach ($definition in $ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
        . ([scriptblock]::Create($definition.Extent.Text))
    }
    function New-TestLauncherCache {
        param([string]$Path, [string]$Revision, [string]$Value = 'old')
        foreach ($file in @('Winrift.ps1', 'scripts\Start-Winrift.ps1', 'scripts\Main.ps1', 'scripts\Common.ps1')) {
            $target = Join-Path $Path $file
            [IO.Directory]::CreateDirectory((Split-Path $target -Parent)) | Out-Null
            [IO.File]::WriteAllText($target, "# $Value")
        }
        [IO.Directory]::CreateDirectory((Join-Path $Path 'config')) | Out-Null
        [IO.File]::WriteAllText((Join-Path $Path 'config\version.json'), '{"version":"26.11"}')
        if ($Revision) { [IO.File]::WriteAllText((Join-Path $Path '.winrift-revision'), $Revision) }
    }
}

Describe 'Standalone online launcher cache' {
    BeforeEach {
        $script:cache = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:old = 'a' * 40
        $script:latest = 'b' * 40
        $script:current = Join-Path $script:cache 'winrift-main'
        Mock Invoke-RestMethod { @{ sha = $script:latest } }
        Mock Start-BitsTransfer { throw 'BITS unavailable' }
        Mock Invoke-WebRequest {
            param($Uri, $OutFile)
            $content = Join-Path $TestDrive ('archive-' + [guid]::NewGuid().ToString('N'))
            $repo = Join-Path $content ('winrift-' + $script:latest)
            New-TestLauncherCache $repo $null 'new'
            Compress-Archive -LiteralPath $repo -DestinationPath $OutFile
        }
    }

    It 'updates files on a different commit with the same 26.11 version and removes obsolete files' {
        New-TestLauncherCache $script:current $script:old
        [IO.File]::WriteAllText((Join-Path $script:current 'obsolete.ps1'), '# removed')
        Update-WinriftLauncherCache $script:cache | Should -Be $script:current
        Get-Content (Join-Path $script:current 'Winrift.ps1') | Should -Be '# new'
        Test-Path (Join-Path $script:current 'obsolete.ps1') | Should -BeFalse
        Get-Content (Join-Path $script:current '.winrift-revision') | Should -Be $script:latest
        Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter { $Uri -like "*/archive/$($script:latest).zip" }
    }

    It 'upgrades a legacy version-only cache instead of treating it as current' {
        New-TestLauncherCache $script:current $null
        Update-WinriftLauncherCache $script:cache | Should -Be $script:current
        Get-Content (Join-Path $script:current 'Winrift.ps1') | Should -Be '# new'
    }

    It 'skips the archive for an unchanged commit' {
        New-TestLauncherCache $script:current $script:latest
        Update-WinriftLauncherCache $script:cache | Should -Be $script:current
        Should -Invoke Start-BitsTransfer -Times 0 -Exactly
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
    }

    It 'uses a working cache when the commit API is unavailable' {
        New-TestLauncherCache $script:current $script:old
        Mock Invoke-RestMethod { throw 'offline' }
        Update-WinriftLauncherCache $script:cache | Should -Be $script:current
        Get-Content (Join-Path $script:current '.winrift-revision') | Should -Be $script:old
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
    }

    It 'retains a working older cache without the optional diagnostic wrapper while offline' {
        New-TestLauncherCache $script:current $script:old
        Remove-Item (Join-Path $script:current 'scripts\Start-Winrift.ps1')
        Mock Invoke-RestMethod { throw 'offline' }
        Update-WinriftLauncherCache $script:cache | Should -Be $script:current
        Get-Content (Join-Path $script:current 'Winrift.ps1') | Should -Be '# old'
    }

    It 'keeps the complete working copy after a download failure' {
        New-TestLauncherCache $script:current $script:old
        Mock Invoke-WebRequest { throw 'connection interrupted' }
        Update-WinriftLauncherCache $script:cache | Should -Be $script:current
        Get-Content (Join-Path $script:current 'Winrift.ps1') | Should -Be '# old'
        Get-Content (Join-Path $script:current '.winrift-revision') | Should -Be $script:old
        @(Get-ChildItem $script:cache -Directory -Force).Count | Should -Be 1
    }

    It 'retains the working cache when extraction or candidate validation fails' -ForEach @('zip', 'incomplete', 'syntax') {
        New-TestLauncherCache $script:current $script:old
        if ($_ -eq 'zip') { Mock Expand-Archive { throw 'truncated zip' } }
        if ($_ -eq 'incomplete') {
            Mock Expand-Archive {
                param($DestinationPath)
                $candidate = Join-Path $DestinationPath ('winrift-' + $script:latest)
                New-TestLauncherCache $candidate $null 'new'
                [IO.File]::Delete((Join-Path $candidate 'scripts\Main.ps1'))
            }
        }
        if ($_ -eq 'syntax') {
            Mock Expand-Archive {
                param($DestinationPath)
                $candidate = Join-Path $DestinationPath ('winrift-' + $script:latest)
                New-TestLauncherCache $candidate $null 'new'
                [IO.File]::WriteAllText((Join-Path $candidate 'Winrift.ps1'), 'function Broken {')
            }
        }
        Update-WinriftLauncherCache $script:cache | Should -Be $script:current
        Get-Content (Join-Path $script:current 'Winrift.ps1') | Should -Be '# old'
        Get-Content (Join-Path $script:current '.winrift-revision') | Should -Be $script:old
    }

    It 'rolls back the directory swap when promotion fails' {
        New-TestLauncherCache $script:current $script:old
        Mock Move-Item {
            param($LiteralPath, $Destination)
            if ($LiteralPath -like '*\.download-*') { throw 'promotion blocked' }
            [IO.Directory]::Move([string]$LiteralPath, [string]$Destination)
        }
        Update-WinriftLauncherCache $script:cache | Should -Be $script:current
        Get-Content (Join-Path $script:current 'Winrift.ps1') | Should -Be '# old'
        Get-Content (Join-Path $script:current '.winrift-revision') | Should -Be $script:old
        Should -Invoke Move-Item -Times 1 -Exactly -ParameterFilter { $LiteralPath -like '*\.previous-*' -and $Destination -eq $script:current }
    }

    It 'throws on a fresh offline installation instead of returning an unusable path' {
        Mock Invoke-RestMethod { throw 'offline' }
        { Update-WinriftLauncherCache $script:cache } | Should -Throw '*offline*'
        Test-Path $script:current | Should -BeFalse
    }

    It 'repairs an incomplete cache even when its revision marker is current' {
        New-TestLauncherCache $script:current $script:latest
        Remove-Item (Join-Path $script:current 'scripts\Main.ps1')
        Update-WinriftLauncherCache $script:cache | Should -Be $script:current
        Test-WinriftLauncherCache $script:current | Should -BeTrue
        Should -Invoke Invoke-WebRequest -Times 1 -Exactly
    }
}

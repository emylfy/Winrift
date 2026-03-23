BeforeDiscovery {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $scripts = @(
        @{
            File = 'modules/customize/Customize.Menu.ps1'
            ExpectedFunctions = @(
                'Show-CustomizeMenu', 'Show-DesktopMenu', 'Show-TerminalMenu',
                'Show-AppsMenu', 'Show-SpotifyToolsMenu', 'Show-VSCodeMenu',
                'Show-WindowsLookMenu'
            )
        }
        @{
            File = 'modules/customize/Customize.Desktop.ps1'
            ExpectedFunctions = @(
                'Install-GlazeWM', 'Copy-GlazeWMConfig', 'Install-StatusBar',
                'Install-FlowLauncher', 'Install-Windhawk', 'Install-Rainmeter',
                'Open-WallpaperBrowser'
            )
        }
        @{
            File = 'modules/customize/Customize.Apps.ps1'
            ExpectedFunctions = @(
                'Invoke-Rectify11', 'Install-SpotX', 'Install-Spicetify',
                'Install-SteamMillennium', 'Install-MacOSCursor'
            )
        }
        @{
            File = 'modules/customize/Customize.Configs.ps1'
            ExpectedFunctions = @(
                'Copy-ConfigFiles', 'Set-VSCodeConfig', 'Set-OtherVSCodeConfig',
                'Set-WinTermConfig', 'Set-PwshConfig', 'Set-OhMyPoshConfig',
                'Set-FastFetchConfig', 'Install-Starship'
            )
        }
        @{
            File = 'modules/customize/Customize.Windows.ps1'
            ExpectedFunctions = @(
                'Set-ShortDateHours', 'Disable-QuickAccess', 'Expand-StartFolders'
            )
        }
    )
}

Describe '<File>' -ForEach $scripts {
    BeforeAll {
        $filePath = Join-Path (Split-Path $PSScriptRoot -Parent) $File
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $filePath, [ref]$null, [ref]$null
        )
        $functionDefs = $ast.FindAll(
            { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true
        )
        $functionNames = $functionDefs | ForEach-Object { $_.Name }
    }

    It 'defines function <_>' -ForEach $ExpectedFunctions {
        $functionNames | Should -Contain $_
    }
}

Describe 'Common.ps1 exports' {
    BeforeAll {
        $filePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/Common.ps1'
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $filePath, [ref]$null, [ref]$null
        )
        $functionDefs = $ast.FindAll(
            { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true
        )
        $functionNames = $functionDefs | ForEach-Object { $_.Name }
    }

    It 'defines function <_>' -ForEach @(
        'Write-Log', 'Pause-ForUser', 'Invoke-ReturnToMenu', 'Show-MenuBox',
        'Assert-AdminOrElevate', 'Initialize-Logging', 'Invoke-MenuLoop',
        'Set-RegistryValue', 'Get-ToolConfig', 'Invoke-SecureScript',
        'Invoke-SecureDownload', 'Confirm-ExternalTool', 'Invoke-Tool',
        'Assert-WingetAvailable', 'Install-WingetPackage', 'Invoke-NativeCommand'
    ) {
        $functionNames | Should -Contain $_
    }
}

Describe 'Copy-ConfigFiles' {
    BeforeAll {
        . (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/Common.ps1')
        . (Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/customize/Customize.Configs.ps1')
    }

    It 'copies files to target directory' {
        $src = Join-Path $TestDrive 'source'
        $dst = Join-Path $TestDrive 'target'
        New-Item -Path $src -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $src 'test.txt') -Value 'hello'

        Copy-ConfigFiles -SourceDir $src -FileNames @('test.txt') -TargetDir $dst -ConfigName 'Test'

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

        Copy-ConfigFiles -SourceDir $src -FileNames @('cfg.json') -TargetDir $dst -ConfigName 'Test'

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
                         -TargetFileNames @('output.json') -ConfigName 'Test'

        Join-Path $dst 'output.json' | Should -Exist
        Join-Path $dst 'input.json' | Should -Not -Exist
    }

    It 'creates target directory if it does not exist' {
        $src = Join-Path $TestDrive 'source4'
        $dst = Join-Path $TestDrive 'target4/nested/deep'
        New-Item -Path $src -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $src 'f.txt') -Value 'ok'

        Copy-ConfigFiles -SourceDir $src -FileNames @('f.txt') -TargetDir $dst -ConfigName 'Test'

        Join-Path $dst 'f.txt' | Should -Exist
    }
}

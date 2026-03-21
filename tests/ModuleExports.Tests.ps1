BeforeDiscovery {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $scripts = @(
        @{
            File = 'modules/windots/Windots.Menu.ps1'
            ExpectedFunctions = @(
                'Show-MainMenu', 'Show-TerminalMenu', 'Show-AppsMenu',
                'Show-SpotifyToolsMenu', 'Show-VSCodeMenu',
                'Show-WindowsCustomizationMenu'
            )
        }
        @{
            File = 'modules/windots/Windots.Apps.ps1'
            ExpectedFunctions = @(
                'Invoke-Rectify11', 'Install-SpotX', 'Install-Spicetify',
                'Install-Steam', 'Set-Cursor'
            )
        }
        @{
            File = 'modules/windots/Windots.Configs.ps1'
            ExpectedFunctions = @(
                'Set-VSCodeConfig', 'Set-OtherVSCConfig', 'Set-WinTermConfig',
                'Set-PwshConfig', 'Set-OhMyPoshConfig', 'Set-FastFetchConfig'
            )
        }
        @{
            File = 'modules/windots/Windots.Customization.ps1'
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

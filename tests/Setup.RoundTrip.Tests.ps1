BeforeAll {
    . "$PSScriptRoot\..\scripts\Common.ps1"
    . "$PSScriptRoot\..\modules\profile\Profile.ps1"
}

Describe 'Saved setup round trip on isolated Windows targets' {
    BeforeEach {
        $script:previousStateRoot = $env:WINRIFT_STATE_ROOT
        $script:previousDryRun = $env:WINRIFT_DRY_RUN
        $env:WINRIFT_STATE_ROOT = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $env:WINRIFT_DRY_RUN = $null
        $script:registryPath = 'HKCU:\Software\WinriftTests\' + [guid]::NewGuid().ToString('N')
        $script:configTarget = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:setupPath = Join-Path $TestDrive ([guid]::NewGuid().ToString('N') + '.json')
        [IO.Directory]::CreateDirectory($script:configTarget) | Out-Null
        $script:configFile = Join-Path $script:configTarget 'settings.json'
        New-Item -Path $script:registryPath -Force | Out-Null
        Set-ItemProperty -LiteralPath $script:registryPath -Name Flag -Type DWord -Value 7
        [IO.File]::WriteAllText($script:configFile, '{"theme":"source"}')

        Mock Get-WinriftSupportedRegistryTargets {
            $script:SupportedRegistryTypes = @{ "$($script:registryPath)|Flag" = 'DWord' }
            $targets = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            $null = $targets.Add("$($script:registryPath)|Flag")
            Write-Output -NoEnumerate -InputObject $targets
        }
        Mock Get-WinriftSetupSystemIds { @() }
        Mock Get-WinriftSetupConfigDefinitions {
            @{ example = @{ Name = 'Example'; Group = 'Terminal'; Target = $script:configTarget; Files = @('settings.json') } }
        }
        Mock Show-MultiSelect { @('W', 'T') }
        Mock Show-InteractiveMenu { 'Y' }
        Mock Read-Host { $script:setupPath }
        Mock Wait-ForUser {}
        Save-WinriftSetup
        $script:saved = Read-WinriftSetup $script:setupPath
        # Simulate a new target baseline; all IO stays in TestDrive and a test-only HKCU key.
        Set-ItemProperty -LiteralPath $script:registryPath -Name Flag -Type DWord -Value 2
        [IO.File]::WriteAllText($script:configFile, '{"theme":"target"}')
    }

    AfterEach {
        if (Test-Path -LiteralPath $script:registryPath) {
            Remove-Item -LiteralPath $script:registryPath -Recurse -Force
        }
        $env:WINRIFT_STATE_ROOT = $script:previousStateRoot
        $env:WINRIFT_DRY_RUN = $script:previousDryRun
    }

    It 'exports, restores and undoes exact registry types and configuration bytes' {
        $script:saved.sections.Windows | Should -HaveCount 1
        $script:saved.sections.Configurations | Should -HaveCount 1
        $script:saved.sections.Windows[0].Value | Should -Be 7
        $script:saved.sections.Windows[0].Type | Should -Be DWord
        $result = Invoke-WinriftSetupApply $script:saved -Sections Windows,Configurations
        @($result | Where-Object Status -eq Applied) | Should -HaveCount 2
        (Get-WinriftRegistrySnapshot $script:registryPath Flag).Value | Should -Be 7
        [IO.File]::ReadAllText($script:configFile) | Should -Be '{"theme":"source"}'
        $history = @(Get-WinriftHistory)
        $registry = @($history | Where-Object kind -eq Registry)[0]
        $file = @($history | Where-Object kind -eq File)[0]
        Restore-WinriftRegistryAction $registry | Should -Be Restored
        Restore-WinriftFileAction $file | Should -Be Restored
        (Get-WinriftRegistrySnapshot $script:registryPath Flag).Value | Should -Be 2
        (Get-WinriftRegistrySnapshot $script:registryPath Flag).Type | Should -Be DWord
        [IO.File]::ReadAllText($script:configFile) | Should -Be '{"theme":"target"}'
        (Read-WinriftSetup $script:setupPath).sections.Windows[0].Value | Should -Be 7
    }

    It 'previews restoration without changing either target' {
        $env:WINRIFT_DRY_RUN = '1'
        $result = Invoke-WinriftSetupApply $script:saved -Sections Windows,Configurations
        @($result | Where-Object Status -eq DryRun) | Should -HaveCount 2
        (Get-WinriftRegistrySnapshot $script:registryPath Flag).Value | Should -Be 2
        [IO.File]::ReadAllText($script:configFile) | Should -Be '{"theme":"target"}'
        @(Get-WinriftHistory) | Should -HaveCount 0
    }

    It 'restores only selected sections and preserves subsequent user edits on Undo' {
        $result = Invoke-WinriftSetupApply $script:saved -Sections Configurations
        @($result | Where-Object Status -eq Applied) | Should -HaveCount 1
        (Get-WinriftRegistrySnapshot $script:registryPath Flag).Value | Should -Be 2
        [IO.File]::WriteAllText($script:configFile, 'later user edit')
        $file = @((Get-WinriftHistory) | Where-Object kind -eq File)[0]
        Restore-WinriftFileAction $file | Should -Be Conflict
        [IO.File]::ReadAllText($script:configFile) | Should -Be 'later user edit'
    }
}

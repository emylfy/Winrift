BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/security/Privacy.ps1')
}

Describe 'Privacy.ps1 function exports' {
    It 'defines Invoke-PrivacyHardening' {
        Get-Command Invoke-PrivacyHardening -CommandType Function | Should -Not -BeNullOrEmpty
    }
    It 'defines Show-PrivacyMenu' {
        Get-Command Show-PrivacyMenu -CommandType Function | Should -Not -BeNullOrEmpty
    }
}

Describe 'Privacy.ps1 script structure' {
    BeforeAll {
        $script:filePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/security/Privacy.ps1'
        $script:content = Get-Content $script:filePath -Raw
    }

    It 'contains registryTweaks array with 300+ entries' {
        $found = [regex]::Matches($script:content, '@\{\s*Path\s*=')
        $found.Count | Should -BeGreaterThan 300
    }

    It 'contains services to disable' {
        $script:content | Should -Match 'DiagTrack'
        $script:content | Should -Match 'dmwappushservice'
    }

    It 'contains scheduled tasks to disable' {
        $script:content | Should -Match 'Microsoft Compatibility Appraiser'
        $script:content | Should -Match 'KernelCeipTask'
    }

    It 'contains appx packages to remove' {
        $script:content | Should -Match 'Microsoft\.549981C3F5F10'
        $script:content | Should -Match 'Microsoft\.WindowsFeedbackHub'
    }

    It 'contains Windows features to disable' {
        $script:content | Should -Match 'SMB1Protocol'
        $script:content | Should -Match 'TelnetClient'
    }

    It 'contains hosts file blocking' {
        $script:content | Should -Match 'vortex-win\.data\.microsoft\.com'
        $script:content | Should -Match 'telecommand\.telemetry\.microsoft\.com'
    }

    It 'contains environment variable opt-outs' {
        $script:content | Should -Match 'DOTNET_CLI_TELEMETRY_OPTOUT'
        $script:content | Should -Match 'POWERSHELL_TELEMETRY_OPTOUT'
    }

    It 'contains UploadUserActivities fix' {
        $script:content | Should -Match 'UploadUserActivities'
    }

}

Describe 'Privacy Appx error isolation' {
    It 'continues with other packages after an unsupported removal request' {
        Mock Get-AppxPackage {
            if ($Name -eq 'Example.First') {
                [pscustomobject]@{ PackageFullName = 'Example.First_unsupported'; NonRemovable = $false }
                [pscustomobject]@{ PackageFullName = 'Example.First_other'; NonRemovable = $false }
            } else {
                [pscustomobject]@{ PackageFullName = 'Example.Second_installed'; NonRemovable = $false }
            }
        }
        Mock Remove-AppxPackage {
            if ($Package -eq 'Example.First_unsupported') { throw 'The request is not supported.' }
        }
        Mock Get-AppxProvisionedPackage { [pscustomobject]@{ DisplayName = 'Example.First'; PackageName = 'Example.First_provisioned' } }
        Mock Remove-AppxProvisionedPackage {}
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -like '*Deprovisioned*' }
        Mock New-Item {} -ParameterFilter { $Path -like '*Deprovisioned*' }
        Mock Write-Log {}

        $results = [System.Collections.Generic.List[object]]::new()
        Remove-WinriftPrivacyApp -Name 'Example.First' -Results $results
        Remove-WinriftPrivacyApp -Name 'Example.Second' -Results $results

        Should -Invoke Remove-AppxPackage -Times 1 -Exactly -ParameterFilter { $Package -eq 'Example.First_other' }
        Should -Invoke Remove-AppxPackage -Times 1 -Exactly -ParameterFilter { $Package -eq 'Example.Second_installed' }
        Should -Invoke Remove-AppxProvisionedPackage -Times 1 -Exactly -ParameterFilter { $PackageName -eq 'Example.First_provisioned' }
        Should -Invoke Test-Path -Times 0 -Exactly -ParameterFilter { $LiteralPath -like '*Deprovisioned*Example.First*' }
        ($results | Where-Object Status -EQ 'Failed').Name | Should -Be 'Example.First (installed app)'
    }
}

Describe 'Privacy backup finalization' {
    It 'tries both saves after an unexpected failure in the preset' {
        $previous = $env:WINRIFT_DRY_RUN
        try {
            $env:WINRIFT_DRY_RUN = '0'
            Mock Invoke-WinriftPrivacyOperations { throw 'Unexpected failure' }
            Mock Save-TweakBackup {}
            Mock Save-DesiredState {}

            { Invoke-PrivacyHardening } | Should -Throw '*Unexpected failure*'
            Should -Invoke Save-TweakBackup -Times 1 -Exactly
            Should -Invoke Save-DesiredState -Times 1 -Exactly
        } finally {
            $env:WINRIFT_DRY_RUN = $previous
        }
    }
}

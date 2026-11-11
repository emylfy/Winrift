BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/security/Privacy.ps1')
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

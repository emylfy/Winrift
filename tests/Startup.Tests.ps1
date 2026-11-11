BeforeAll {
    . "$PSScriptRoot\..\scripts\AdminLaunch.ps1"
    . "$PSScriptRoot\..\scripts\RequirePwsh.ps1"
}

Describe 'PowerShell bootstrap executable selection' {
    It 'selects one executable when PATH contains more than one pwsh installation' {
        Mock Get-Command {
            [pscustomobject]@{ Source = 'C:\Program Files\PowerShell\7\pwsh.exe' }
            [pscustomobject]@{ Source = 'C:\Other PowerShell\pwsh.exe' }
        } -ParameterFilter { $Name -eq 'pwsh.exe' }
        $found = @(Find-InstalledPwsh)
        $found | Should -HaveCount 1
        $found[0] | Should -Be 'C:\Program Files\PowerShell\7\pwsh.exe'
    }
}

Describe 'Launch paths across elevation' {
    It 'converts a Parallels drive path to its UNC share before UAC' {
        Mock Get-PSDrive { [pscustomobject]@{ DisplayRoot = '\\Mac\Home' } } -ParameterFilter { $Name -eq 'Y' }
        ConvertTo-WinriftLaunchPath 'Y:\Parallels\Winrift\scripts\Main.ps1' | Should -Be '\\Mac\Home\Parallels\Winrift\scripts\Main.ps1'
    }
    It 'preserves local and UNC paths with spaces and apostrophes' {
        ConvertTo-WinriftLaunchPath "C:\Tim's files\Main.ps1" | Should -Be "C:\Tim's files\Main.ps1"
        ConvertTo-WinriftLaunchPath "\\Mac\Home\Tim's files\Main.ps1" | Should -Be "\\Mac\Home\Tim's files\Main.ps1"
    }
    It 'resolves a relative profile path before changing the process context' {
        ConvertTo-WinriftLaunchPath '.\config\profiles\example.json' | Should -Be (Join-Path (Get-Location).ProviderPath 'config\profiles\example.json')
    }
    It 'waits for the elevated child and returns its failure code' {
        Mock Start-Process { [pscustomobject]@{ ExitCode = 7 } }
        Start-AdminProcess -ScriptPath 'C:\Winrift\scripts\Main.ps1' | Should -Be 7
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter { $Verb -eq 'RunAs' -and $Wait -and $PassThru }
    }
}

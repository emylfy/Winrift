BeforeAll {
    $env:WINRIFT_NO_SPINNER = '1'
    function Write-Log { param([string]$Message, [string]$Level) }
    function Wait-ForUser {}
    function Show-MultiSelect { param([string]$Title, [string[]]$Items, $Defaults) return @() }
    function Install-WingetPackage { param([string]$PackageId, [string]$Name) return $true }

    $repoRoot = Split-Path $PSScriptRoot -Parent
    . "$repoRoot\scripts\Common.ps1"
}

Describe 'Get-InstalledAndBrokenIds' {
    BeforeAll {
        # Dot-source UniGetUI but stub winget so it doesn't run
        $repoRoot = Split-Path $PSScriptRoot -Parent
        function global:winget { }
        . "$repoRoot\modules\unigetui\UniGetUI.ps1"
    }

    It 'classifies a package with a real version as installed only' {
        Mock winget {
            # Simulate: one package with a normal version
            return @(
                'Name                      Id                           Version',
                '--------------------------------------------------------------',
                'Git for Windows            Git.Git                      2.44.0'
            )
        }
        $installed, $broken = Get-InstalledAndBrokenIds
        $installed.Contains('Git.Git') | Should -BeTrue
        $broken.Contains('Git.Git')    | Should -BeFalse
    }

    It 'classifies a package with Unknown version as both installed and broken' {
        Mock winget {
            return @(
                'Name                      Id                           Version',
                '--------------------------------------------------------------',
                'BrokenApp                  Broken.App                   Unknown'
            )
        }
        $installed, $broken = Get-InstalledAndBrokenIds
        $installed.Contains('Broken.App') | Should -BeTrue
        $broken.Contains('Broken.App')    | Should -BeTrue
    }

    It 'ignores lines that do not contain a package ID pattern' {
        Mock winget {
            return @(
                'Name                      Id                           Version',
                '--------------------------------------------------------------',
                '',
                'This line has no dotted.identifier at all',
                '   ---',
                'Real.Package               Real.Package                 1.0.0'
            )
        }
        $installed, $broken = Get-InstalledAndBrokenIds
        $installed.Contains('Real.Package') | Should -BeTrue
        # Header noise should not appear as IDs
        $installed.Contains('Id') | Should -BeFalse
    }

    It 'returns empty sets when winget returns no output' {
        Mock winget { return @() }
        $installed, $broken = Get-InstalledAndBrokenIds
        $installed.Count | Should -Be 0
        $broken.Count    | Should -Be 0
    }
}

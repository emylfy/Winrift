BeforeDiscovery {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $ps1Files = Get-ChildItem -Path $repoRoot -Filter '*.ps1' -Recurse |
        Where-Object { $_.FullName -notmatch '[/\\]\.git[/\\]' -and $_.FullName -notmatch '[/\\]tests[/\\]' }
}

Describe 'PowerShell script syntax validation' {
    It '<_.Name> parses without errors' -ForEach $ps1Files {
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $_.FullName, [ref]$null, [ref]$errors
        ) | Out-Null
        $errors | Should -HaveCount 0
    }
}

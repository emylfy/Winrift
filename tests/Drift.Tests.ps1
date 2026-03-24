BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/Common.ps1')
}

Describe 'Tweaks.Drift.ps1 function exports' {
    BeforeAll {
        $filePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/system/Tweaks.Drift.ps1'
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $filePath, [ref]$null, [ref]$null
        )
        $functionDefs = $ast.FindAll(
            { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true
        )
        $functionNames = $functionDefs | ForEach-Object { $_.Name }
    }

    It 'defines function <_>' -ForEach @(
        'Get-DesiredState', 'Test-DriftedEntries', 'Show-DriftReport',
        'Invoke-DriftReapply', 'Register-DriftScheduledTask',
        'Unregister-DriftScheduledTask', 'Get-DriftScheduledTaskStatus',
        'Show-DriftMenu'
    ) {
        $functionNames | Should -Contain $_
    }
}

Describe 'Save-DesiredState' {
    It 'creates desired state file with correct schema' {
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester_drift_$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
        New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null
        try {
            $script:DesiredStateDir = $tmpDir
            $script:DesiredStateEntries = [System.Collections.Generic.List[hashtable]]::new()
            $script:DesiredStateEntries.Add(@{
                Path = "HKLM:\TEST\Path"; Name = "TestVal"; Value = "1"
                Type = "DWord"; Category = "Test Category"
            })
            Save-DesiredState 6>&1 | Out-Null

            $filePath = Join-Path $tmpDir "desired_state.json"
            $filePath | Should -Exist
            $json = Get-Content $filePath -Raw | ConvertFrom-Json
            $json.version | Should -Be 1
            $json.entries.Count | Should -Be 1
            $json.entries[0].Name | Should -Be "TestVal"
            $json.entries[0].Category | Should -Be "Test Category"
        } finally {
            Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'merges with existing entries (upsert by Path+Name)' {
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester_drift_merge_$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
        New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null
        try {
            $filePath = Join-Path $tmpDir "desired_state.json"
            @{
                version = 1; lastUpdated = "2026-01-01T00:00:00"
                entries = @(
                    @{ Path = "HKLM:\A"; Name = "Existing"; Value = "old"; Type = "String"; Category = "Cat1"; UpdatedAt = "2026-01-01T00:00:00" }
                )
            } | ConvertTo-Json -Depth 5 | Set-Content -Path $filePath -Encoding UTF8

            $script:DesiredStateDir = $tmpDir
            $script:DesiredStateEntries = [System.Collections.Generic.List[hashtable]]::new()
            $script:DesiredStateEntries.Add(@{
                Path = "HKLM:\A"; Name = "Existing"; Value = "new"
                Type = "String"; Category = "Cat1"
            })
            $script:DesiredStateEntries.Add(@{
                Path = "HKLM:\B"; Name = "BrandNew"; Value = "1"
                Type = "DWord"; Category = "Cat2"
            })
            Save-DesiredState 6>&1 | Out-Null

            $json = Get-Content $filePath -Raw | ConvertFrom-Json
            $json.entries.Count | Should -Be 2
            ($json.entries | Where-Object { $_.Name -eq "Existing" }).Value | Should -Be "new"
            ($json.entries | Where-Object { $_.Name -eq "BrandNew" }).Value | Should -Be "1"
        } finally {
            Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

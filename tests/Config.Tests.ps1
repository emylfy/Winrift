BeforeDiscovery {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $bundleDir = Join-Path $repoRoot 'config' 'bundles'
    $bundleFiles = Get-ChildItem -Path $bundleDir -Filter '*.ubundle'
}

Describe 'version.json' {
    BeforeAll {
        $repoRoot = Split-Path $PSScriptRoot -Parent
        $versionFile = Join-Path $repoRoot 'config' 'version.json'
        $content = Get-Content $versionFile -Raw
        $json = $content | ConvertFrom-Json
    }

    It 'is valid JSON' {
        { $content | ConvertFrom-Json } | Should -Not -Throw
    }

    It 'has a version property matching YY.M format' {
        $json.version | Should -Match '^\d+\.\d+$'
    }

    It 'has a channel property' {
        $json.channel | Should -BeIn @('stable', 'beta', 'dev')
    }

    It 'has a repo property in owner/repo format' {
        $json.repo | Should -Match '^[^/]+/[^/]+$'
    }
}

Describe 'tools.json' {
    BeforeAll {
        $repoRoot = Split-Path $PSScriptRoot -Parent
        $toolsFile = Join-Path $repoRoot 'config' 'tools.json'
        $content = Get-Content $toolsFile -Raw
        $json = $content | ConvertFrom-Json
    }

    It 'is valid JSON' {
        { $content | ConvertFrom-Json } | Should -Not -Throw
    }

    It 'has a non-empty tools array' {
        $json.tools | Should -Not -BeNullOrEmpty
        $json.tools.Count | Should -BeGreaterThan 0
    }

    It 'each tool has required properties' {
        foreach ($tool in $json.tools) {
            $tool.id | Should -Not -BeNullOrEmpty
            $tool.name | Should -Not -BeNullOrEmpty
            $tool.type | Should -Not -BeNullOrEmpty
            $tool.url | Should -Not -BeNullOrEmpty
        }
    }

    It 'each tool type is irm or download' {
        foreach ($tool in $json.tools) {
            $tool.type | Should -BeIn @('irm', 'download')
        }
    }

    It 'download tools have a filename property' {
        $downloadTools = $json.tools | Where-Object { $_.type -eq 'download' }
        foreach ($tool in $downloadTools) {
            $tool.filename | Should -Not -BeNullOrEmpty
        }
    }

    It 'all tool IDs are unique' {
        $ids = $json.tools | ForEach-Object { $_.id }
        $ids | Should -HaveCount ($ids | Select-Object -Unique).Count
    }

    It 'all URLs use HTTPS' {
        foreach ($tool in $json.tools) {
            $tool.url | Should -Match '^https://'
        }
    }
}

Describe 'Bundle files' {
    It 'at least one bundle file exists' {
        $bundleFiles.Count | Should -BeGreaterThan 0
    }

    It '<_.Name> is valid JSON' -ForEach $bundleFiles {
        { Get-Content $_.FullName -Raw | ConvertFrom-Json } | Should -Not -Throw
    }

    It '<_.Name> has a packages array' -ForEach $bundleFiles {
        $json = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $json.packages | Should -Not -BeNullOrEmpty
    }

    It '<_.Name> packages have required fields' -ForEach $bundleFiles {
        $json = Get-Content $_.FullName -Raw | ConvertFrom-Json
        foreach ($pkg in $json.packages) {
            $pkg.Id | Should -Not -BeNullOrEmpty
            $pkg.Name | Should -Not -BeNullOrEmpty
            $pkg.Source | Should -Not -BeNullOrEmpty
        }
    }
}

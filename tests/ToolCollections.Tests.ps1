BeforeAll {
    $scripts = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts'
    . (Join-Path $scripts 'Common.ps1')
    . (Join-Path $scripts 'ToolCollections.ps1')
}

Describe 'External tool collections' {
    BeforeEach {
        $script:previousState = $env:WINRIFT_STATE_ROOT
        $script:previousDryRun = $env:WINRIFT_DRY_RUN
        $env:WINRIFT_STATE_ROOT = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $env:WINRIFT_DRY_RUN = '0'
        $script:source = [uri]'https://example.com/tools.json'
        $script:json = '{"schemaVersion":1,"name":"My Tools","tools":[{"name":"Example","description":"An example action.","type":"powershell","target":"throw ''Never execute on import''"}]}'
        Mock Get-WinriftToolCollectionText { $script:json }
        Mock Show-InteractiveMenu { 'A' }
    }

    AfterEach {
        $env:WINRIFT_STATE_ROOT = $script:previousState
        $env:WINRIFT_DRY_RUN = $script:previousDryRun
    }

    It 'resolves the tools.json file in a GitHub Gist' {
        Mock Get-WinriftToolCollectionText {
            '{"files":{"tools.json":{"raw_url":"https://gist.githubusercontent.com/alex/abcd/raw/tools.json"}}}'
        } -ParameterFilter { $Uri.Host -eq 'api.github.com' }

        $catalog = Import-WinriftToolCollection ([uri]'https://gist.github.com/alex/abcd')
        $catalog.tools[0].name | Should -Be 'Example'
        $catalog.tools[0].description | Should -Be 'An example action.'
        Should -Invoke Get-WinriftToolCollectionText -Exactly -Times 1 -ParameterFilter {
            $Uri.AbsoluteUri -eq 'https://api.github.com/gists/abcd'
        }
    }

    It 'saves after confirmation without running tool commands' {
        Show-WinriftToolCollectionImport -Source $script:source

        $saved = Read-WinriftJson (Get-WinriftToolCollectionPath $script:source)
        $saved.catalog.tools[0].target | Should -Be "throw 'Never execute on import'"
    }

    It 'keeps the saved catalog when an update fails validation' {
        Show-WinriftToolCollectionImport -Source $script:source
        $path = Get-WinriftToolCollectionPath $script:source
        $previous = [IO.File]::ReadAllText($path)
        $script:json = '{"schemaVersion":1,"name":"Broken","tools":[]}'
        { Show-WinriftToolCollectionImport -Source $script:source } | Should -Throw
        [IO.File]::ReadAllText($path) | Should -BeExactly $previous
    }

    It 'accepts a catalog without descriptions' {
        $script:json = $script:json.Replace('"description":"An example action.",', '')
        (Import-WinriftToolCollection $script:source).tools[0].description | Should -Be ''
    }

    It 'does not save a declined import' {
        Mock Show-InteractiveMenu { 'N' }
        Show-WinriftToolCollectionImport -Source $script:source
        [IO.File]::Exists((Get-WinriftToolCollectionPath $script:source)) | Should -BeFalse
    }
    It 'does not save a collection during dry-run' {
        $env:WINRIFT_DRY_RUN = '1'
        Show-WinriftToolCollectionImport -Source $script:source
        [IO.File]::Exists((Get-WinriftToolCollectionPath $script:source)) | Should -BeFalse
    }

    It 'does not open a tool when launch is declined' {
        Mock Read-Host { 'N' }
        Mock Clear-Host {}
        Mock Start-Process {}
        $tool = @{ name = 'Example'; type = 'url'; target = 'https://example.com/' }
        Start-WinriftCollectionTool $tool $script:source.AbsoluteUri
        Should -Invoke Start-Process -Times 0 -Exactly
    }

    It 'does not open a tool during dry-run even when confirmed' {
        $env:WINRIFT_DRY_RUN = '1'
        Mock Read-Host { 'Y' }
        Mock Clear-Host {}
        Mock Start-Process {}
        $tool = @{ name = 'Example'; type = 'url'; target = 'https://example.com/' }
        Start-WinriftCollectionTool $tool $script:source.AbsoluteUri
        Should -Invoke Start-Process -Times 0 -Exactly
    }

    It 'rejects an unsupported tool instead of saving it' {
        $script:json = $script:json.Replace('"type":"powershell"', '"type":"unknown"')
        { Show-WinriftToolCollectionImport -Source $script:source } | Should -Throw
        [IO.File]::Exists((Get-WinriftToolCollectionPath $script:source)) | Should -BeFalse
    }

}

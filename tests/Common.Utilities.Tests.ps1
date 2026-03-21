BeforeAll {
    . (Join-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts') 'Common.ps1')
}

Describe 'Get-ToolConfig' {
    It 'returns tool object for known ID' {
        $tool = Get-ToolConfig 'winutil'
        $tool | Should -Not -BeNullOrEmpty
        $tool.id | Should -Be 'winutil'
        $tool.name | Should -Not -BeNullOrEmpty
        $tool.url | Should -Not -BeNullOrEmpty
    }

    It 'returns null for unknown ID' {
        $tool = Get-ToolConfig 'nonexistent-tool-xyz' 6>&1
        $tool | Should -BeNullOrEmpty
    }

    It 'returns correct type for each tool' {
        $tool = Get-ToolConfig 'gtweak'
        $tool.type | Should -Be 'download'
        $tool.filename | Should -Not -BeNullOrEmpty
    }
}

Describe 'Invoke-NativeCommand' {
    BeforeAll {
        # Use a cross-platform command for testing
        if ($IsWindows -or $env:OS -match 'Windows') {
            $script:testCmd = 'cmd'
            $script:successArgs = @('/c', 'echo test')
            $script:failArgs = @('/c', 'exit 1')
        } else {
            $script:testCmd = 'echo'
            $script:successArgs = @('test')
        }
    }

    It 'returns true for successful command' {
        $result = Invoke-NativeCommand -Command 'echo' -Arguments @('hello') `
            -SuccessMessage 'Worked' 6>&1
        # Filter out Write-Host output to get the boolean
        $boolResult = $result | Where-Object { $_ -is [bool] -or $_ -eq $true -or $_ -eq $false }
        $boolResult | Should -Contain $true
    }

    It 'uses custom SuccessMessage when provided' {
        $output = Invoke-NativeCommand -Command 'echo' -Arguments @('hello') `
            -SuccessMessage 'Custom success' 6>&1
        $output | Should -Not -BeNullOrEmpty
    }

    It 'uses custom ErrorMessage on failure' {
        # Use a command that will fail
        $result = Invoke-NativeCommand -Command 'false' -Arguments @() `
            -ErrorMessage 'Custom error' 6>&1
        $result | Should -Not -BeNullOrEmpty
    }

    It 'catches exceptions and returns false' {
        $result = Invoke-NativeCommand -Command 'this-command-does-not-exist-xyz' `
            -Arguments @() 6>&1
        $boolResult = $result | Where-Object { $_ -is [bool] }
        $boolResult | Should -Contain $false
    }
}

Describe 'Invoke-SecureDownload hash verification' {
    It 'succeeds when hash matches' {
        $tmpFile = Join-Path ([System.IO.Path]::GetTempPath()) "pester_hash_$(Get-Random).txt"
        $testContent = "test content for hash verification"
        try {
            # Pre-create the file to simulate download
            Set-Content -Path $tmpFile -Value $testContent -NoNewline
            $expectedHash = (Get-FileHash -Path $tmpFile -Algorithm SHA256).Hash

            # Mock Invoke-WebRequest to write our known content
            Mock Invoke-WebRequest {
                Set-Content -Path $OutFile -Value $testContent -NoNewline
            }

            { Invoke-SecureDownload -Url 'https://example.com/test' -OutFile $tmpFile `
                -ToolName 'TestTool' -ExpectedHash $expectedHash 6>&1 | Out-Null } | Should -Not -Throw
        } finally {
            Remove-Item $tmpFile -ErrorAction SilentlyContinue
        }
    }

    It 'throws and removes file when hash mismatches' {
        $tmpFile = Join-Path ([System.IO.Path]::GetTempPath()) "pester_badhash_$(Get-Random).txt"
        try {
            Mock Invoke-WebRequest {
                Set-Content -Path $OutFile -Value "actual content" -NoNewline
            }

            { Invoke-SecureDownload -Url 'https://example.com/test' -OutFile $tmpFile `
                -ToolName 'TestTool' -ExpectedHash 'AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555FFFF6666AAAA7777BBBB8888' 6>&1 | Out-Null } | Should -Throw

            $tmpFile | Should -Not -Exist
        } finally {
            Remove-Item $tmpFile -ErrorAction SilentlyContinue
        }
    }

    It 'skips verification when ExpectedHash is empty' {
        $tmpFile = Join-Path ([System.IO.Path]::GetTempPath()) "pester_nohash_$(Get-Random).txt"
        try {
            Mock Invoke-WebRequest {
                Set-Content -Path $OutFile -Value "some content" -NoNewline
            }

            { Invoke-SecureDownload -Url 'https://example.com/test' -OutFile $tmpFile `
                -ToolName 'TestTool' 6>&1 | Out-Null } | Should -Not -Throw

            $tmpFile | Should -Exist
        } finally {
            Remove-Item $tmpFile -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Invoke-SecureScript hash verification' {
    It 'throws on hash mismatch' {
        Mock Invoke-RestMethod { return 'Write-Host "mock script"' }
        Mock Invoke-Expression {}

        { Invoke-SecureScript -Url 'https://example.com/script.ps1' -ToolName 'TestScript' `
            -ExpectedHash 'AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555FFFF6666AAAA7777BBBB8888' 6>&1 | Out-Null } | Should -Throw '*Hash verification failed*'
    }

    It 'skips verification when ExpectedHash is empty' {
        Mock Invoke-RestMethod { return 'Write-Host "mock script"' }
        Mock Invoke-Expression {}

        { Invoke-SecureScript -Url 'https://example.com/script.ps1' -ToolName 'TestScript' 6>&1 | Out-Null } | Should -Not -Throw
    }
}

Describe 'Invoke-Tool' {
    It 'is defined with correct parameters' {
        $cmd = Get-Command Invoke-Tool -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
        $cmd.Parameters.Keys | Should -Contain 'ToolId'
        $cmd.Parameters.Keys | Should -Contain 'SuccessMessage'
        $cmd.Parameters.Keys | Should -Contain 'ErrorMessage'
        $cmd.Parameters.Keys | Should -Contain 'OnSuccess'
        $cmd.Parameters.Keys | Should -Contain 'Wait'
    }

    It 'returns false for unknown tool ID' {
        $result = Invoke-Tool 'nonexistent-tool-xyz' 6>&1
        $boolResult = $result | Where-Object { $_ -is [bool] }
        $boolResult | Should -Contain $false
    }

    It 'calls Invoke-SecureScript for irm tools' {
        Mock Invoke-SecureScript {}
        Mock Confirm-ExternalTool { return $true }
        Mock Get-ToolConfig {
            return [PSCustomObject]@{
                id = 'test-irm'; name = 'Test'; type = 'irm'
                url = 'https://example.com/test.ps1'; sha256 = $null
                fallbackUrl = $null
            }
        }

        $result = Invoke-Tool 'test-irm' 6>&1
        Should -Invoke Invoke-SecureScript -Times 1
    }

    It 'calls Start-Process for browser tools' {
        Mock Start-Process {}
        Mock Get-ToolConfig {
            return [PSCustomObject]@{
                id = 'test-browser'; name = 'Test'; type = 'browser'
                url = 'https://example.com'; sha256 = $null
                fallbackUrl = $null
            }
        }

        $result = Invoke-Tool 'test-browser' 6>&1
        Should -Invoke Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'https://example.com' -or $args -contains 'https://example.com' }
    }

    It 'opens fallbackUrl on failure' {
        Mock Invoke-SecureScript { throw "Download failed" }
        Mock Confirm-ExternalTool { return $true }
        Mock Start-Process {}
        Mock Get-ToolConfig {
            return [PSCustomObject]@{
                id = 'test-fallback'; name = 'Test'; type = 'irm'
                url = 'https://example.com/bad.ps1'; sha256 = $null
                fallbackUrl = 'https://example.com/releases'
            }
        }

        $result = Invoke-Tool 'test-fallback' 6>&1
        Should -Invoke Start-Process -Times 1
    }
}

Describe 'Invoke-MenuLoop' {
    It 'is defined with correct parameters' {
        $cmd = Get-Command Invoke-MenuLoop -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
        $cmd.Parameters.Keys | Should -Contain 'Title'
        $cmd.Parameters.Keys | Should -Contain 'Items'
        $cmd.Parameters.Keys | Should -Contain 'Actions'
        $cmd.Parameters.Keys | Should -Contain 'ExitKey'
        $cmd.Parameters.Keys | Should -Contain 'OnExit'
    }
}

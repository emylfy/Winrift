BeforeAll {
    . (Join-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts') 'Common.ps1')
}

Describe 'Color variables' {
    It '<name> is defined and non-empty' -ForEach @(
        @{ name = 'Purple' }
        @{ name = 'Reset' }
        @{ name = 'Red' }
        @{ name = 'Green' }
        @{ name = 'Yellow' }
    ) {
        (Get-Variable -Name $name -ValueOnly) | Should -Not -BeNullOrEmpty
    }

    It 'color variables contain ANSI escape sequences' {
        $Purple | Should -Match '\x1b\[38;5;'
        $Reset | Should -Match '\x1b\[0m'
    }
}

Describe 'Write-Log' {
    It 'accepts level <level>' -ForEach @(
        @{ level = 'INFO' }
        @{ level = 'SUCCESS' }
        @{ level = 'WARNING' }
        @{ level = 'ERROR' }
        @{ level = 'SKIP' }
    ) {
        { Write-Log -Message 'test' -Level $level 6>&1 | Out-Null } | Should -Not -Throw
    }

    It 'writes to log file with correct format' {
        $tmpLog = Join-Path ([System.IO.Path]::GetTempPath()) "pester_writelog_$(Get-Random).log"
        try {
            Write-Log -Message 'test entry' -Level SUCCESS -LogFile $tmpLog 6>&1 | Out-Null
            $tmpLog | Should -Exist
            $content = Get-Content $tmpLog -Raw
            $content | Should -Match '\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[SUCCESS\] test entry'
        } finally {
            Remove-Item $tmpLog -ErrorAction SilentlyContinue
        }
    }

    It 'writes multiple entries to the same log file' {
        $tmpLog = Join-Path ([System.IO.Path]::GetTempPath()) "pester_multilog_$(Get-Random).log"
        try {
            Write-Log -Message 'entry 1' -Level INFO -LogFile $tmpLog 6>&1 | Out-Null
            Write-Log -Message 'entry 2' -Level ERROR -LogFile $tmpLog 6>&1 | Out-Null
            $lines = Get-Content $tmpLog
            $lines.Count | Should -Be 2
            $lines[0] | Should -Match '\[INFO\] entry 1'
            $lines[1] | Should -Match '\[ERROR\] entry 2'
        } finally {
            Remove-Item $tmpLog -ErrorAction SilentlyContinue
        }
    }

    It 'does not write to file when LogFile is empty' {
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester_nolog_$(Get-Random)"
        try {
            { Write-Log -Message 'no file' -Level INFO 6>&1 | Out-Null } | Should -Not -Throw
        } finally {
            if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }
        }
    }
}

Describe 'Show-MenuBox' {
    It 'renders without error' {
        { Show-MenuBox -Title 'Test' -Items @('Item 1', 'Item 2') 6>&1 | Out-Null } | Should -Not -Throw
    }

    It 'handles separator items' {
        { Show-MenuBox -Title 'Test' -Items @('Item 1', '---', 'Item 2') 6>&1 | Out-Null } | Should -Not -Throw
    }

    It 'handles separator with centered text' {
        { Show-MenuBox -Title 'Test' -Items @('Item 1', '--- Info text ---', 'Item 2') 6>&1 | Out-Null } | Should -Not -Throw
    }

    It 'handles empty items array' {
        { Show-MenuBox -Title 'Empty' -Items @() 6>&1 | Out-Null } | Should -Not -Throw
    }

    It 'respects explicit Width parameter' {
        { Show-MenuBox -Title 'T' -Items @('A') -Width 60 6>&1 | Out-Null } | Should -Not -Throw
    }
}

Describe 'Confirm-ExternalTool' {
    It 'has mandatory Tool parameter' {
        $cmd = Get-Command Confirm-ExternalTool
        $cmd.Parameters['Tool'].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
            ForEach-Object { $_.Mandatory | Should -Be $true }
    }
}

Describe 'Set-RegistryValue' {
    It 'has correct parameters' {
        $cmd = Get-Command Set-RegistryValue
        $cmd.Parameters.Keys | Should -Contain 'Path'
        $cmd.Parameters.Keys | Should -Contain 'Name'
        $cmd.Parameters.Keys | Should -Contain 'Type'
        $cmd.Parameters.Keys | Should -Contain 'Value'
        $cmd.Parameters.Keys | Should -Contain 'Message'
    }
}

Describe 'Tweak Backup System' {
    It 'Start-TweakSession clears previous entries' {
        Start-TweakSession
        # Backup should produce null with 0 entries
        $result = Save-TweakBackup 6>&1
        $result | Should -BeNullOrEmpty
    }

    It 'Save-TweakBackup creates valid JSON file' -Skip:(-not ($IsWindows -or $env:OS -match 'Windows')) {
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester_backup_$(Get-Random)"
        New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null
        try {
            Start-TweakSession
            # Create a test registry key and use Set-RegistryValue
            $testPath = "HKCU:\SOFTWARE\WinriftTest_$(Get-Random)"
            Set-RegistryValue -Path $testPath -Name "TestValue" -Type "String" -Value "test" -Message "Test" 6>&1 | Out-Null

            $backupPath = Save-TweakBackup 6>&1
            $jsonFiles = $backupPath | Where-Object { $_ -is [string] -and $_ -match '\.json$' }
            $jsonFiles | Should -Not -BeNullOrEmpty

            # Cleanup test registry
            Remove-Item $testPath -Recurse -Force -ErrorAction SilentlyContinue
        } finally {
            Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Restore-TweakBackup handles missing backup directory gracefully' {
        { Restore-TweakBackup 6>&1 | Out-Null } | Should -Not -Throw
    }
}

Describe 'New-SafeRestorePoint' {
    It 'is defined' {
        Get-Command New-SafeRestorePoint -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

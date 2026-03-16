BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts' 'Common.ps1')
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
}

Describe 'Write-Log' {
    It 'is defined' {
        Get-Command Write-Log -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

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
}

Describe 'Show-MenuBox' {
    It 'is defined' {
        Get-Command Show-MenuBox -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'renders without error' {
        { Show-MenuBox -Title 'Test' -Items @('Item 1', 'Item 2') 6>&1 | Out-Null } | Should -Not -Throw
    }

    It 'handles separator items' {
        { Show-MenuBox -Title 'Test' -Items @('Item 1', '---', 'Item 2') 6>&1 | Out-Null } | Should -Not -Throw
    }
}

Describe 'Set-RegistryValue' {
    It 'is defined with correct parameters' {
        $cmd = Get-Command Set-RegistryValue -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
        $cmd.Parameters.Keys | Should -Contain 'Path'
        $cmd.Parameters.Keys | Should -Contain 'Name'
        $cmd.Parameters.Keys | Should -Contain 'Type'
        $cmd.Parameters.Keys | Should -Contain 'Value'
        $cmd.Parameters.Keys | Should -Contain 'Message'
    }
}

Describe 'New-SafeRestorePoint' {
    It 'is defined' {
        Get-Command New-SafeRestorePoint -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'Invoke-ReturnToMenu' {
    It 'is defined' {
        Get-Command Invoke-ReturnToMenu -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

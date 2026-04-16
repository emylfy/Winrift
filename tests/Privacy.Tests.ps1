BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/security/Privacy.ps1')
}

Describe 'Privacy.ps1 function exports' {
    It 'defines Invoke-PrivacyHardening' {
        Get-Command Invoke-PrivacyHardening -CommandType Function | Should -Not -BeNullOrEmpty
    }
    It 'defines Show-PrivacyMenu' {
        Get-Command Show-PrivacyMenu -CommandType Function | Should -Not -BeNullOrEmpty
    }
}

Describe 'Privacy.ps1 script structure' {
    BeforeAll {
        $script:filePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/security/Privacy.ps1'
        $script:content = Get-Content $script:filePath -Raw
    }

    It 'contains registryTweaks array with 300+ entries' {
        $found = [regex]::Matches($script:content, '@\{\s*Path\s*=')
        $found.Count | Should -BeGreaterThan 300
    }

    It 'contains services to disable' {
        $script:content | Should -Match 'DiagTrack'
        $script:content | Should -Match 'dmwappushservice'
    }

    It 'contains scheduled tasks to disable' {
        $script:content | Should -Match 'Microsoft Compatibility Appraiser'
        $script:content | Should -Match 'KernelCeipTask'
    }

    It 'contains appx packages to remove' {
        $script:content | Should -Match 'Microsoft\.549981C3F5F10'
        $script:content | Should -Match 'Microsoft\.WindowsFeedbackHub'
    }

    It 'contains Windows features to disable' {
        $script:content | Should -Match 'SMB1Protocol'
        $script:content | Should -Match 'TelnetClient'
    }

    It 'contains hosts file blocking' {
        $script:content | Should -Match 'vortex-win\.data\.microsoft\.com'
        $script:content | Should -Match 'telecommand\.telemetry\.microsoft\.com'
    }

    It 'contains environment variable opt-outs' {
        $script:content | Should -Match 'DOTNET_CLI_TELEMETRY_OPTOUT'
        $script:content | Should -Match 'POWERSHELL_TELEMETRY_OPTOUT'
    }

    It 'contains UploadUserActivities fix' {
        $script:content | Should -Match 'UploadUserActivities'
    }

    It 'does not contain comment-only lines' {
        $lines = Get-Content $script:filePath
        $commentOnly = $lines | Where-Object { $_ -match '^\s*#' -and $_ -notmatch '^\s*#Requires' }
        $commentOnly | Should -BeNullOrEmpty
    }
}

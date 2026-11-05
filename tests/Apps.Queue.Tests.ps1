BeforeAll {
    function global:winget { $global:LASTEXITCODE=0 }
    . "$PSScriptRoot\..\modules\apps\Apps.ps1"
}
Describe 'Shared application queue' {
    BeforeEach {
        $script:oldRoot=$env:WINRIFT_STATE_ROOT
        $script:oldDry=$env:WINRIFT_DRY_RUN
        $env:WINRIFT_STATE_ROOT=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $env:WINRIFT_DRY_RUN=$null
    }
    AfterEach { $env:WINRIFT_STATE_ROOT=$script:oldRoot; $env:WINRIFT_DRY_RUN=$script:oldDry }
    It 'survives a reload and deduplicates shared category selections' {
        $a=[pscustomobject]@{Id='Example.One';Name='One';ManagerName='Winget'}
        $b=[pscustomobject]@{Id='Example.Two';Name='Two';ManagerName='Winget'}
        Save-WinriftAppQueue @($a,$b,$a)
        @(Get-WinriftAppQueue).Count | Should -Be 2
        @(Get-WinriftAppQueue).Id | Should -Contain 'Example.One'
    }
    It 'retains failed items after partial success' {
        $a=[pscustomobject]@{Id='Example.One';Name='One';ManagerName='Winget'}
        $b=[pscustomobject]@{Id='Example.Two';Name='Two';ManagerName='Winget'}
        Save-WinriftAppQueue @($a,$b)
        Mock winget { $global:LASTEXITCODE=0 }
        Mock Install-WingetPackage { param($PackageId) return $PackageId -eq 'Example.One' }
        $results=Invoke-WinriftQueuedInstall @($a,$b)
        @($results|Where-Object Status -EQ Completed).Count | Should -Be 1
        @($results|Where-Object Status -EQ Failed).Count | Should -Be 1
        @(Get-WinriftAppQueue).Id | Should -Be @('Example.Two')
    }
    It 'does not drop corrupt state or infer an empty queue' {
        $path=Join-Path $env:WINRIFT_STATE_ROOT 'apps\queue.json'
        [IO.Directory]::CreateDirectory((Split-Path $path -Parent)) | Out-Null
        [IO.File]::WriteAllText($path,'{broken')
        { Get-WinriftAppQueue } | Should -Throw
        [IO.File]::ReadAllText($path) | Should -Be '{broken'
    }
    It 'retains selections and never calls installers in dry-run' {
        $a=[pscustomobject]@{Id='Example.One';Name='One';ManagerName='Winget'}
        Save-WinriftAppQueue @($a)
        Mock Install-WingetPackage { throw 'must not run' }
        Mock winget { throw 'must not run' }
        $env:WINRIFT_DRY_RUN='1'
        $result=Invoke-WinriftQueuedInstall @($a)
        $result[0].Status | Should -Be DryRun
        @(Get-WinriftAppQueue).Id | Should -Be @('Example.One')
        Should -Invoke Install-WingetPackage -Times 0
        Should -Invoke winget -Times 0
    }
    It 'reports unsupported package managers as failed instead of dropping them' {
        $a=[pscustomobject]@{Id='example';Name='Example';ManagerName='UnknownManager'}
        Save-WinriftAppQueue @($a)
        $result=Invoke-WinriftQueuedInstall @($a)
        $result[0].Status | Should -Be Failed
        $result[0].Error | Should -Match 'Unsupported manager'
        @(Get-WinriftAppQueue).Count | Should -Be 1
    }
}
Describe 'Native action preview' {
    BeforeEach { $script:AuditQueue.Clear(); $script:CollectMode=$true }
    AfterEach { $script:CollectMode=$false; $script:AuditQueue.Clear() }
    It 'queries native state but never applies while collecting' {
        Mock Get-WinriftSystemValue { return $true }
        Mock Set-WinriftSystemValue { throw 'must not run' }
        Add-WinriftSystemAction 'MMAgent.PageCombining' $false 'Disable page combining'
        $script:AuditQueue.Count | Should -Be 1
        $script:AuditQueue[0].Current | Should -BeTrue
        Should -Invoke Set-WinriftSystemValue -Times 0
    }
    It 'preserves unavailable actions as unsupported instead of claiming success' {
        Mock Get-WinriftSystemValue { throw 'not supported' }
        Add-WinriftSystemAction 'MMAgent.PageCombining' $false 'Disable page combining'
        $script:AuditQueue[0].Supported | Should -BeFalse
        Test-WinriftQueuedChange $script:AuditQueue[0] | Should -BeFalse
    }
}
Describe 'Dry-run external tool handoff' {
    It 'never downloads or starts an external tool' {
        $old=$env:WINRIFT_DRY_RUN
        try{
            $env:WINRIFT_DRY_RUN='1'
            Mock Get-ToolConfig {return [pscustomobject]@{name='Test tool';type='irm';url='https://example.com/script.ps1'}}
            Mock Invoke-SecureScript {throw 'must not run'}
            Mock Start-Process {throw 'must not run'}
            Invoke-Tool test|Should -BeFalse
            Should -Invoke Invoke-SecureScript -Times 0
            Should -Invoke Start-Process -Times 0
        }finally{$env:WINRIFT_DRY_RUN=$old}
    }
}
BeforeAll {
    . "$PSScriptRoot\..\scripts\Common.ps1"
    . "$PSScriptRoot\..\modules\profile\Profile.ps1"
    . "$PSScriptRoot\..\modules\customize\Organizer.ps1"
    . "$PSScriptRoot\..\scripts\AdminLaunch.ps1"
}
Describe 'Versioned file Undo' {
    BeforeEach {
        $script:oldRoot=$env:WINRIFT_STATE_ROOT;$script:oldDry=$env:WINRIFT_DRY_RUN
        $env:WINRIFT_STATE_ROOT=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'));$env:WINRIFT_DRY_RUN=$null
    }
    AfterEach {$env:WINRIFT_STATE_ROOT=$script:oldRoot;$env:WINRIFT_DRY_RUN=$script:oldDry}
    It 'restores exact prior bytes and preserves later versions' {
        $source=Join-Path $TestDrive 'source.txt';$target=Join-Path $TestDrive 'target.txt'
        [IO.File]::WriteAllText($source,'new');[IO.File]::WriteAllText($target,'original')
        Copy-WinriftJournaledFile $source $target 'Test configuration'
        $record=@(Get-WinriftHistory)[0]
        [IO.File]::WriteAllText($target,'user edit')
        Restore-WinriftFileAction $record|Should -Be Conflict
        [IO.File]::ReadAllText($target)|Should -Be 'user edit'
        [IO.File]::WriteAllText($target,'new')
        Restore-WinriftFileAction $record|Should -Be Restored
        [IO.File]::ReadAllText($target)|Should -Be original
        [IO.File]::ReadAllText($record.before.BackupPath)|Should -Be original
    }
    It 'does not replace a file if the journal cannot be persisted' {
        $source=Join-Path $TestDrive 'source2.txt';$target=Join-Path $TestDrive 'target2.txt'
        [IO.File]::WriteAllText($source,'new');[IO.File]::WriteAllText($target,'original')
        Mock Save-WinriftActionRecord {throw 'disk full'}
        Copy-WinriftJournaledFile $source $target 'Test configuration'
        [IO.File]::ReadAllText($target)|Should -Be original
        $script:LastFileResult.Status|Should -Be Failed
    }
}
Describe 'Setup preflight and migration' {
    BeforeEach {
        $script:target=Join-Path $TestDrive 'setup-target'
        Mock Get-WinriftSetupConfigDefinitions {return @{example=@{Target=$script:target;Files=@('settings.json');Name='Example'}}}
    }
    It 'rejects traversal before any setting is applied' {
        $setup=New-WinriftSetup
        $setup.sections.Configurations=@(@{Id='example';Files=@(@{Name='..\outside.json';Content='';Hash=''});Extensions=@()})
        Mock Set-RegistryValue {throw 'must not run'}
        {Invoke-WinriftSetupApply $setup}|Should -Throw '*Unsupported filename*'
        Should -Invoke Set-RegistryValue -Times 0
    }
    It 'rejects interrupted or changed configuration content before Apply' {
        $setup=New-WinriftSetup
        $setup.sections.Configurations=@(@{Id='example';Files=@(@{Name='settings.json';Content=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('changed'));Hash='incorrect'});Extensions=@()})
        {Test-WinriftSetupContent $setup}|Should -Throw '*checksum mismatch*'
    }
    It 'migrates a legacy folder without overwriting its metadata or source files' {
        $folder=Join-Path $TestDrive 'legacy';[IO.Directory]::CreateDirectory($folder)|Out-Null
        [IO.File]::WriteAllText((Join-Path $folder 'profile.json'),'{}')
        [IO.File]::WriteAllText((Join-Path $folder 'terminal.json'),'old terminal')
        [IO.File]::WriteAllText((Join-Path $folder 'extensions.txt'),'vendor.extension')
        $setup=Read-WinriftSetup $folder
        $setup.kind|Should -Be Winrift.Setup
        $setup.sections.Configurations[0].Id|Should -Be terminal
        $setup.migrationNotes -join ' '|Should -Match 'no reliable editor identity'
        [IO.File]::ReadAllText((Join-Path $folder 'terminal.json'))|Should -Be 'old terminal'
    }
    It 'rejects unknown setup schemas' {
        {ConvertTo-WinriftSetup @{kind='Winrift.Setup';schemaVersion=99;sections=@{}}}|Should -Throw
    }
}
Describe 'Organizer paths and collisions' {
    It 'does not plan two shortcuts for the same destination or move unrelated files' {
        $root=Join-Path $TestDrive 'Programs';$one=Join-Path $root 'ExampleA';$two=Join-Path $root 'ExampleB'
        [IO.Directory]::CreateDirectory($one)|Out-Null;[IO.Directory]::CreateDirectory($two)|Out-Null
        [IO.File]::WriteAllText((Join-Path $one 'Example.lnk'),'first');[IO.File]::WriteAllText((Join-Path $two 'Example.lnk'),'second')
        [IO.File]::WriteAllText((Join-Path $one 'personal.txt'),'preserve')
        $plan=@(Get-WinriftOrganizerPlan @($root))
        $plan.Count|Should -Be 1
        [IO.File]::ReadAllText((Join-Path $one 'personal.txt'))|Should -Be preserve
    }
}
Describe 'Quoted UAC argument bridge' {
    It 'preserves a path with spaces and apostrophes and a switch through both encoded layers' {
        $scriptPath=Join-Path $TestDrive "receiver's script.ps1";$receipt=Join-Path $TestDrive 'receipt.json'
        $receiver='param([switch]$DryRun,[string]$Apply)' + "`n" + '@{DryRun=[bool]$DryRun;Apply=$Apply;Sid=$env:WINRIFT_ORIGIN_SID}|ConvertTo-Json|Set-Content -LiteralPath ' + "'" + $receipt.Replace("'","''") + "'"
        [IO.File]::WriteAllText($scriptPath,$receiver)
        Mock Start-Process {param($FilePath,$ArgumentList,$Verb) $script:bridge=$ArgumentList[-1]}
        $applyPath="C:\Folder with spaces\O'Brien\setup.json"
        Start-AdminProcess -ScriptPath $scriptPath -Arguments @('-DryRun','-Apply',$applyPath)
        $bridge=[Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($script:bridge))
        & ([scriptblock]::Create($bridge))
        $result=Get-Content -LiteralPath $receipt -Raw|ConvertFrom-Json
        $result.DryRun|Should -BeTrue
        $result.Apply|Should -Be $applyPath
        $result.Sid|Should -Be ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value)
    }
}
Describe 'Interactive terminal host' {
    BeforeEach {
        Mock Get-Command { [pscustomobject]@{Source='C:\WindowsApps\wt.exe'} } -ParameterFilter { $Name -eq 'wt.exe' }
        Mock Start-Process {}
    }
    It 'opens an explicit Winrift window in Windows Terminal when available' {
        Start-AdminProcess -ScriptPath 'C:\Winrift folder\Main.ps1' -InTerminal

        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -like '*\wt.exe' -and $ArgumentList[0] -eq '-w' -and
                $ArgumentList[1] -eq 'new' -and $ArgumentList -contains '-EncodedCommand' -and -not $Verb
        }
    }
    It 'uses CMD when Windows Terminal fails to start' {
        Mock Start-Process { throw 'Terminal unavailable' } -ParameterFilter { $FilePath -like '*\wt.exe' }

        Start-AdminProcess -ScriptPath 'C:\Winrift folder\Main.ps1' -InTerminal

        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -like '*\cmd.exe' -and $ArgumentList -like '/d /s /c *-EncodedCommand *' -and -not $Verb
        }
    }
}
Describe 'Partial native failure Undo' {
    BeforeEach {
        $script:oldRoot=$env:WINRIFT_STATE_ROOT;$script:oldDry=$env:WINRIFT_DRY_RUN
        $env:WINRIFT_STATE_ROOT=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'));$env:WINRIFT_DRY_RUN=$null
        $script:nativeState='Manual|Running|Absent'
        Mock Get-WinriftSystemValue {return $script:nativeState}
        Mock Set-WinriftSystemValue {param($Id,$Value) if($Value -eq 'Disabled|Stopped|Absent'){$script:nativeState='Disabled|Running|Absent';throw 'stop failed'}else{$script:nativeState=$Value}}
    }
    AfterEach {$env:WINRIFT_STATE_ROOT=$script:oldRoot;$env:WINRIFT_DRY_RUN=$script:oldDry}
    It 'records a partial failure without claiming success and restores only the observed state' {
        Invoke-WinriftSystemAction @{Id='Service.Test';Value='Disabled|Stopped|Absent';Message='Test service';Supported=$true}
        $record=@(Get-WinriftHistory)[0]
        $record.status|Should -Be Failed
        $record.observed|Should -Be 'Disabled|Running|Absent'
        Restore-WinriftSystemAction $record|Should -Be Restored
        $script:nativeState|Should -Be 'Manual|Running|Absent'
    }
    It 'detects changes after the failed operation' {
        Invoke-WinriftSystemAction @{Id='Service.Test';Value='Disabled|Stopped|Absent';Message='Test service';Supported=$true}
        $record=@(Get-WinriftHistory)[0]
        $script:nativeState='Disabled|Stopped|Absent'
        Restore-WinriftSystemAction $record|Should -Be Conflict
    }
}
Describe 'Prompt configuration preserves custom profile content' {
    BeforeAll {. "$PSScriptRoot\..\modules\customize\Customize.Configs.ps1"}
    It 'adds one managed Starship block while preserving custom code and versioned backup' {
        $oldRoot=$env:WINRIFT_STATE_ROOT;$oldDry=$env:WINRIFT_DRY_RUN
        try{
            $env:WINRIFT_STATE_ROOT=Join-Path $TestDrive 'prompt-state';$env:WINRIFT_DRY_RUN=$null
            $docs=Join-Path $TestDrive 'Documents';$profilePath=Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1'
            [IO.Directory]::CreateDirectory((Split-Path $profilePath -Parent))|Out-Null
            [IO.File]::WriteAllText($profilePath,'function MyCustomCommand { ''preserved'' }')
            Mock Show-InteractiveMenu {return 'Y'}
            Set-WinriftPromptProfile -Engine Starship -DocumentsRoot $docs
            $content=[IO.File]::ReadAllText($profilePath)
            $content|Should -Match 'MyCustomCommand'
            $content|Should -Match 'starship init powershell'
            ([regex]::Matches($content,'# Winrift prompt begin')).Count|Should -Be 1
            $errors=$null;[void][Management.Automation.Language.Parser]::ParseInput($content,[ref]$null,[ref]$errors)
            @($errors).Count|Should -Be 0
            $record=@(Get-WinriftHistory|Where-Object{$_.target.Path -eq $profilePath})[0]
            [IO.File]::ReadAllText($record.before.BackupPath)|Should -Match 'MyCustomCommand'
        }finally{$env:WINRIFT_STATE_ROOT=$oldRoot;$env:WINRIFT_DRY_RUN=$oldDry}
    }
}
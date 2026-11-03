BeforeAll {
    . "$PSScriptRoot\..\scripts\Common.ps1"
    . "$PSScriptRoot\..\modules\system\Tweaks.Universal.ps1"
    . "$PSScriptRoot\..\modules\system\Tweaks.GPU.ps1"
    $script:source=Get-Content "$PSScriptRoot\fixtures\alchemy-approved.json" -Raw|ConvertFrom-Json
    function Get-PresetSignatures($Entries){@($Entries|ForEach-Object{($_.Path+'|'+$_.Name+'|'+$_.Type+'|'+(ConvertTo-WinriftRegistryValue $_.Type $_.Value)).ToLowerInvariant()}|Sort-Object)}
}
Describe 'Preserved presets match pinned Alchemy source data' {
    BeforeEach {
        $script:AuditQueue.Clear();$script:CollectMode=$true
        Mock Get-DisplayAdapterIndices {return '0007'}
        Mock Get-WinriftRegistrySnapshot {return @{Exists=$false;Type=$null;Value=$null}}
        Mock Get-ItemProperty {return [pscustomobject]@{ProviderName=$script:vendor}}
    }
    AfterEach {$script:CollectMode=$false;$script:AuditQueue.Clear()}
    It 'preserves all five NVIDIA writes as one selectable preset' {
        $script:vendor='NVIDIA';$null=Invoke-NvidiaTweaks -NoExit
        $script:AuditQueue.Count|Should -Be 5
        @(Compare-Object (Get-PresetSignatures $script:source.presets.NVIDIA.entries) (Get-PresetSignatures $script:AuditQueue)).Count|Should -Be 0
    }
    It 'preserves all thirty AMD names, types and values with a detected adapter path' {
        $script:vendor='Advanced Micro Devices';$null=Invoke-AMDTweaks -NoExit
        $script:AuditQueue.Count|Should -Be 30
        $actual=@($script:AuditQueue|ForEach-Object{@{Path=($_.Path -replace '\\0007$','\<adapter>');Name=$_.Name;Type=$_.Type;Value=$_.Value}})
        @(Compare-Object (Get-PresetSignatures $script:source.presets.AMD.entries) (Get-PresetSignatures $actual)).Count|Should -Be 0
    }
    It 'does not classify Intel Corporation as ATI' {
        $script:vendor='Intel Corporation';$null=Invoke-AMDTweaks -NoExit
        $script:AuditQueue.Count|Should -Be 0
    }
    It 'preserves the complete fourteen-action DirectX preset' {
        Invoke-DirectXTweaks
        $script:AuditQueue.Count|Should -Be 14
        @(Compare-Object (Get-PresetSignatures $script:source.presets.DirectX.entries) (Get-PresetSignatures $script:AuditQueue)).Count|Should -Be 0
    }
}
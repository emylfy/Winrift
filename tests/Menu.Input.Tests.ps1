BeforeAll { . "$PSScriptRoot\..\scripts\Common.ps1" }

Describe 'Menu key behavior without console input injection' {
    BeforeEach {
        $script:previousConfirm = $env:WINRIFT_NO_CONFIRM
        $env:WINRIFT_NO_CONFIRM = $null
        $script:keys = [Collections.Generic.Queue[object]]::new()
        Mock _Enter-RawUI { @{ CtrlC = $false } }
        Mock _Exit-RawUI {}
        Mock Clear-Host {}
        Mock _Draw-InteractiveBox { 0 }
        Mock _Get-WinriftConsoleHeight { 25 }
        Mock _Set-WinriftControlCMode {}
        Mock Read-WinriftMenuKey {
            if (-not $script:keys.Count) { throw 'Unexpected additional key read.' }
            $script:keys.Dequeue()
        }
    }
    AfterEach { $env:WINRIFT_NO_CONFIRM = $script:previousConfirm }

    It 'returns from each menu with Left or Escape' -ForEach @(37, 27) {
        $key = [pscustomobject]@{ VirtualKeyCode = $_; Character = [char]0 }
        $script:keys.Enqueue($key)
        Show-InteractiveMenu -Title Test -Items @('1 › First', '0 › Back') | Should -BeNullOrEmpty
        $script:keys.Enqueue($key)
        @(Show-MultiSelect -Title Test -Items @('1 › First') -Defaults @($true)).Count | Should -Be 0
        $script:keys.Enqueue($key)
        $script:called = $false
        Invoke-MenuLoop -Title Test -Items @('1 › First', '0 › Back') -ExitKey 0 -Actions @{ '1' = { $script:called = $true } }
        $script:called | Should -BeFalse
        $script:keys.Count | Should -Be 0
    }

    It 'opens the highlighted action with Right or Enter' -ForEach @(39, 13) {
        $script:keys.Enqueue([pscustomobject]@{ VirtualKeyCode = 40; Character = [char]0 })
        $script:keys.Enqueue([pscustomobject]@{ VirtualKeyCode = $_; Character = [char]0 })
        Show-InteractiveMenu -Title Test -Items @('1 › First', '2 › Second', '0 › Back') | Should -Be '2'
    }

    It 'clamps at the first and last actions instead of wrapping' {
        foreach ($vk in @(38, 40, 40, 13)) { $script:keys.Enqueue([pscustomobject]@{ VirtualKeyCode = $vk; Character = [char]0 }) }
        Show-InteractiveMenu -Title Test -Items @('1 › First', '2 › Second') | Should -Be '2'
    }

    It 'returns only selected enabled settings after Space and Enter' {
        foreach ($vk in @(32, 40, 32, 13)) { $script:keys.Enqueue([pscustomobject]@{ VirtualKeyCode = $vk; Character = [char]0 }) }
        $confirmed = $false
        $result = @(Show-MultiSelect -Title Test -Items @('1 › First', '2 › Disabled') -Disabled @($false, $true) -Confirmed ([ref]$confirmed))
        $confirmed | Should -BeTrue
        $result | Should -HaveCount 1
        $result[0] | Should -Be '1'
    }
}

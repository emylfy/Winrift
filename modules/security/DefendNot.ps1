. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "DefendNot - Disable Windows Defender"

function Show-DefendNotMenu {
    $tool = Get-ToolConfig "defendnot"
    Invoke-MenuLoop -Title "DefendNot - Disable Windows Defender via WSC API" -Items @(
        "[1] Launch DefendNot",
        "[2] Open documentation / project source",
        "---",
        "[3] Back to menu"
    ) -Actions @{
        "1" = {
            Write-Host ""
            $defendnotPath = "$env:ProgramFiles\defendnot"

            try {
                Add-MpPreference -ExclusionPath $defendnotPath -ErrorAction Stop
                Write-Log -Message "Added Defender exclusion for $defendnotPath" -Level SUCCESS
            } catch {
                Write-Log -Message "Could not add exclusion: $($_.Exception.Message)" -Level WARNING
            }

            try {
                Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
                Write-Log -Message "Real-time protection disabled temporarily." -Level SUCCESS
            } catch {
                Write-Log -Message "Could not disable real-time protection." -Level WARNING
                Write-Log -Message "If Tamper Protection is on, disable it manually:" -Level WARNING
                Write-Log -Message "Windows Security > Virus & threat protection > Manage settings > Tamper Protection: Off" -Level WARNING
            }

            Invoke-Tool "defendnot"
            Read-Host "Press Enter to continue"
        }
        "2" = { Start-Process $tool.docs }
    } -ExitKey "3" -OnExit { & "$PSScriptRoot\SecurityMenu.ps1" }
}

Show-DefendNotMenu

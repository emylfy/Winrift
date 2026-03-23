. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "DefendNot - Disable Windows Defender"

$tool = Get-ToolConfig "defendnot"

Clear-Host
Show-MenuBox -Title "DefendNot - Disable Windows Defender" -Items @(
    "This will fetch and run a script from the web",
    "to disable Defender via the WSC API.",
    "",
    "Before running, real-time protection and",
    "Defender exclusion will be set automatically.",
    "You may need to disable Tamper Protection first.",
    "",
    "URL:    $($tool.url)",
    "Source: $($tool.docs)",
    "---",
    "[Y] Run  [N] Cancel  [R] Review source"
)

while ($true) {
    $choice = Read-Host ">"
    switch ($choice.ToUpper()) {
        "Y" {
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

            # Remove previous installation to avoid ExtractToDirectory conflict
            if (Test-Path $defendnotPath) {
                try {
                    Remove-Item $defendnotPath -Recurse -Force -ErrorAction Stop
                    Write-Log -Message "Removed previous installation." -Level INFO
                } catch {
                    Write-Log -Message "Could not remove $defendnotPath -- files may be locked." -Level WARNING
                }
            }

            $null = Invoke-Tool "defendnot" -SkipConfirm
            Read-Host "Press Enter to continue"
            & "$PSScriptRoot\SecurityMenu.ps1"
            return
        }
        "N" {
            & "$PSScriptRoot\SecurityMenu.ps1"
            return
        }
        "R" {
            if ($tool.docs) {
                Start-Process $tool.docs
                Write-Host "$Green  Opened project source in browser.$Reset"
            }
        }
        default { Write-Host "  Please enter Y, N, or R." }
    }
}

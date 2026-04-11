. "$PSScriptRoot\..\..\scripts\Common.ps1"
Initialize-Logging -ModuleName "defendnot"
$Host.UI.RawUI.WindowTitle = "DefendNot - Disable Windows Defender"

$result = Invoke-Tool "defendnot" -PreRun {
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

    if (Test-Path $defendnotPath) {
        try {
            Remove-Item $defendnotPath -Recurse -Force -ErrorAction Stop
            Write-Log -Message "Removed previous installation." -Level INFO
        } catch {
            Write-Log -Message "Could not remove $defendnotPath -- files may be locked." -Level WARNING
        }
    }
}

if (-not $result) {
    Write-Host ""
    Write-Log -Message "Disable Tamper Protection before running DefendNot:" -Level WARNING
    Write-Host "  Windows Security > Virus & threat protection > Manage settings > Tamper Protection: $Yellow Off$Reset"
}
Wait-ForUser

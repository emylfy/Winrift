param(
    [switch]$AutoCheck
)

# Auto-check mode: invoked by scheduled task after Windows Update
if ($AutoCheck) {
    . "$PSScriptRoot\..\..\scripts\Common.ps1"
    Initialize-Logging -ModuleName "drift-auto"

    $script:DesiredStateFile = Join-Path $env:USERPROFILE "Winrift\tweaks\desired_state.json"
    $allEntries = Test-DriftedEntries
    $drifted = @($allEntries | Where-Object { $_.Status -ne "OK" })

    if ($drifted.Count -gt 0) {
        Write-Log -Message "Drift detected: $($drifted.Count) value(s) changed since last tweak application." -Level WARNING
        foreach ($entry in $drifted) {
            Write-Log -Message "  [$($entry.Category)] $($entry.Name): expected=$($entry.Expected), current=$($entry.Current)" -Level WARNING
        }
    } else {
        Write-Log -Message "No drift detected. All values match desired state." -Level SUCCESS
    }
    exit 0
}

# Normal mode: dot-sourced from Tweaks.ps1

$script:DesiredStateFile = Join-Path $env:USERPROFILE "Winrift\tweaks\desired_state.json"
$script:DriftTaskName = "Winrift-DriftCheck"

function Get-DesiredState {
    if (-not (Test-Path $script:DesiredStateFile)) { return $null }
    try {
        $json = Get-Content $script:DesiredStateFile -Raw | ConvertFrom-Json
        return $json
    } catch {
        Write-Log -Message "Failed to read desired state: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Test-DriftedEntries {
    $state = Get-DesiredState
    if (-not $state -or -not $state.entries) {
        Write-Log -Message "No desired state found. Apply tweaks first." -Level WARNING
        return @()
    }

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($entry in $state.entries) {
        $status = "OK"
        $currentValue = $null

        try {
            if (-not (Test-Path $entry.Path)) {
                $status = "Missing"
            } else {
                $prop = Get-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
                if ($null -eq $prop -or $null -eq $prop.($entry.Name)) {
                    $status = "Missing"
                } else {
                    $currentValue = $prop.($entry.Name)
                    if ([string]$currentValue -ne [string]$entry.Value) {
                        $status = "Drifted"
                    }
                }
            }
        } catch {
            $status = "Error"
        }

        $results.Add([PSCustomObject]@{
            Path     = $entry.Path
            Name     = $entry.Name
            Expected = $entry.Value
            Current  = $currentValue
            Type     = $entry.Type
            Category = $entry.Category
            Status   = $status
        })
    }

    return $results
}

function Show-DriftReport {
    Write-Host ""
    Write-Log -Message "Checking for configuration drift..." -Level INFO

    $allEntries = Test-DriftedEntries
    if ($allEntries.Count -eq 0) { return $null }

    $drifted = @($allEntries | Where-Object { $_.Status -ne "OK" })
    $okCount = @($allEntries | Where-Object { $_.Status -eq "OK" }).Count

    if ($drifted.Count -eq 0) {
        Write-Host ""
        Show-MenuBox -Title "Drift Detection" -Items @(
            "No drift detected.",
            "All $okCount monitored values match desired state."
        )
        return $null
    }

    $grouped = $drifted | Group-Object Category

    $items = @(
        "$($drifted.Count) drifted value(s) out of $($allEntries.Count) monitored:",
        ""
    )
    foreach ($group in $grouped) {
        $items += "--- $($group.Name) ---"
        foreach ($entry in $group.Group) {
            if ($entry.Status -eq "Missing") {
                $items += "  $($entry.Name): MISSING (expected: $($entry.Expected))"
            } else {
                $items += "  $($entry.Name): $($entry.Current) -> $($entry.Expected)"
            }
        }
    }

    Show-MenuBox -Title "Drift Detection Report" -Items $items

    return $drifted
}

function Invoke-DriftReapply {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject[]]$DriftedEntries
    )

    Start-TweakSession
    $reapplied = 0
    $errors = 0

    foreach ($entry in $DriftedEntries) {
        $script:DesiredStateCategory = $entry.Category
        try {
            Set-RegistryValue `
                -Path $entry.Path `
                -Name $entry.Name `
                -Type $entry.Type `
                -Value $entry.Expected `
                -Message "Reapplied: $($entry.Name)"
            $reapplied++
        } catch {
            $errors++
            Write-Log -Message "Failed to reapply $($entry.Name): $($_.Exception.Message)" -Level ERROR
        }
    }

    Save-TweakBackup

    Write-Log -Message "Reapplied $reapplied of $($DriftedEntries.Count) drifted values. Errors: $errors" -Level $(if ($errors -eq 0) { 'SUCCESS' } else { 'WARNING' })
    Write-Log -Message "A system restart is recommended for changes to take effect." -Level INFO
}

function Register-DriftScheduledTask {
    $scriptPath = Join-Path $PSScriptRoot "Tweaks.Drift.ps1"

    $action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`" -AutoCheck"

    # Trigger on Windows Update completion (Event ID 19)
    $CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler
    $eventTrigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
    $eventTrigger.Subscription = @"
<QueryList>
  <Query Id="0" Path="System">
    <Select Path="System">*[System[Provider[@Name='Microsoft-Windows-WindowsUpdateClient'] and EventID=19]]</Select>
  </Query>
</QueryList>
"@
    $eventTrigger.Enabled = $true

    $principal = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -RunLevel Highest `
        -LogonType ServiceAccount

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    try {
        Unregister-ScheduledTask -TaskName $script:DriftTaskName -Confirm:$false -ErrorAction SilentlyContinue

        Register-ScheduledTask `
            -TaskName $script:DriftTaskName `
            -Action $action `
            -Trigger $eventTrigger `
            -Principal $principal `
            -Settings $settings `
            -Description "Winrift drift detection - checks if Windows Update reverted optimization tweaks" `
            -Force | Out-Null

        Write-Log -Message "Scheduled task '$($script:DriftTaskName)' registered. Will run after Windows Updates." -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to register scheduled task: $($_.Exception.Message)" -Level ERROR
    }
}

function Unregister-DriftScheduledTask {
    try {
        $existing = Get-ScheduledTask -TaskName $script:DriftTaskName -ErrorAction SilentlyContinue
        if ($existing) {
            Unregister-ScheduledTask -TaskName $script:DriftTaskName -Confirm:$false
            Write-Log -Message "Scheduled task '$($script:DriftTaskName)' removed." -Level SUCCESS
        } else {
            Write-Log -Message "No scheduled task found to remove." -Level INFO
        }
    } catch {
        Write-Log -Message "Failed to remove scheduled task: $($_.Exception.Message)" -Level ERROR
    }
}

function Get-DriftScheduledTaskStatus {
    $task = Get-ScheduledTask -TaskName $script:DriftTaskName -ErrorAction SilentlyContinue
    return ($null -ne $task)
}

function Show-DriftMenu {
    $taskRegistered = Get-DriftScheduledTaskStatus
    $taskLabel = if ($taskRegistered) { "Disable" } else { "Enable" }

    Invoke-MenuLoop -Title "Drift Detection" -Items @(
        "1 › Check for drift now",
        "2 › $taskLabel auto-check after Windows Update",
        "3 › Clear desired state (reset monitoring)",
        "---",
        "4 › Back"
    ) -Actions @{
        "1" = {
            $drifted = Show-DriftReport
            if ($drifted -and $drifted.Count -gt 0) {
                Write-Host ""
                Write-Host "  [Y] Reapply all drifted values   [N] Return to menu"
                $choice = Read-Host ">"
                if ($choice -eq "Y" -or $choice -eq "y") {
                    Invoke-DriftReapply -DriftedEntries $drifted
                }
                Wait-ForUser
            }
        }
        "2" = {
            if ($taskRegistered) {
                Unregister-DriftScheduledTask
            } else {
                Register-DriftScheduledTask
            }
            Wait-ForUser
        }
        "3" = {
            if (Test-Path $script:DesiredStateFile) {
                Write-Host ""
                Write-Host "  This will delete the desired state file."
                Write-Host "  [Y] Confirm   [N] Cancel"
                $choice = Read-Host ">"
                if ($choice -eq "Y" -or $choice -eq "y") {
                    Remove-Item $script:DesiredStateFile -Force
                    Write-Log -Message "Desired state cleared." -Level SUCCESS
                }
            } else {
                Write-Log -Message "No desired state file found." -Level INFO
            }
            Wait-ForUser
        }
    } -ExitKey "4"
}

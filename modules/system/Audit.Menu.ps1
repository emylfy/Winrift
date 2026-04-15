. "$PSScriptRoot\..\..\scripts\Common.ps1"
. "$PSScriptRoot\Audit.Engine.ps1"

# Audit menu UI — interactive browsing and application of audit findings.
# Re-audits after every apply so the user sees the immediate state change.

function Format-AuditSummary {
    # Produces the menu items that go above the per-finding list: counts by
    # severity and aggregated estimated savings.
    param([Parameter(Mandatory)][object[]]$Findings)

    $items = [System.Collections.Generic.List[string]]::new()
    if ($Findings.Count -eq 0) {
        $items.Add("$Green All checks passed — no issues found$Reset")
        return $items.ToArray()
    }

    $crit = ($Findings | Where-Object { $_.Severity -eq 'critical' }).Count
    $warn = ($Findings | Where-Object { $_.Severity -eq 'warning' }).Count
    $info = ($Findings | Where-Object { $_.Severity -eq 'info' }).Count
    $items.Add("$($Findings.Count) issue(s):  ${Red}$crit critical$Reset  ${Yellow}$warn warning$Reset  ${Cyan}$info info$Reset")

    # Aggregate estimated savings (only from cost.type = measured/estimated)
    $totalRam = 0; $totalDisk = 0
    foreach ($f in $Findings) {
        if ($f.Cost -and $f.Cost.type -in @('measured','estimated')) {
            if ($f.Cost.ram_mb)  { $totalRam  += [int]$f.Cost.ram_mb }
            if ($f.Cost.disk_mb) { $totalDisk += [int]$f.Cost.disk_mb }
        }
    }
    if ($totalRam -gt 0 -or $totalDisk -gt 0) {
        $parts = @()
        if ($totalRam -gt 0)  { $parts += "${Cyan}~$totalRam MB$Reset RAM" }
        if ($totalDisk -gt 0) { $parts += "${Cyan}~$totalDisk MB$Reset disk" }
        $items.Add("Estimated if all fixed: $($parts -join ', ')")
    }

    return $items.ToArray()
}

function Format-FindingShort {
    # One-line representation of a finding for the menu list.
    param([Parameter(Mandatory)][PSCustomObject]$Finding)

    $glyph = switch ($Finding.Severity) {
        'critical' { "$Red$([char]0x2717)$Reset" }     # ✗
        'warning'  { "$Yellow!$Reset" }
        default    { "$Cyan$([char]0x203A)$Reset" }    # ›
    }
    return "$glyph $($Finding.Title)"
}

function Show-AuditFindingDetail {
    # Detail screen for one finding. Prose (description, evidence, fix) is
    # printed as plain Write-Host so the terminal handles wrapping naturally.
    # The interactive box is reduced to a 2-item Y/N action menu.
    # Returns $true if the fix was applied (caller should re-audit).
    param([Parameter(Mandatory)][PSCustomObject]$Finding)

    Clear-Host
    Write-Host ""

    # Title — bold ice
    Write-Host "  $Bold$Ice$($Finding.Title)$Reset"

    # Severity glyph + category
    $sevGlyph = switch ($Finding.Severity) {
        'critical' { "$Red$([char]0x2717)$Reset" }     # ✗
        'warning'  { "$Yellow!$Reset" }
        default    { "$Cyan$([char]0x203A)$Reset" }    # ›
    }
    Write-Host "  $sevGlyph $Dim$($Finding.Severity) · $($Finding.Category)$Reset"
    Write-Host ""

    # Description — terminal handles wrap because Write-Host is not boxed
    Write-Host "  $($Finding.Description)"
    Write-Host ""

    # Evidence and Fix sections — single space between glyph and label
    Write-Host "  $Cyan$([char]0x203A)$Reset ${Bold}Evidence${Reset}"
    Write-Host "    $($Finding.Evidence)"
    Write-Host ""

    Write-Host "  $Cyan$([char]0x203A)$Reset ${Bold}Fix${Reset}"
    Write-Host "    $($Finding.Remediation.description)"
    if ($Finding.Remediation.requires_reboot) {
        Write-Host "    $Yellow! requires reboot$Reset"
    }

    # Tiny action box — does NOT clear the screen, prose above stays intact.
    # _Draw-InteractiveBox starts each frame with a blank line so we don't add
    # one here (otherwise we'd get a double blank between Fix and the box).
    $choice = Show-InteractiveMenu -Title "Action" -Items @(
        "Y > Apply this fix",
        "N > Back"
    ) -NoClear -HideKeys

    if ($choice -eq "Y") {
        return (Invoke-AuditApply -Finding $Finding)
    }
    return $false
}

function Invoke-AuditApply {
    # Applies a single finding's remediation. Returns $true on success.
    # Dispatches by remediation.type:
    #   module   → dot-source / invoke an existing Winrift module
    #   registry → parse "Path\Name=Value" target and write via Set-RegistryValue
    #              (Value of "DELETE" removes the entry)
    #   inline   → Invoke-Expression on the target string (use sparingly)
    param([Parameter(Mandatory)][PSCustomObject]$Finding)

    $rem = $Finding.Remediation
    if (-not $rem) {
        Write-Log -Message "Finding $($Finding.Id) has no remediation" -Level WARNING
        return $false
    }

    Write-Host ""
    Write-Log -Message "Applying: $($Finding.Title)" -Level INFO

    try {
        switch ($rem.type) {
            'module' {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                $modulePath = Join-Path $repoRoot $rem.target
                if (-not (Test-Path $modulePath)) {
                    Write-Log -Message "Module not found: $modulePath" -Level ERROR
                    return $false
                }
                & $modulePath
                Write-Log -Message "Module completed — re-scan to verify fix" -Level INFO
            }
            'manual' {
                Write-Log -Message $rem.description -Level INFO
            }
            'registry' {
                # Parse "HKLM:\Path\To\Key\Name=Value" or "...=DELETE"
                if ($rem.target -notmatch '^(.+?)\\([^\\]+)=(.+)$') {
                    Write-Log -Message "Malformed registry target: $($rem.target)" -Level ERROR
                    return $false
                }
                $regPath  = $Matches[1]
                $regName  = $Matches[2]
                $regValue = $Matches[3]
                if ($regValue -eq 'DELETE') {
                    Remove-ItemProperty -Path $regPath -Name $regName -ErrorAction Stop
                    Write-Log -Message "Removed $regPath\$regName" -Level SUCCESS
                } else {
                    Set-RegistryValue -Path $regPath -Name $regName -Type "DWord" -Value $regValue -Message "Audit fix: $($Finding.Title)"
                }
            }
            'inline' {
                # Allowlist of permitted inline commands.
                # audit_findings.json is a local file, but any free-form ScriptBlock::Create
                # execution is equivalent to Invoke-Expression — validate before running.
                # Split on `;` to allow chained commands (e.g. Stop-Service X; Set-Service X),
                # but validate every statement independently. Reject `|`, `&`, backtick.
                if ($rem.target -match '[|&`]') {
                    Write-Log -Message "Inline remediation contains prohibited characters (|&`). Skipping." -Level ERROR
                    return $false
                }
                $allowedPrefixes = @('Stop-Service', 'Set-Service', 'Stop-Process', 'Enable-MMAgent', 'Disable-MMAgent',
                                     'Get-Process', 'Start-Process', 'fsutil')
                $statements = $rem.target -split '\s*;\s*' | Where-Object { $_ -ne '' }
                foreach ($stmt in $statements) {
                    $firstToken = ($stmt -split '\s' | Where-Object { $_ -ne '' } | Select-Object -First 1)
                    if ($firstToken -notin $allowedPrefixes) {
                        Write-Log -Message "Inline remediation '$firstToken' is not in the allowed command list. Skipping." -Level ERROR
                        return $false
                    }
                }
                & ([ScriptBlock]::Create($rem.target))
                Write-Log -Message "Inline fix executed" -Level SUCCESS
            }
            default {
                Write-Log -Message "Unknown remediation type: $($rem.type)" -Level ERROR
                return $false
            }
        }
        return $true
    } catch {
        Write-Log -Message "Apply failed: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Invoke-ApplyAllCritical {
    # Bulk-applies every finding marked critical AND not requiring a reboot AND
    # not opening an external tool. Conservative by design — see plan §3.
    param([Parameter(Mandatory)][object[]]$Findings)

    $eligible = $Findings | Where-Object {
        $_.Severity -eq 'critical' -and -not $_.Remediation.requires_reboot -and $_.Remediation.type -notin @('module', 'manual')
    }
    if ($eligible.Count -eq 0) {
        Write-Log -Message "No critical findings eligible for bulk apply" -Level INFO
        return
    }

    Write-Host ""
    Write-Log -Message "Applying $($eligible.Count) critical fix(es)..." -Level INFO
    $applied = 0; $failed = 0
    foreach ($f in $eligible) {
        if (Invoke-AuditApply -Finding $f) { $applied++ } else { $failed++ }
    }
    Write-Host ""
    Write-Log -Message "Bulk apply complete: $applied applied, $failed failed" -Level $(if ($failed -eq 0) { 'SUCCESS' } else { 'WARNING' })
}

function Show-AuditWizard {
    # Boxless wizard-style audit UI: per-finding [*]/[ ] state markers, scroll
    # viewport with section headers, hint footer with macrift-style keybindings.
    # No A/R/B menu items — those are now hint-line keybindings (a, r, esc).
    #
    # State per finding: $selection[$id] = $true (will apply) | $false (skip).
    # Default on fresh audit: all findings selected (user disables what they
    # don't want, faster for the typical "fix everything" case).
    $Host.UI.RawUI.WindowTitle = "Winrift - System Audit"

    $needAudit = $true
    $findings = @()
    $selection = @{}
    $cursor = 0
    $vpTop = 0

    while ($true) {
        if ($needAudit) {
            Write-Host ""
            Write-Log -Message "Running system audit..." -Level INFO
            $progressCallback = {
                param($p)
                $bar = "[$($p.index)/$($p.total)]"
                $line = "  $Cyan$bar$Reset $($p.title)"
                Write-Host -NoNewline ("`r" + $line.PadRight(80))
            }
            $findings = @(Invoke-Audit -OnProgress $progressCallback)
            Write-Host -NoNewline ("`r" + (" " * 80) + "`r")
            Save-AuditCache -Findings $findings

            # Default: select only critical findings, fall back to all if none
            $selection = @{}
            $hasCritical = $findings | Where-Object { $_.Severity -eq 'critical' }
            foreach ($f in $findings) {
                $selection[$f.Id] = $hasCritical ? ($f.Severity -eq 'critical') : $true
            }
            $cursor = 0
            $vpTop = 0
            $needAudit = $false
        }

        if ($findings.Count -eq 0) {
            Clear-Host
            Write-Host ""
            Write-Host "  $Bold$Ice System Audit$Reset"
            Write-Host ""
            Write-Host "  $Green$([char]0x2713)$Reset All checks passed — no issues found"
            Write-Host ""
            Wait-ForUser
            return
        }

        # Inner key loop — every iteration rebuilds items so [*]/[ ] markers
        # reflect current selection state, then renders one frame.
        Clear-Host
        $prevLines = 0
        $_ui = _Enter-RawUI

        try {
            while ($true) {
                # Rebuild items list with current selection markers
                $items = [System.Collections.Generic.List[string]]::new()
                $findingByIdx = @{}
                $selectIdx = [System.Collections.Generic.List[int]]::new()

                $byCategory = $findings | Group-Object -Property Category | Sort-Object Name
                foreach ($group in $byCategory) {
                    $items.Add("--- $($group.Name) ---")
                    foreach ($f in $group.Group) {
                        $marker = $selection[$f.Id] ? "$Green[*]$Reset" : "$Dim[ ]$Reset"
                        $sevGlyph = switch ($f.Severity) {
                            'critical' { "$Red$([char]0x2717)$Reset" }
                            'warning'  { "$Yellow!$Reset" }
                            default    { "$Cyan$([char]0x203A)$Reset" }
                        }
                        $line = "$marker $sevGlyph $($f.Title)"
                        $itemIdx = $items.Count
                        $items.Add($line)
                        $selectIdx.Add($itemIdx)
                        $findingByIdx[$itemIdx] = $f
                    }
                }

                if ($cursor -ge $selectIdx.Count) { $cursor = $selectIdx.Count - 1 }
                if ($cursor -lt 0) { $cursor = 0 }

                # Build hint footer
                $selectedCount = ($findings | Where-Object { $selection[$_.Id] }).Count
                $up   = [char]0x2191
                $dn   = [char]0x2193
                $sp   = [char]0x2423
                $ent  = [char]0x21B5
                $dot  = [char]0x00B7
                $hint = "$up$dn move  $sp toggle  a all  c critical  d detail  r re-run  $ent apply  esc back"
                if ($selectedCount -gt 0) {
                    $hint += "   $Dim$dot$Reset $Cyan$selectedCount apply$Reset"
                }

                $prevLines = _Draw-InteractiveBox -Title "System Audit" `
                    -Items $items.ToArray() `
                    -HighlightIndex $selectIdx[$cursor] `
                    -PrevLines $prevLines `
                    -VpTop ([ref]$vpTop) `
                    -NoBox -Hint $hint

                # Read key
                [Console]::TreatControlCAsInput = $true
                $k = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                [Console]::TreatControlCAsInput = $_ui.CtrlC
                $vk = $k.VirtualKeyCode
                $ch = $k.Character

                # Ctrl+C / Esc → back without applying
                if ($ch -eq [char]3 -or $vk -eq 27) { return }

                # Up / Down navigation
                if ($vk -eq 38) {
                    if ($cursor -gt 0) { $cursor-- }
                    continue
                }
                if ($vk -eq 40) {
                    if ($cursor -lt $selectIdx.Count - 1) { $cursor++ }
                    continue
                }

                # Space → toggle current
                if ($vk -eq 32) {
                    $f = $findingByIdx[$selectIdx[$cursor]]
                    $selection[$f.Id] = -not $selection[$f.Id]
                    continue
                }

                # Enter → apply all selected
                if ($vk -eq 13) {
                    $toApply = @($findings | Where-Object { $selection[$_.Id] })
                    if ($toApply.Count -eq 0) { return }
                    Write-Host ""
                    Write-Log -Message "Applying $($toApply.Count) selected fix(es)..." -Level INFO
                    $applied = 0; $failed = 0
                    foreach ($f in $toApply) {
                        if (Invoke-AuditApply -Finding $f) { $applied++ } else { $failed++ }
                    }
                    Write-Host ""
                    Write-Log -Message "Done: $applied applied, $failed failed" -Level $(if ($failed -eq 0) { 'SUCCESS' } else { 'WARNING' })
                    Wait-ForUser
                    $needAudit = $true
                    break  # exit inner loop, outer loop re-audits
                }

                # 'a' → toggle all
                if ($ch -eq 'a' -or $ch -eq 'A') {
                    $allOn = ($findings | Where-Object { -not $selection[$_.Id] }).Count -eq 0
                    foreach ($f in $findings) { $selection[$f.Id] = -not $allOn }
                    continue
                }

                # 'd' → detail screen for current finding
                if ($ch -eq 'd' -or $ch -eq 'D') {
                    try { [Console]::CursorVisible = $true } catch { $null = $_ }
                    $f = $findingByIdx[$selectIdx[$cursor]]
                    $applied = Show-AuditFindingDetail -Finding $f
                    try { [Console]::CursorVisible = $false } catch { $null = $_ }
                    if ($applied) {
                        $needAudit = $true
                        break  # re-audit
                    }
                    # Refresh on return — Clear-Host so prose from detail vanishes
                    Clear-Host
                    $prevLines = 0
                    continue
                }

                # 'r' → re-run audit
                if ($ch -eq 'r' -or $ch -eq 'R') {
                    $needAudit = $true
                    break  # re-audit
                }

                # 'c' → apply all critical findings
                if ($ch -eq 'c' -or $ch -eq 'C') {
                    try { [Console]::CursorVisible = $true } catch { $null = $_ }
                    Invoke-ApplyAllCritical -Findings $findings
                    Wait-ForUser
                    try { [Console]::CursorVisible = $false } catch { $null = $_ }
                    $needAudit = $true
                    break  # re-audit
                }
            }
        } finally {
            _Exit-RawUI $_ui
        }
    }
}

# Entry point — only when invoked directly (not when dot-sourced from tests)
if ($MyInvocation.InvocationName -ne '.') {
    Initialize-Logging -ModuleName "audit"
    Show-AuditWizard
}

. "$PSScriptRoot\..\..\scripts\Common.ps1"
. "$PSScriptRoot\Audit.Probes.ps1"

# Audit engine — loads finding definitions from config/audit_findings.json,
# dispatches each finding's `detect.probe` against the live system via
# reflection, and returns the list of findings whose condition holds.
#
# Output format: an array of [PSCustomObject] each containing the original
# finding metadata plus runtime fields:
#   - Evidence  : string from the probe explaining what was observed
#   - Found     : true (only applicable findings are returned)
#
# The engine is pure: no UI, no apply logic, no caching. UI lives in
# Audit.Menu.ps1; apply logic in remediation handlers (Phase 4+).

function Get-AuditFindingsPath {
    # Resolves the path to audit_findings.json regardless of how this script
    # was invoked (dot-sourced from a test, called from menu, etc.).
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $repoRoot "config\audit_findings.json"
}

function Read-AuditFindings {
    # Loads finding definitions from JSON and returns the parsed array.
    # Throws if the file is missing or malformed.
    $path = Get-AuditFindingsPath
    if (-not (Test-Path $path)) {
        throw "audit_findings.json not found at $path"
    }
    $raw = Get-Content -Path $path -Raw -ErrorAction Stop
    $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $parsed.findings) {
        throw "audit_findings.json missing top-level 'findings' array"
    }
    return $parsed.findings
}

function Invoke-AuditProbe {
    # Dispatches a single finding's detect probe via reflection.
    # Returns @{ found, evidence } from the probe, or @{ found=$false; evidence="probe error: ..." }
    # if the probe is missing, throws, or returns malformed data.
    param(
        [Parameter(Mandatory)][PSCustomObject]$Detect
    )
    $probeName = $Detect.probe
    if (-not $probeName) {
        return @{ found = $false; evidence = "missing probe name" }
    }
    $cmd = Get-Command -Name $probeName -CommandType Function -ErrorAction SilentlyContinue
    if (-not $cmd) {
        return @{ found = $false; evidence = "unknown probe: $probeName" }
    }

    # Convert PSCustomObject args → hashtable for splatting
    $argHash = @{}
    if ($Detect.args) {
        foreach ($prop in $Detect.args.PSObject.Properties) {
            $argHash[$prop.Name] = $prop.Value
        }
    }

    try {
        $result = & $probeName @argHash
        if ($result -isnot [hashtable] -or -not $result.ContainsKey('found')) {
            return @{ found = $false; evidence = "probe '$probeName' returned malformed result" }
        }
        return $result
    } catch {
        return @{ found = $false; evidence = "probe '$probeName' threw: $($_.Exception.Message)" }
    }
}

function Invoke-Audit {
    # Runs all findings against the current system. Returns an array of
    # PSCustomObjects representing applicable findings (only those where the
    # probe returned found=$true). The full original metadata is preserved
    # plus an Evidence string from the probe.
    #
    # If a probe returns dynamic_cost (e.g. real Get-Process RSS), the engine
    # merges those keys into the finding's cost block and flips type to
    # 'measured' — overriding the static JSON estimate.
    #
    # -OnProgress receives a hashtable @{ index, total, title } after each
    # probe so the caller can render a progress line.
    param(
        [scriptblock]$OnProgress
    )

    $findings = Read-AuditFindings
    $applicable = [System.Collections.Generic.List[PSCustomObject]]::new()
    $i = 0
    $total = $findings.Count

    foreach ($finding in $findings) {
        $i++
        if ($OnProgress) {
            try { & $OnProgress @{ index = $i; total = $total; title = $finding.title } } catch { $null = $_ }
        }

        $result = Invoke-AuditProbe -Detect $finding.detect
        if ($result.found) {
            # Merge dynamic_cost from the probe into the static cost from JSON.
            # Convert PSCustomObject → hashtable so we can mutate it cleanly.
            $cost = @{}
            if ($finding.cost) {
                foreach ($prop in $finding.cost.PSObject.Properties) {
                    $cost[$prop.Name] = $prop.Value
                }
            }
            if ($result.ContainsKey('dynamic_cost') -and $result.dynamic_cost) {
                foreach ($k in $result.dynamic_cost.Keys) {
                    $cost[$k] = $result.dynamic_cost[$k]
                }
                $cost['type'] = 'measured'
            }

            $applicable.Add([PSCustomObject]@{
                Id          = $finding.id
                Category    = $finding.category
                Severity    = $finding.severity
                Title       = $finding.title
                Description = $finding.description
                Evidence    = $result.evidence
                Cost        = [PSCustomObject]$cost
                Remediation = $finding.remediation
            })
        }
    }

    return $applicable.ToArray()
}

function Get-AuditCachePath {
    # Single rolling cache location — overwritten on each save, never appended.
    $base = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($env:HOME) { $env:HOME } else { [System.IO.Path]::GetTempPath() }
    $dir = Join-Path $base "Winrift\audit"
    if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
    return Join-Path $dir "last.json"
}

function Save-AuditCache {
    # Persists the latest audit result to a single rolling file. Used by the
    # menu to show a fast preview on re-entry while a fresh audit runs in
    # parallel. Never accumulates dated files.
    param([Parameter(Mandatory)][object[]]$Findings)
    $payload = [PSCustomObject]@{
        timestamp = (Get-Date).ToString('o')
        findings  = $Findings
    }
    try {
        $payload | ConvertTo-Json -Depth 10 | Set-Content -Path (Get-AuditCachePath) -Encoding UTF8 -ErrorAction Stop
    } catch {
        Write-Verbose "Audit cache save failed: $($_.Exception.Message)"
    }
}

function Read-AuditCache {
    # Returns the cached findings array, or $null if no cache exists.
    $path = Get-AuditCachePath
    if (-not (Test-Path $path)) { return $null }
    try {
        $payload = Get-Content -Path $path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        return $payload.findings
    } catch {
        return $null
    }
}


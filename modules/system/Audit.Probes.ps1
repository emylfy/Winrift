. "$PSScriptRoot\..\..\scripts\Common.ps1"

# Audit probes — pure functions called by Audit.Engine via reflection.
#
# Each probe takes a hashtable of args (splatted from a finding's `detect.args`
# JSON object) and returns a hashtable: @{ found = [bool]; evidence = [string] }.
#
# Convention: `found = $true` means **the issue is present** and the finding
# applies to the current system. `evidence` is a short human-readable string
# explaining what was observed.
#
# All probes must be cheap (< 100 ms) and side-effect-free — no writes, no
# network, no admin checks. The engine runs every probe on every audit pass.

function _Get-RegistryValueOrDefault {
    # Returns the registry value at $Path\$Name, or $Default if missing.
    # Used by all registry probes so the "missing key" semantic is uniform.
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        $Default = $null
    )
    try {
        $item = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        return $item.$Name
    } catch {
        return $Default
    }
}

function Test-RegistryValueEquals {
    # found = $true if the value at Path\Name equals Expected.
    # Use for: "service is enabled (=1) which is bad".
    param(
        [Parameter(Mandatory)][string]$path,
        [Parameter(Mandatory)][string]$name,
        [Parameter(Mandatory)]$expected,
        $treat_missing_as = $null
    )
    $current = _Get-RegistryValueOrDefault -Path $path -Name $name -Default $treat_missing_as
    $found = ($current -eq $expected)
    $evidence = $null -eq $current ? "$name is not set" : "$name = $current (expected $expected)"
    return @{ found = $found; evidence = $evidence }
}

function Test-RegistryValueNotEquals {
    # found = $true if the value at Path\Name does NOT equal Expected.
    # Use for: "should be 1 (good) but is anything else".
    param(
        [Parameter(Mandatory)][string]$path,
        [Parameter(Mandatory)][string]$name,
        [Parameter(Mandatory)]$expected,
        $treat_missing_as = $null
    )
    $current = _Get-RegistryValueOrDefault -Path $path -Name $name -Default $treat_missing_as
    $found = ($current -ne $expected)
    $evidence = $null -eq $current ? "$name is not set (expected $expected)" : "$name = $current (expected $expected)"
    return @{ found = $found; evidence = $evidence }
}

function Test-RegistryValueGreaterThan {
    # found = $true if the value at Path\Name is numerically > Threshold.
    # Use for: "telemetry level should be 0 (Security) but is higher".
    param(
        [Parameter(Mandatory)][string]$path,
        [Parameter(Mandatory)][string]$name,
        [Parameter(Mandatory)][int]$threshold,
        $treat_missing_as = $null
    )
    $current = _Get-RegistryValueOrDefault -Path $path -Name $name -Default $treat_missing_as
    $numeric = 0
    $isNumeric = [int]::TryParse([string]$current, [ref]$numeric)
    $found = ($isNumeric -and $numeric -gt $threshold)
    $evidence = $null -eq $current ? "$name is not set (treated as $treat_missing_as)" : "$name = $current (threshold $threshold)"
    return @{ found = $found; evidence = $evidence }
}

function Test-ServiceRunning {
    # found = $true if the service exists and is in the Running state.
    # Use for: "SysMain is running on this SSD system".
    param(
        [Parameter(Mandatory)][string]$name
    )
    try {
        $svc = Get-Service -Name $name -ErrorAction Stop
        $found = ($svc.Status -eq 'Running')
        $evidence = "$name service: $($svc.Status)"
    } catch {
        $found = $false
        $evidence = "$name service not installed"
    }
    return @{ found = $found; evidence = $evidence }
}

function Test-AppxPackageInstalled {
    # found = $true if an AppX package matching the wildcard is installed.
    # Use for: "Copilot/Recall/OneDrive UWP package present".
    param(
        [Parameter(Mandatory)][string]$pattern
    )
    try {
        $pkgs = Get-AppxPackage -Name $pattern -AllUsers -ErrorAction SilentlyContinue
        if ($pkgs) {
            $names = ($pkgs | Select-Object -ExpandProperty Name) -join ', '
            return @{ found = $true; evidence = "installed: $names" }
        }
        return @{ found = $false; evidence = "no package matching '$pattern'" }
    } catch {
        return @{ found = $false; evidence = "AppX query failed: $($_.Exception.Message)" }
    }
}

function Test-RegistryValueExists {
    # found = $true if the registry value Path\Name exists at all.
    # Use for: detecting Run/RunOnce entries that shouldn't be there.
    param(
        [Parameter(Mandatory)][string]$path,
        [Parameter(Mandatory)][string]$name
    )
    try {
        $null = Get-ItemProperty -Path $path -Name $name -ErrorAction Stop
        return @{ found = $true; evidence = "$name is set in $path" }
    } catch {
        return @{ found = $false; evidence = "$name not present" }
    }
}

function Test-FsutilBehavior {
    # found = $true if `fsutil behavior query <key>` returns a value matching expected.
    # Use for: TRIM (DisableDeleteNotify), 8.3 names, etc.
    # The probe runs fsutil and parses "key = value" output. Reports found when
    # the parsed value equals $expected (i.e. "issue is present at expected value").
    param(
        [Parameter(Mandatory)][string]$key,
        [Parameter(Mandatory)][int]$expected
    )
    try {
        $output = & fsutil behavior query $key 2>&1
        if ($LASTEXITCODE -ne 0) {
            return @{ found = $false; evidence = "fsutil query failed: $output" }
        }
        # Output format on modern Win: "DisableDeleteNotify (DwordValue) = 0x0"
        if ($output -match '=\s*(?:0x)?([0-9a-fA-F]+)') {
            $current = [Convert]::ToInt32($Matches[1], 16)
            $found = ($current -eq $expected)
            return @{ found = $found; evidence = "$key = $current (issue if $expected)" }
        }
        return @{ found = $false; evidence = "fsutil output not parseable: $output" }
    } catch {
        return @{ found = $false; evidence = "fsutil unavailable: $($_.Exception.Message)" }
    }
}

function Test-MMAgentFeature {
    # found = $true if a Get-MMAgent property has a value matching $expected.
    # Use for: memory compression, page combining, OperationAPI checks.
    param(
        [Parameter(Mandatory)][string]$property,
        [Parameter(Mandatory)]$expected
    )
    try {
        $agent = Get-MMAgent -ErrorAction Stop
        $current = $agent.$property
        $found = ($current -eq $expected)
        return @{ found = $found; evidence = "MMAgent.$property = $current (issue if $expected)" }
    } catch {
        return @{ found = $false; evidence = "MMAgent unavailable: $($_.Exception.Message)" }
    }
}

function Test-DnsServersFromList {
    # found = $true if NONE of the active interfaces' DNS servers are in the
    # known-fast list. Use for: "user is on default ISP DNS, run DNS Benchmark".
    # known_good_csv: comma-separated list of "good" DNS server IPs.
    param(
        [Parameter(Mandatory)][string]$known_good_csv
    )
    try {
        $known = $known_good_csv -split ',' | ForEach-Object { $_.Trim() }
        $servers = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop |
                   Where-Object { $_.ServerAddresses -and $_.InterfaceAlias -notmatch 'Loopback|isatap|Teredo' } |
                   ForEach-Object { $_.ServerAddresses } |
                   Where-Object { $_ }
        if (-not $servers) { return @{ found = $false; evidence = "no DNS servers configured" } }
        $matched = $servers | Where-Object { $_ -in $known }
        if ($matched) {
            return @{ found = $false; evidence = "using known fast DNS: $($matched -join ', ')" }
        }
        return @{ found = $true; evidence = "current DNS: $($servers -join ', ') (none in known-good list)" }
    } catch {
        return @{ found = $false; evidence = "DNS query failed: $($_.Exception.Message)" }
    }
}

function Get-RegistryRunCount {
    # found = $true if the Run/RunOnce key under $path has more than $threshold
    # entries. Use for: "you have 14 startup apps, consider pruning".
    # Returns dynamic_cost.startup_count so the UI can show the exact number.
    param(
        [Parameter(Mandatory)][string]$path,
        [Parameter(Mandatory)][int]$threshold
    )
    try {
        if (-not (Test-Path $path)) {
            return @{ found = $false; evidence = "$path does not exist" }
        }
        $entries = Get-ItemProperty -Path $path -ErrorAction Stop |
                   Get-Member -MemberType NoteProperty |
                   Where-Object { $_.Name -notmatch '^PS' }
        $count = ($entries | Measure-Object).Count
        $found = ($count -gt $threshold)
        return @{
            found        = $found
            evidence     = "$count entries in $path (threshold $threshold)"
            dynamic_cost = @{ startup_count = $count }
        }
    } catch {
        return @{ found = $false; evidence = "Run key query failed: $($_.Exception.Message)" }
    }
}

function Test-ProcessRSSExceeds {
    # found = $true if any process matching the name pattern is currently using
    # more than $threshold_mb of working set memory. Returns the offending
    # process name + RSS in evidence AND a dynamic_cost block so the engine can
    # show the real measured RAM in the UI instead of an estimate from JSON.
    # Use for: "Copilot is consuming 250+ MB right now".
    param(
        [Parameter(Mandatory)][string]$name_pattern,
        [Parameter(Mandatory)][int]$threshold_mb
    )
    try {
        $procs = Get-Process -Name $name_pattern -ErrorAction SilentlyContinue
        if (-not $procs) {
            return @{ found = $false; evidence = "no process matching '$name_pattern'" }
        }
        $totalMb = [math]::Round((($procs | Measure-Object WorkingSet64 -Sum).Sum / 1MB), 0)
        $found = ($totalMb -gt $threshold_mb)
        return @{
            found        = $found
            evidence     = "$name_pattern total RSS: $totalMb MB (threshold $threshold_mb)"
            dynamic_cost = @{ ram_mb = $totalMb }
        }
    } catch {
        return @{ found = $false; evidence = "process query failed: $($_.Exception.Message)" }
    }
}

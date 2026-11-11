. "$PSScriptRoot\..\..\scripts\Common.ps1"

Initialize-Logging -ModuleName "dns"

$script:DnsProviders = @(
    @{ Name = "Cloudflare";     Primary = "1.1.1.1";         Secondary = "1.0.0.1" }
    @{ Name = "Google";         Primary = "8.8.8.8";         Secondary = "8.8.4.4" }
    @{ Name = "Quad9";          Primary = "9.9.9.9";         Secondary = "149.112.112.112" }
    @{ Name = "NextDNS";        Primary = "45.90.28.0";      Secondary = "45.90.30.0" }
    @{ Name = "OpenDNS";        Primary = "208.67.222.222";  Secondary = "208.67.220.220" }
    @{ Name = "AdGuard";        Primary = "94.140.14.14";    Secondary = "94.140.15.15" }
    @{ Name = "CleanBrowsing";  Primary = "185.228.168.168"; Secondary = "185.228.169.168" }
    @{ Name = "Comodo";         Primary = "8.26.56.26";      Secondary = "8.20.247.20" }
)

function Set-WinriftBenchmarkDns {
    param([hashtable]$Provider)

    $adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object Status -EQ 'Up' | Sort-Object Name)
    if (-not $adapters.Count) {
        $null = Show-InteractiveMenu -Title 'Choose Network Adapter' -Items @('No active network adapters found.', '---', 'B › Back')
        return
    }

    $items = @(for ($i = 0; $i -lt $adapters.Count; $i++) { "$i › $($adapters[$i].Name)" })
    $choice = Show-InteractiveMenu -Title 'Choose Network Adapter' -Items ($items + @('---', 'B › Back'))
    if ($null -eq $choice -or $choice -eq 'B') { return }
    $adapter = $adapters[[int]$choice]
    $servers = @($Provider.Primary, $Provider.Secondary)
    $choice = Show-InteractiveMenu -Title 'Confirm DNS Change' -Items @(
        "Provider: $($Provider.Name)",
        "Adapter: $($adapter.Name)",
        "DNS servers: $($servers -join ', ')",
        'This replaces the DNS servers for this adapter.',
        '---', 'A › Apply DNS', 'B › Back'
    )
    if ($choice -ne 'A') { return }

    $message = if ($env:WINRIFT_DRY_RUN -eq '1') {
        "Would set DNS to $($Provider.Name) on $($adapter.Name)."
    } else {
        try {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $servers -ErrorAction Stop
            "DNS set to $($Provider.Name) on $($adapter.Name)."
        } catch {
            Write-Log "Could not set DNS on $($adapter.Name): $($_.Exception.Message)" -Level ERROR -Quiet
            'Could not change DNS. See Help → Open Logs for details.'
        }
    }
    $null = Show-InteractiveMenu -Title 'DNS Change Result' -Items @($message, '---', 'B › Back to Results')
}

function Invoke-DnsBenchmark {
    $choice = Show-InteractiveMenu -Title 'DNS Benchmark' -Items @(
        'Compare DNS lookup times for a domain.',
        '---', 'D › Use example.com', 'C › Enter a Domain or URL', 'B › Back'
    )
    if ($null -eq $choice -or $choice -eq 'B') { return }

    $domain = 'example.com'
    if ($choice -eq 'C') {
        Clear-Host
        while ($true) {
            $inputDomain = (Read-Host 'Domain or URL (blank to cancel)').Trim()
            if (-not $inputDomain) { return }
            if ($inputDomain -notmatch '://') { $inputDomain = 'https://' + $inputDomain }
            $uri = $null
            if ([uri]::TryCreate($inputDomain, [UriKind]::Absolute, [ref]$uri) -and
                $uri.Scheme -in @('http', 'https') -and $uri.HostNameType -eq [UriHostNameType]::Dns -and
                $uri.DnsSafeHost.TrimEnd('.') -match '\.') {
                $domain = $uri.IdnHost.TrimEnd('.')
                break
            }
            Write-Host 'Enter a domain such as example.com or an HTTP(S) URL.'
        }
    }

    Clear-Host
    $queries = 5
    $results = @()
    $vpnAdapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
        $_.InterfaceDescription -match 'VPN|WireGuard|Tunnel|TAP|TUN' -and $_.Status -eq 'Up'
    })
    try {
        foreach ($provider in $script:DnsProviders) {
            Write-Progress -Activity "Testing DNS for $domain" -Status $provider.Name -PercentComplete (100 * $results.Count / $script:DnsProviders.Count)
            $times = @()
            for ($i = 0; $i -lt $queries; $i++) {
                $watch = [System.Diagnostics.Stopwatch]::StartNew()
                try {
                    $answer = @(Resolve-DnsName -Name "$domain." -Server $provider.Primary -Type A -DnsOnly -NoHostsFile -QuickTimeout -ErrorAction Stop)
                    $watch.Stop()
                    if ($answer.Type -contains 'A') { $times += $watch.Elapsed.TotalMilliseconds }
                } catch {
                    Write-Log "DNS lookup via $($provider.Name) failed: $($_.Exception.Message)" -Level INFO -Quiet
                }
            }
            $average = if ($times.Count) { ($times | Measure-Object -Average).Average }
            $results += [pscustomobject]@{ Provider = $provider; Successes = $times.Count; Average = $average }
        }
    } finally {
        Write-Progress -Activity "Testing DNS for $domain" -Completed
    }

    $ranked = @($results | Where-Object Successes -EQ $queries | Sort-Object Average)
    $partial = @($results | Where-Object Successes -LT $queries | Sort-Object Successes -Descending)
    $items = @("Domain: $domain", "Average IPv4 lookup time · $queries requests per provider")
    if ($vpnAdapters.Count) { $items += 'VPN detected. Results reflect this connection.' }
    $items += '---'
    foreach ($result in $ranked) {
        $items += "$($result.Provider.Name)  $([math]::Round($result.Average, 1)) ms  ($queries/$queries)"
    }
    foreach ($result in $partial) {
        $items += "$($result.Provider.Name)  $($result.Successes)/$queries lookups succeeded"
    }
    if (-not $ranked.Count) { $items += 'No provider answered all requests.' }
    $items += '---'
    if ($ranked.Count) { $items += 'C › Choose DNS Provider' }
    $items += 'B › Back'

    while ((Show-InteractiveMenu -Title 'DNS Results' -Items $items) -eq 'C') {
        $providerItems = @(for ($i = 0; $i -lt $ranked.Count; $i++) {
            "$i › $($ranked[$i].Provider.Name)  $([math]::Round($ranked[$i].Average, 1)) ms"
        })
        $choice = Show-InteractiveMenu -Title 'Choose DNS Provider' -Items ($providerItems + @('---', 'B › Back'))
        if ($null -ne $choice -and $choice -ne 'B') {
            Set-WinriftBenchmarkDns -Provider $ranked[[int]$choice].Provider
        }
    }
}

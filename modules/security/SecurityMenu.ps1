. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "Security & Privacy Tools"

Initialize-Logging -ModuleName "security"

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

function Invoke-DnsBenchmark {
    Clear-Host
    $domain = "example.com"
    $queries = 5

    # VPN detection
    $vpnAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
        $_.InterfaceDescription -match 'VPN|WireGuard|Tunnel|TAP|TUN' -and $_.Status -eq 'Up'
    }
    if ($vpnAdapters) {
        Write-Log -Message "VPN detected ($($vpnAdapters[0].InterfaceDescription)). Results may not reflect normal DNS performance." -Level WARNING
        Write-Host ""
    }

    Write-Host "$Cyan  Benchmarking $($script:DnsProviders.Count) DNS providers ($queries queries each)...$Reset"
    Write-Host ""

    $results = @()
    foreach ($provider in $script:DnsProviders) {
        Write-Host -NoNewline "  $Dim$($provider.Name.PadRight(16))$Reset"
        $times = @()
        for ($i = 0; $i -lt $queries; $i++) {
            try {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                Resolve-DnsName -Name $domain -Server $provider.Primary -Type A -DnsOnly -ErrorAction Stop | Out-Null
                $sw.Stop()
                $times += $sw.Elapsed.TotalMilliseconds
            } catch {
                $sw.Stop()
                $times += $sw.Elapsed.TotalMilliseconds
            }
        }
        $avg = ($times | Measure-Object -Average).Average
        $color = if ($avg -lt 20) { $Green } elseif ($avg -lt 50) { $Yellow } else { $Red }
        Write-Host "$color$([math]::Round($avg, 1)) ms$Reset"
        $results += @{ Name = $provider.Name; Primary = $provider.Primary; Secondary = $provider.Secondary; Avg = $avg }
    }

    $ranked = $results | Sort-Object { $_.Avg }
    $best = $ranked[0]

    Write-Host ""
    Write-Log -Message "Fastest: $($best.Name) ($([math]::Round($best.Avg, 1)) ms)" -Level SUCCESS
    Write-Host ""
    Write-Host -NoNewline "  Apply $Cyan$($best.Name)$Reset?  $Green[Y]$Reset Apply   $Dim[N]$Reset Pick other   $Dim[Esc]$Reset Skip  "

    $key  = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $char = $key.Character.ToString().ToUpper()
    $vk   = [int]$key.VirtualKeyCode

    $selected = $null
    if ($char -eq "Y") {
        Write-Host "$Green[Y]$Reset"
        $selected = $best
    } elseif ($char -eq "N") {
        Write-Host "$Dim[N]$Reset"
        Write-Host ""
        for ($i = 0; $i -lt $ranked.Count; $i++) {
            $r     = $ranked[$i]
            $color = if ($r.Avg -lt 20) { $Green } elseif ($r.Avg -lt 50) { $Yellow } else { $Red }
            Write-Host "  $Cyan$($i + 1)$Reset  $($r.Name.PadRight(16))$color$([math]::Round($r.Avg, 1)) ms$Reset"
        }
        Write-Host "  $Dim0$Reset  Skip"
        Write-Host ""
        $raw = Read-Host "  Select (1-$($ranked.Count), 0 to skip)"
        $n = 0
        if ([int]::TryParse($raw.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $ranked.Count) {
            $selected = $ranked[$n - 1]
        }
    }

    if ($selected) {
        Write-Host ""
        $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notmatch 'VPN|Loopback|Virtual' } | Select-Object -First 1
        if ($adapter) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses @($selected.Primary, $selected.Secondary) -ErrorAction Stop
            Write-Log -Message "DNS set to $($selected.Name) on $($adapter.Name)" -Level SUCCESS
        } else {
            Write-Log -Message "No suitable network adapter found." -Level ERROR
        }
    }
    Wait-ForUser
}

function Show-SecurityMenu {
    $menuRoot = $PSScriptRoot
    Invoke-MenuLoop -Title "Security & Privacy Tools" -Items @(
        "1 › DefendNot - Disable Windows Defender",
        "2 › RemoveWindowsAI - Remove Copilot & Recall",
        "3 › Privacy.sexy - Enforce privacy and security",
        "4 › DNS Benchmark - Test & apply fastest DNS",
        "---",
        "5 › Back to menu"
    ) -Actions @{
        "1" = { Start-AdminProcess -ScriptPath "$menuRoot\DefendNot.ps1" }
        "2" = { Start-AdminProcess -ScriptPath "$menuRoot\RemoveWindowsAI.ps1" }
        "3" = { Start-AdminProcess -ScriptPath "$menuRoot\PrivacySexy.ps1" }
        "4" = { Invoke-DnsBenchmark }
    } -ExitKey "5"
}

Show-SecurityMenu

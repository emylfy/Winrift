# Testing & Benchmarks

Winrift includes a built-in performance benchmark that measures real system metrics before and after applying tweaks.

## Quick Start

**Step 1.** Run the benchmark **before** applying any tweaks:

```powershell
. .\modules\system\Benchmark.ps1
Invoke-Benchmark -Phase Before
```

**Step 2.** Apply your tweaks through the Winrift menu.

**Step 3.** Run the benchmark **after** tweaks (reboot recommended first):

```powershell
. .\modules\system\Benchmark.ps1
Invoke-Benchmark -Phase After
```

The comparison report is displayed automatically and saved to `%USERPROFILE%\Winrift\benchmarks\`.

To re-view the last report without collecting new data:

```powershell
Invoke-Benchmark -Phase Compare
```

## Benchmark Menu

From the main menu, select **Benchmark** to access:

| Option | Action |
| :---: | :--- |
| 1 | Run Benchmark (Before tweaks) |
| 2 | Run Benchmark (After tweaks) |
| 3 | View Last Report |
| 4 | [System Health Score](health_score.md) — composite 0–100 rating across 7 categories |
| 5 | Back |

**Recommended workflow:** Before → Apply tweaks → Reboot → After → Compare → Health Score.

## Metrics

| Metric | Source | What It Shows |
| :--- | :--- | :--- |
| CPU idle load | `\Processor(_Total)\% Processor Time` | Background CPU usage at rest — fewer services = lower idle load |
| RAM usage | `Win32_OperatingSystem` | Physical memory consumed — disabled services free RAM |
| Committed memory | `\Memory\Committed Bytes` | Virtual memory pressure including page file |
| Running processes | `Get-Process` | Total process count — direct measure of background bloat |
| Running services | `Get-Service` | Active Windows services — tweaks disable unnecessary ones |
| Startup apps | `Win32_StartupCommand` | Programs that auto-launch on boot |
| Scheduled tasks | `Get-ScheduledTask` | Active tasks (Ready state) — maintenance tweaks reduce these |
| Disk read latency | `\PhysicalDisk(_Total)\Avg. Disk sec/Read` | Storage response time — SSD/NVMe tweaks improve this |
| Disk write latency | `\PhysicalDisk(_Total)\Avg. Disk sec/Write` | Storage write response time |
| DPC rate | `\Processor(_Total)\DPC Rate` | Deferred Procedure Calls — system latency indicator |
| Context switches/sec | `\System\Context Switches/sec` | CPU scheduling overhead — lower is better |
| Interrupts/sec | `\Processor(_Total)\Interrupts/sec` | Hardware interrupt rate — affected by interrupt steering tweak |
| Page faults/sec | `\Memory\Page Faults/sec` | Memory paging activity — memory optimization impact |

All sampled metrics are averaged over 10 readings at 3-second intervals (~30 seconds total).

## Interpreting Results

The report shows a before/after comparison table for all metrics with percentage change.

- **▼** indicates a decrease (typically better for all metrics)
- **▲** indicates an increase (typically worse for resource metrics)

### Expected Ranges

These are typical improvements on a clean Windows 11 24H2 install:

| Metric | Typical Improvement |
| :--- | :--- |
| CPU idle load | 30–70% reduction |
| RAM usage | 15–30% reduction |
| Running processes | 20–40% reduction |
| Running services | 10–25% reduction |
| DPC rate | 20–40% reduction |
| Context switches | 15–30% reduction |

Actual results depend on hardware, installed software, and which tweak categories were applied.

## Output Files

All benchmark data is stored in `%USERPROFILE%\Winrift\benchmarks\`:

| File | Description |
| :--- | :--- |
| `before_{timestamp}.json` | Raw metrics snapshot before tweaks |
| `after_{timestamp}.json` | Raw metrics snapshot after tweaks |
| `report_{timestamp}.md` | Markdown comparison report |

## Limitations

- **Reboot recommended** between before/after snapshots — some tweaks require a restart to take effect
- **Close background apps** before measuring — browsers, editors, and other apps affect metrics
- **Hardware-dependent** — results vary significantly between systems
- **GPU tweaks** are not measured — GPU performance requires specialized tools (FrameView, CapFrameX)
- **Network tweaks** — throughput/latency changes require external test servers to measure accurately
- **Single-point measurement** — for statistically significant results, run multiple before/after cycles

## Health Score

The benchmark menu includes a **System Health Score** (option 4) that rates your system's optimization state across 7 weighted categories: Latency, Privacy, Memory, Network, Process Bloat, Startup, and Storage.

It reuses `Get-PerformanceSnapshot` with reduced sampling (3 samples at 2-second intervals) and adds configuration checks (privacy registry keys, storage settings, network state).

Full documentation: [Health Score Guide](health_score.md)

## Pester Tests

Unit tests for the benchmark module are at `tests/Benchmark.Tests.ps1`. Run them with:

```powershell
Invoke-Pester ./tests/Benchmark.Tests.ps1
```

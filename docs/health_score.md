# System Health Score

Composite 0-100 rating of your system's optimization state across 7 weighted categories.

## Usage

**Benchmark > System Health Score** from the main menu. Scan takes ~10 seconds.

The report shows each category with a score bar, detail, and delta since last run. Below that: drift summary (how many tweaks still hold) and recommendations for categories below 60.

Colors: green (80+), yellow (50+), red (below 50). Delta values like `+5` show change since last saved score.

## Categories

| Category | Weight | Measures |
| :--- | :---: | :--- |
| Latency | 20% | DPC rate, context switches, interrupts |
| Privacy | 20% | Telemetry, Copilot, Recall, activity history, ad ID |
| Memory | 15% | RAM usage, commit ratio, page faults |
| Network | 15% | Throttling, lazy mode, Nagle, TCP autotuning |
| Process Bloat | 10% | Running processes and services |
| Startup | 10% | Startup apps, scheduled tasks |
| Storage | 10% | SSD/NVMe, TRIM, prefetcher, last access |

## Scoring

Each metric is scored against threshold bands with linear interpolation between them. The composite score is a weighted average.

**Privacy** starts at 100 with deductions: telemetry (-25), diagnostic data (-15), Copilot (-20), Recall (-15), activity history (-10), ad ID (-15).

**Storage** and **Network** start at 0 with points added per optimization detected.

**Recall** is only penalized if the feature actually exists on the system (Win11 24H2+ with compatible hardware).

## Output

Scores saved to `%USERPROFILE%\Winrift\health\score_{timestamp}.json`. Previous scores are loaded automatically for delta comparison on the next run.

## vs Benchmark

Health Score gives a point-in-time optimization rating. Benchmark measures before vs. after with full sampling. Health Score reuses `Get-PerformanceSnapshot` with reduced sampling (3 samples, 2s intervals).

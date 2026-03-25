# Drift Detection

Tracks whether Windows Updates or other processes silently revert your Winrift tweaks.

## How it works

Every time Winrift applies a tweak, it saves the expected registry value to `desired_state.json`. Drift detection compares those saved values against the current registry state and reports any differences.

Three states per entry:
- **OK** — value matches
- **Drifted** — value changed (shows current vs expected)
- **Missing** — registry key or value was deleted

## Usage

**System Tweaks > Drift Detection** from the main menu.

### Check for drift

Scans all tracked entries and shows a report grouped by tweak category. Each drifted entry shows current value vs expected. If drift is found, you can reapply all values in one step. A reboot is recommended after reapply.

### Auto-check after Windows Update

Registers a scheduled task (`Winrift-DriftCheck`) triggered by Windows Update Event ID 19. Runs as SYSTEM, logs results to `~/Winrift/logs/drift-auto_*.log`.

The task only detects and logs — it does not auto-reapply. Check logs or run a manual scan to fix.

Toggle on/off from the same menu option.

### Clear desired state

Deletes `desired_state.json` and stops monitoring. Use when starting fresh or switching tweak categories. Apply tweaks again to rebuild.

## Data

Desired state file: `%USERPROFILE%\Winrift\tweaks\desired_state.json`

```json
{
  "Path": "HKLM:\\...\\SystemProfile",
  "Name": "NetworkThrottlingIndex",
  "Value": 4294967295,
  "Type": "DWord",
  "Category": "Network Optimization"
}
```

Entries are upserted — reapplying a tweak updates the existing entry, no duplicates.

## Health Score integration

The System Health Score includes a drift summary:

```
44/45 tweaks holding (98%)
1 drifted - run Drift Detection to fix
```

Quick overview without a full scan.

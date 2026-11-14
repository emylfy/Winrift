# Validation and known limits

## Recorded baseline — 5 November 2026

The results below describe the historical checkout and environment listed here, not a certification of every later commit or supported machine. For a new revision, consult its CI run and record manual results using the [setup validation procedure](setup.md#manual-validation).

## Environment and baseline

- Windows 11 26H2, build 26300.9711, ARM64, Parallels VM.
- Original checkout: branch `product-finish`, HEAD `4642bc9502db613eb0b14c8253bada07f6b59c8c`.
- Standalone portable runtime: PowerShell 7.6.9. Automated test host: PowerShell 7.6.5.

## Results

| Check | Result |
| --- | --- |
| Pester 5.7.1, complete suite | 241 passed, 0 failed, 0 skipped |
| PSScriptAnalyzer 1.24.0 | 0 Error-severity findings |
| PowerShell 5.1 parser | Winrift.ps1, RequirePwsh.ps1, Start-Winrift.ps1 and launch.ps1 pass |
| Git whitespace check | Pass with `core.whitespace=cr-at-eol`, preserving the existing committed CRLF file |
| Ordinary Winrift.cmd | PS5 → portable PS7 → same-user UAC → main menu; bootstrap exit 0 |
| Path with spaces and an apostrophe | Actual copied-checkout headless dry-run completed; bootstrap exit 0 and transcript ended normally |
| UI | Main menu manually reviewed on the recorded VM; viewport tests cover normal and narrow dimensions |
| Source presets | NVIDIA 5/5, AMD 30/30 and DirectX 14/14 paths/names/types/values match pinned upstream fixtures, allowing detected AMD adapter targeting |

The tests cover partial package failures and retained retry items, unknown installed versions, persisted queues, corrupt state preservation, atomic state replacement, preview/dry-run without native writes, external tools blocked during dry-run, typed registry checks, conflict-safe registry/file/native Undo, partial service-operation state, versioned configuration backups, profile migration/preflight, path traversal rejection, Organizer collisions and UAC argument quoting. Mocked failures print red diagnostic lines intentionally; they are passing negative tests.

Source checks used actual winget queries. The four Store packages were checked against msstore, not the winget source. Existing Desktop Tools remain catalog entries; the current YASB ID is AmN.yasb. RustDesk.RustDesk and Octol1ttle.ElyPrismLauncher were unavailable on the checked source/system and remain retained entries with explicit installation failure reporting rather than silent removal or substitution.

## Configuration-state probes

Read-only checks confirmed NTFS/ReFS TRIM notification queries, last-access query, MMAgent ApplicationPreLaunch/PageCombining and SystemParametersInfo reads for accessibility flags and menu delay on this target. These are configuration/API observations. No measured performance gain, physical storage behavior, driver stability or reboot persistence is inferred from them.

## Limits and excluded checks

- Real AMD/NVIDIA hardware, complete preset before/after workloads, reboot/stability checks and a cross-architecture matrix were not available/performed on this VM. Vendor presets and preemption retain explicit compatibility caveats.
- Windows Terminal and console-host resize behavior was not exhaustively tested manually in both hosts. The shared renderer is dimension-tested and the running UI was reviewed by the user.
- Same-account UAC and complex argument paths were tested. Elevation under a different Windows account is explicitly rejected before configuration changes; this is not a validated alternate-account workflow.
- Full ISO creation, boot and fresh-install-to-setup verification were not performed. Parser and embedding tests do not establish a full install-cycle result. The ISO workflow remains experimental.
- File/app/history deletion, updates, drivers and external tools are not universally reversible. Legacy state without enough expected-state information is retained rather than blindly overwritten.
- The upstream MMCSS source uses LazyMode=0; the existing NoLazyMode=1 action is preserved without inferring a replacement or network-packet benefit.

## Recovery boundaries

Prior state is journaled before supported writes. Backups remain versioned; failed or interrupted operations do not become successful merely because a section opened or a registry value was written. Upgrade migration preserves old desired-state data and backups and removes only the named Winrift-DriftCheck task. Uninstall preserves backups and source files.

Automated tests exercise configuration and registry restoration, failure handling, and conflict detection. They do not substitute for a fresh Windows installation, reboot persistence checks, or physical GPU measurements. Record those separately; do not infer them from a passing CI run.
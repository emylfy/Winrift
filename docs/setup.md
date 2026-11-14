# Save and restore your Windows setup

Save Setup captures the supported parts of your environment in a JSON file. Keep that file somewhere that survives a reinstall, then use Restore Setup on the new installation.

## What travels with you

| Section | Included | Limits |
| --- | --- | --- |
| Windows | Supported registry values that exist and supported readable native settings | Not every Windows preference; hardware-specific AMD/NVIDIA presets are not a portable driver backup |
| Apps | Selected package IDs and their sources from `winget export` | No installers, app data, activation keys, or pinned package versions; sources must still provide the packages |
| Terminal & PowerShell | Supported Terminal, shell, prompt and FastFetch configuration files | Only the recognized files are captured |
| Editors | Supported editor settings and extension IDs | Extensions are installed from the available editor CLI; extension data is not a complete editor backup |
| GlazeWM | Supported GlazeWM configuration | Other desktop files and applications require separate backup |

This is not a system image or a backup of documents. Saved configurations can contain executable shell settings or private data. Winrift skips some obvious credential assignments, but that heuristic cannot guarantee a secret-free file. Review a setup before transferring or sharing it.

## Save

1. Configure Windows and applications as desired.
2. Open **Save / Restore Setup → Save Setup**.
3. Select the sections to capture. If exporting apps, review the package list.
4. Review the captured items and save to a new JSON file. Existing setup files are preserved.
5. Copy the JSON to your backup location. Back up personal files separately.

## Restore

1. Start Winrift on the new Windows installation with the same Windows account you want to configure.
2. Open **Save / Restore Setup → Restore Setup** and enter the saved JSON path.
3. Select the sections to restore and review the proposed items.
4. Choose **Back Up and Apply**. Inspect the individual results; skipped, unavailable, and failed items need attention.
5. Restart Windows where required. Open the restored applications and verify their settings.

App installs require an internet connection and the relevant package source. Editor extension restoration requires that editor's CLI. Install the editor first if its CLI is unavailable. Only supported configuration files and Windows targets are restored; a legacy import does not silently become a full system snapshot.

## Undo and recovery

For supported operations, use **Undo Changes → Action History** to restore the previous registry/file/native state or **Restore Configuration Backup** for backed-up configs. If a target changed after Winrift wrote it, Undo reports a conflict instead of overwriting that later edit. Installing apps, deleting data, and invoking external tools do not have universal rollback.

## Manual validation

Use disposable Windows installations with snapshots. Record the Winrift version/commit, Windows edition/build, architecture, PowerShell version, package-source availability, and whether the machine is a VM or physical hardware. Mark unrun steps as **not tested**, not passed.

| Step | Action | Evidence to retain |
| --- | --- | --- |
| 1. Baseline | Start from a clean source installation; snapshot it | Environment and original values/file hashes |
| 2. Configure | Apply a small reviewed setting, install a test app, change a supported terminal/editor config | Individual operation results and observed settings |
| 3. Save | Export Windows, apps, and the configured application sections | Setup JSON and its SHA256; redact private content before sharing |
| 4. Fresh target | Use a second clean installation with a different baseline | Target environment and pre-restore state |
| 5. Preview | Launch with `Winrift.cmd -DryRun`, restore the saved setup | Preview results; verify target settings/configs did not change |
| 6. Restore | Launch normally and restore the selected sections | Per-item results, installed app IDs, restored file hashes and native/registry values |
| 7. Reboot | Restart and open restored applications | Persistence and functional observations |
| 8. Undo | Undo a supported setting and configuration write | Exact original value/type or file bytes restored |
| 9. Conflict | Apply again, edit the target manually, then attempt Undo | Conflict reported; later edit remains intact |
| 10. Failure | Exercise an unavailable package and retry it | Failure visible; retry queue retains unsuccessful items |

Record both successful and failed observations. A VM run does not validate physical AMD/NVIDIA driver behavior. Run x64 and ARM64 separately before claiming both are validated.

For the experimental installation-media path, additionally build the ISO, boot a fresh VM, complete Windows Setup, and verify the embedded setup at first sign-in and after reboot. A successful ISO build alone is insufficient.

For performance claims, separately record hardware, driver versions, workload, repeated baseline/modified runs, variability, power/thermal behavior, and a reverted baseline. A registry value matching its intended value is not a performance result.

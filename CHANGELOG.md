# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Calendar Versioning](https://calver.org/) (YY.M.patch format).

## [26.3.16] - 2026-03-26

### Menu polish, README cleanup, health score fix

- Changed main menu order — App Bundles (5) before Customize (6), workflow order
- Changed System Tweaks menu — reordered: actions (1-4), then Drift Detection (5) + Restore (6), then Back (7); added separators between groups
- Changed all `Read-Host ">"` prompts to `Read-Host " "` (clean cursor, no symbol) across all modules
- Changed `Invoke-MenuLoop` default prompt from `>` to ` `
- Removed custom prompts from Tweaks, Benchmark, WinScript menus
- Removed "Explore & Learn" section header from main menu (plain divider)
- Removed "Third-party tools/scripts fetched from the web" labels from Community Tools, Apps, Spotify, Security menus
- Removed Security menu "Third-party" header moved to top (removed entirely)
- Removed `Write-Progress` blue bar — replaced with `[N/total]` text counter in tweak loop; removed "Applying X tweaks..." headers from all tweak functions
- Added `$ProgressPreference = 'SilentlyContinue'` to Common.ps1 globally
- Changed `Invoke-Tool` — skips `[SUCCESS]` message for `browser` type tools
- Removed `Install-MacOSCursor` function and menu item (broken .inf install)
- Changed `logo.png` → `screenshot-main.png`; added `screenshot-features.png` for Features section
- Changed README — removed Windows icon from title, removed slogan from menu title, cleaned table padding, single features screenshot, 80% hero image
- Changed `cat.txt` → `fastfetch.txt` with Windows logo ASCII art; updated references in fastfetch.jsonc and Customize.Configs.ps1
- Added `scrollbarState: hidden` to Windows Terminal defaults in terminal.json
- Changed version display in menu — shows `v26.3` (major.minor only), patch stays in version.json
- Fixed health score detail padding — removed manual 30-char pad, let Show-MenuBox handle alignment

## [26.3.15] - 2026-03-25

### Customize reorganization, admin elevation, versioning, polish

- Reorganized Customize menu — merged Editor Configs + App Themes into "Apps", merged Windows Look & Feel into "Windows"; 6 categories reduced to 4 with inline descriptions
- Added "Import VSCode Config" flow — description + GitHub preview link before editor selection; replaces flat 7-editor list
- Removed macOS Cursor from Customize (broken, unreliable .inf install)
- Changed `Winrift.ps1` — added `Assert-AdminOrElevate` at startup; all inline modules inherit admin
- Fixed `Assert-AdminOrElevate` — uses `(Get-PSCallStack)[1].ScriptName` to re-launch correct script on elevation
- Fixed `Start-UserProcess` — uses `runas /trustlevel:0x20000` to actually drop admin privileges; prefers `wt.exe` when available
- Fixed `Set-RegistryValue` — added `-ErrorAction Stop` to `Set-ItemProperty`; no more false `[SUCCESS]` on "Access denied"
- Changed `Invoke-Tool` — skips `[SUCCESS]` message for `browser` type tools (just opens URL)
- Changed `Write-Progress` replaced with `[N/total]` text counter in tweak loop; removed "Applying X tweaks..." headers from all tweak functions
- Added `$ProgressPreference = 'SilentlyContinue'` globally — kills blue progress bar (also speeds up `Invoke-WebRequest` in PS 5.1)
- Fixed `Benchmark.ps1` — restored standalone guard for test compatibility; uses `&` call operator from Winrift
- Switched to CalVer + patch versioning (`YY.M.patch`) — retroactive tags `v26.3.0` through `v26.3.14` on all March commits
- Updated docs — removed UI box elements from `health_score.md`, `drift_detection.md`, `tests.md`
- Updated tests — fixed `Start-TweakSession` and `Save-TweakBackup` tests for accumulated session model

## [26.3.14] - 2026-03-25

### UI overhaul, inline modules, health score v2, logging, bugfixes

#### UI Redesign
- Changed `Show-MenuBox` in `Common.ps1` — new rounded Unicode borders (`╭╮╰╯─│`) with dimmed gray frame (`$Dim`, 243), bright purple title, section headers as colored text instead of `├─┤` dividers, top/bottom padding inside box
- Changed menu item style — replaced `[1]` brackets with `1 ›` arrows across all 20+ PS1 files
- Changed `Confirm-ExternalTool` — rewritten to use `Show-MenuBox` instead of manual `+---+` / `'` border drawing
- Added `$Dim` color variable to `Common.ps1` for border rendering
- Added UTF-8 BOM to all `.ps1` source files for PowerShell 5.1 Unicode compatibility
- Added `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` to `Common.ps1`
- Fixed ANSI-aware padding in `Show-MenuBox` — strips escape codes before calculating padding width so colored items align correctly

#### Inline Module Execution
- Changed `Winrift.ps1` — admin modules (Benchmark, Tweaks, Security, Drivers, ISO) now run inline via dot-source instead of `Start-AdminProcess`; reduces 7+ terminal tabs to 1 main window
- Changed `Tweaks.ps1` — renamed `Show-MainMenu` to `Show-TweaksMenu` to avoid name conflict with Winrift; removed `Assert-AdminOrElevate`
- Changed `SecurityMenu.ps1` — removed redundant `AdminLaunch.ps1` dot-source; DefendNot/RemoveWindowsAI/PrivacySexy still launch as separate processes (web script isolation)
- Changed `ISOBuilder.ps1` — removed `Assert-AdminOrElevate`; conditional `Common.ps1` load for inline compatibility
- Changed `Benchmark.ps1` — removed standalone guard; always runs entry function
- Customize and App Bundles remain as separate user-space processes (no admin)

#### Health Score v2
- Added delta comparison — loads previous score from `~/Winrift/health/`, shows `(+17)` / `(-5)` next to each category and composite score
- Added drift summary — quick scan of `desired_state.json`, shows "60/63 tweaks holding (95%)" with drift count and fix hint
- Added actionable recommendations — categories below 60 score show specific action (e.g. "Apply Network tweaks", "Run Security & Privacy from main menu")
- Fixed Recall detection — now checks if Recall feature actually exists on the system (WindowsAI registry key or Recall AppX package) before penalizing; no more false "Recall active" on systems without Recall
- Fixed health score detail padding — pads detail text (including colored delta) by visible length so right border aligns

#### Session Management
- Changed restore point to once-per-session — `$script:RestorePointCreated` flag in `Common.ps1` prevents duplicate restore points; `-WarningAction SilentlyContinue` suppresses Windows 1440-minute warning
- Changed tweak backup to accumulate — `Start-TweakSession` no longer clears entry lists; `Save-TweakBackup`/`Save-DesiredState` called once on exit from `Invoke-UniversalTweaks` instead of per-action
- Changed `Invoke-UniversalTweaks` — session init (restore point + start session) moved outside loop, save moved after loop exit; shows "No tweaks were applied" when all categories skipped

#### Tweaks UX
- Changed tweak categories menu — opt-in categories (`System Maintenance`, `DirectX Enhancements`) moved to separate "Advanced" section with divider; renumbered 10-13
- Added Y/N confirmation with impact warning before applying opt-in categories
- Changed category selection input — accepts spaces, commas, or mix (`1 3 5`, `1,3,5`, `1, 3 5`)
- Removed duplicate warnings from `Invoke-SystemMaintenanceTweaks` and `Invoke-DirectXTweaks` (now shown in pre-apply prompt)
- Fixed `<16GB` parse error — replaced with `less than 16GB` (PS 5.1 reserved operator)
- Fixed `|` pipe parse error in success box — replaced manual `|` border with `Write-Log -Level SUCCESS`

#### Logging
- Added `Initialize-Logging` to DefendNot, RemoveWindowsAI, PrivacySexy, ExternalLauncher, WinScript, Organizer, Benchmark (standalone)
- Fixed `ISOBuilder.ps1` — added `-ModuleName "isobuilder"` to `Initialize-Logging`

#### Bugfixes
- Fixed `Show-MenuBox` section header padding — was 1 character short causing misaligned right border
- Fixed duplicate "Report saved" messages in `Benchmark.ps1` — removed `Write-Host "Saved to:"` and `return $filePath` from `Save-Snapshot`/`Save-TweakBackup`/`Export-BenchmarkReport`
- Fixed "View Last Report" — shows user-friendly messages when Before/After snapshots missing instead of internal error
- Fixed `Customize.Apps.ps1` — restored `$Matches[1]`/`$Matches[2]` broken by batch `[N]` → `N ›` replacement
- Fixed SSD tweaks raw output — `fsutil`/`Disable-ScheduledTask` output piped to `Out-Null`, `Write-Host` replaced with `Write-Log`
- Fixed Power Management raw output — `powercfg` output piped to `Out-Null`
- Fixed drift detection — removed `Wait-ForUser` from "No drift detected" path to avoid double prompt
- Fixed DefendNot — checks `Invoke-Tool` return value; shows Tamper Protection hint on failure
- Fixed PrivacySexy — removed duplicate `[R] Review project source` from menu (already in confirmation dialog)
- Fixed SecurityMenu — removed `-NoExit` from `Start-AdminProcess` calls (was leaving PS prompt open)
- Fixed PC Manager install — soft fallback to Microsoft Store on `0x80004004` error
- Changed `Install-WingetPackage` — added `--silent` + `--disable-interactivity` for clean output; added `-ShowProgress` switch for large packages (used by UniGetUI)

## [26.3.13] - 2026-03-25

### Health Score, drift detection, desired state tracking, pipeline fixes

- Added `modules/system/HealthScore.ps1` — composite 0-100 system health score across 7 categories (Latency, Memory, Process Bloat, Startup, Privacy, Storage, Network) with weighted scoring, threshold-band interpolation, visual bar display, and JSON persistence to `~/Winrift/health/`
- Added `modules/system/Tweaks.Drift.ps1` — drift detection system that compares current registry values against saved desired state; supports manual scan with one-click reapply, scheduled task triggered by Windows Update (Event ID 19), and desired state reset
- Added `Save-DesiredState` to `Common.ps1` — persists every successful `Set-RegistryValue` write to `desired_state.json` with upsert logic (merges by Path+Name); `$script:DesiredStateCategory` tracks tweak category per write
- Added "System Health Score" as `[4]` in Benchmark menu (`Benchmark.ps1`)
- Added "Drift Detection" as `[6]` in System Tweaks menu (`Tweaks.ps1`)
- Changed GPU menu (`Tweaks.GPU.ps1`) — inlined `Invoke-HybridTweaks` into menu actions; each GPU tweak action now saves desired state and tweak backup
- Changed `Tweaks.Universal.ps1`, `Tweaks.Power.ps1` — tweak sessions now save desired state after application
- Changed main menu title to include version (`Winrift v$AppVersion`); separator changed from `---` to `--- Explore & Learn ---`
- Changed `Show-MenuBox` in `Common.ps1` — improved separator width calculation and item padding
- Fixed pipeline pollution — added `$null =` to `Invoke-Tool`, `Install-WingetPackage`, `Invoke-NativeCommand` calls in `Customize.Apps.ps1`, `Customize.Desktop.ps1`, `PrivacySexy.ps1`, `Tweaks.Cleanup.ps1`, `WinScript.ps1`
- Removed lowercase `winrift.ps1` duplicate — only `Winrift.ps1` (PascalCase) remains
- Added `tests/HealthScore.Tests.ps1` — function exports, `Get-ThresholdScore` interpolation, `Format-ScoreBar` rendering, scorer unit tests, `Get-CompositeScore` weighting
- Added `tests/Drift.Tests.ps1` — function exports, `Save-DesiredState` schema validation, upsert merge logic
- Updated `tests/ModuleExports.Tests.ps1` — added Drift and HealthScore function lists, added backup/restore exports to Common.ps1 tests

## [26.3.12] - 2026-03-25

### ISO Builder, community files, README overhaul, autounattend fix

- Added `modules/iso/ISOBuilder.ps1` — embed `autounattend.xml` into a Windows 11 ISO, producing a ready-to-burn image with oscdimg.exe (auto-downloaded from Microsoft Symbol Server with Y/N/A confirmation)
- Added answer file selection in ISO Builder — choose Winrift default or custom `autounattend.xml` via file picker; explains what the answer file does before embedding
- Added ISO Builder as main menu item `[7]` in `Winrift.ps1`; runs with admin elevation
- Added `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1 summary with private reporting via GitHub Security Advisories
- Added `.github/PULL_REQUEST_TEMPLATE.md` — Summary, Risk, Testing checklist, Screenshots sections
- Added `.github/dependabot.yml` — weekly GitHub Actions version updates
- Changed `docs/autounattend.xml` — regenerated via schneegans generator with `BypassNetworkCheck=true` (BypassNRO); adds "I don't have internet" option during OOBE so users can choose Microsoft or local account
- Changed main menu numbering — Community Tools shifted to `[8]`, Docs & Guides to `[9]`
- Changed `Install-WingetPackage` — added `-Source` parameter for msstore packages; centralized `$WINGET_ALREADY_INSTALLED` constant to `Common.ps1` (removed duplicates from `Drivers.ps1`, `Tweaks.Cleanup.ps1`)
- Refactored `Drivers.ps1` — `Install-IntelDSA` and Lenovo Vantage install now use `Install-WingetPackage` helper instead of inline winget calls
- Refactored `Tweaks.Cleanup.ps1` — PC Manager install now uses `Install-WingetPackage` helper
- Changed `Tweaks.Universal.ps1` — marked System Maintenance `[10]` and DirectX Enhancements `[13]` as opt-in only (excluded from "Apply ALL safe tweaks")
- Updated README — new tagline, version badge, "Why Winrift?" section, updated features table with ISO Builder and tweak categories, rollback troubleshooting entry

## [26.3.11] - 2026-03-24

### Lint cleanup, PSScriptAnalyzer fixes

- Fixed PSScriptAnalyzer issues — empty catch blocks in `Common.ps1` and `Benchmark.ps1` now use `Write-Verbose`, removed unused `$result` in `ExternalLauncher.ps1`, `$output` in `Common.ps1`
- Changed CI lint rules — removed `PSUseApprovedVerbs` from enabled rules, excluded noisy rules (`PSUseSingularNouns`, `PSUseBOMForUnicodeEncodedFile`, `PSUseDeclaredVarsMoreThanAssignments`, `PSAvoidUsingPositionalParameters`, `PSAvoidOverwritingBuiltInCmdlets`, `PSAvoidUsingEmptyCatchBlock`)

## [26.3.10] - 2026-03-24

### Kill navigation recursion, tweak rollback, CI hardening, cleanup

- Removed `Invoke-ReturnToMenu` — eliminated recursive script re-invocation via temp file; sub-windows now close naturally when module exits
- Removed `-NoExit` from all `Start-AdminProcess`/`Start-UserProcess` calls in `winrift.ps1` — sub-windows are ephemeral
- Removed recursive `& "$PSScriptRoot\SecurityMenu.ps1"` calls from `DefendNot.ps1`, `RemoveWindowsAI.ps1` — replaced with `return`
- Removed `OnExit { Invoke-ReturnToMenu }` from `Tweaks.ps1`, `SecurityMenu.ps1`, `WinScript.ps1`, `PrivacySexy.ps1`
- Removed unused `chocolatey` entry from `tools.json`
- Added tweak rollback system — `Start-TweakSession`, `Save-TweakBackup`, `Restore-TweakBackup` in `Common.ps1`; `Set-RegistryValue` now auto-captures previous values before writing
- Added "Restore Previous Tweaks" menu option to `Tweaks.ps1`
- Added tweak consequence warnings: RAM check for Memory tweaks (<16GB), laptop detection for Power tweaks (ChassisTypes), UNSAFE_COMMAND_BUFFER_REUSE warning for DirectX, AutoEndTasks data loss warning, maintenance disable warning
- Changed `AdminLaunch.ps1` `$Arguments` parameter from `[string]` to `[string[]]` — fixes broken paths with spaces from `.Split(' ')`
- Changed CI (`lint.yml`) from `ubuntu-latest` to `windows-latest` for both lint and test jobs
- Changed CI lint job to `exit 1` on PSScriptAnalyzer findings (was silent `Write-Warning`)
- Changed `powercfg` in `Tweaks.Power.ps1` from useless `try/catch` to `$LASTEXITCODE` check
- Changed Docs submenu `break docsLoop` to `continue docsLoop` — user can open multiple docs without re-entering submenu
- Changed `ExternalLauncher.ps1` — added `Pause-ForUser` so user sees result before window closes
- Changed `UniGetUI.ps1` — removed `Assert-WingetAvailable` from startup (1-3s delay); winget only checked when actually installing
- Updated tests: removed `Invoke-ReturnToMenu` tests, added tweak backup system tests, added multi-line log tests

## [26.3.9] - 2026-03-23

### Rename Windots to Customize, fix pipeline leaks, restore backups, config quality

- Renamed `modules/windots/` to `modules/customize/` — all files renamed from `Windots.*` to `Customize.*`
- Added `Customize.Desktop.ps1` — GlazeWM, Zebar/YASB, Flow Launcher, Windhawk, Rainmeter, wallpaper browser
- Added GlazeWM config (`config/glazewm/config.yaml`) with height resize keybindings (alt+i/o)
- Added PowerShell 7 profile to `terminal.json`
- Added `Restore-ConfigBackup` function — scans for `.bak` files across all config locations, shows date/size, restore one or all
- Added `Install-WingetPackage` helper to `Common.ps1` — unified winget install with exit code handling, already-installed detection, `| Out-Host` to prevent pipeline pollution
- Added `Pause-ForUser` helper to `Common.ps1`
- Added `Start-UserProcess` to `AdminLaunch.ps1` for launching modules without elevation (WT tab support)
- Added Wiki link to Docs & Guides submenu
- Added `rectify11` entry to `tools.json`
- Changed `Show-MenuBox` to auto-calculate width from content (no more overflow past box borders)
- Changed Customize and App Bundles to run without admin elevation (`Start-UserProcess`)
- Changed `Invoke-ReturnToMenu` placement inside `try/finally` in `Customize.ps1`
- Changed `Copy-ConfigFiles` backup logic — preserves original `.bak`, won't overwrite on repeat runs
- Changed `Set-PwshConfig` to use `[Environment]::GetFolderPath('MyDocuments')` instead of hardcoded path
- Changed `Set-WinTermConfig` to properly handle font cancel in combo selection
- Changed Oh My Posh, Starship, FastFetch installers to use `Install-WingetPackage` instead of raw `Start-Process winget`
- Changed Starship, Oh My Posh, FastFetch menus — moved descriptions inside menu box instead of loose `Write-Log` above
- Changed `Install-Starship` to show both PS 5.1 and PS 7+ profile paths
- Changed `Disable-QuickAccess` — proper COM object cleanup, polling-based Explorer restart
- Changed `Install-MacOSCursor` — inlined download with `Invoke-WebRequest`/`Get-FileHash`, `try/finally` for temp cleanup, combined path traversal regex
- Changed macOS Cursor in `tools.json` from `browser` type to `download` with SHA256 hash verification
- Changed UniGetUI package ID from `MartiCliment.UniGetUI` to `Devolutions.UniGetUI`
- Changed UniGetUI install check from slow `winget list` to instant `Test-Path` for UniGetUI.exe
- Changed PC Manager install from `Microsoft.PCManager` to `9PM860492SZD --source msstore`
- Changed Intel DSA to launch after install/already-installed
- Changed DefendNot to clean previous installation before re-install (fixes ExtractToDirectory conflict)
- Changed RemoveWindowsAI to run as separate `powershell.exe` process (fixes GUI not showing)
- Fixed pipeline pollution in `Invoke-Tool`, `Invoke-SecureScript`, `Install-WingetPackage` — added `| Out-Host` to prevent `True`/`False` leaking to console
- Fixed `Invoke-SecureScript`/`Invoke-SecureDownload` — removed noisy "No hash provided" warning (only 1 of 14 tools has a hash)
- Fixed em-dash encoding (`—` → `--`) in Common.ps1 warning messages for PS 5.1
- Fixed PowerShell profile — replaced `Write-Warning` on startup with silent skip
- Removed 13 redundant breadcrumb settings from VSCode `settings.json` (only `breadcrumbs.enabled: false` needed)
- Removed dead `stickyScroll.scrollWithEditor`/`scrolling` settings, duplicate `layoutControl` from VSCode config
- Removed `Windots.Apps.ps1`, `Windots.Configs.ps1`, `Windots.Customization.ps1`, `Windots.Menu.ps1`, `windots.ps1`, `config/vscode/snippet.txt`
- Renamed `Set-WallpaperPack` to `Open-WallpaperBrowser`
- Updated menu text "Windows Terminal config + Fira Code" → "Windows Terminal config + Nerd Font"
- Changed README security note from collapsible `<details>` to blockquote
- Changed `Benchmark.ps1` — added `$env:USERPROFILE` fallback chain for benchmark directory path
- Changed `Initialize-Logging` — wrapped `Start-Transcript` in try/catch for locked file handling
- Updated README, CONTRIBUTING, tests, and Customize README to match all renames

## [26.3.8] - 2026-03-22

### Rebrand to Winrift, menu restructure, benchmark promotion, config flatten

- Rebranded project from Simplify11 to Winrift across all files, URLs, window titles, menus, reports, docs, and issue templates
- Renamed `simplify11.ps1` to `winrift.ps1`; updated all references in `Common.ps1`, `launch.ps1`, `install.ps1`
- Changed temp file from `simplify11_launchdir.txt` to `winrift_launchdir.txt`
- Changed user data directories from `~/Simplify11/` to `~/Winrift/` (logs, benchmarks)
- Changed `version.json` repo field from `emylfy/simplify11` to `emylfy/winrift`
- Updated all GitHub URLs, badge links, shortcut names, and ASCII art across README, CONTRIBUTING, Windots README, docs, and autounattend.xml
- Updated README tagline to "Break through default Windows" with benchmark-first positioning
- Rewrote README: features as compact table, Community Tools in collapsible `<details>` block, Answer File merged into features table, navigation links, placeholder images commented out until real files exist, honest benchmark disclaimer ("your numbers will vary")
- Restructured main menu: promoted Benchmark to #1 position as the primary feature
- Consolidated 5 external tool launchers (WinUtil, WinScript, Sparkle, GTweak) into a single "Community Tools" submenu
- Moved Answer File guide from main menu into new "Docs & Guides" submenu alongside Tweaks Guide and Benchmark Guide
- Renamed "Windots" to "Desktop Ricing" and "UniGetUI" to "App Bundles" in main menu for clarity
- Removed Benchmark and Documentation links from System Tweaks submenu (Benchmark is now top-level, docs have their own section)
- Added standalone entry point to `Benchmark.ps1` so it can be launched directly from main menu
- Refactored Windots menu: split flat menu into Terminal Setup, VSCode Configs, Third-party Apps, and Customization submenus
- Added `TargetFileNames` parameter to `Copy-ConfigFiles` for renaming files during copy
- Flattened `config/cli/` directory: removed nested subdirectories (terminal/, fastfetch/, ohmyposh/, WindowsPowershell/), all config files now live at `config/cli/` root
- Updated `Windots.Configs.ps1` paths to match flattened directory structure with file rename support
- Added Defender exclusion path for DefendNot installation directory before tool launch
- Changed `Invoke-SecureScript` to use `[ScriptBlock]::Create` instead of `Invoke-Expression` for safer script execution
- Centered menu box title in `Show-MenuBox` instead of left-aligned padding
- Added Benchmarks section to README with usage example and link to testing guide
- Added `docs/tests.md` with benchmark methodology, metrics, expected results, and Pester test instructions
- Updated Windots README paths to match flattened config directory
- Updated `ModuleExports.Tests.ps1` to match refactored Windots menu function names

### Tech debt cleanup, security flow simplification, WT tab support

- Extracted magic numbers into named constants in `Tweaks.Universal.ps1` (accessibility flags, timeouts, network throttling, priority separation) and `Tweaks.Cleanup.ps1` (PC Manager AUMID, Store link)
- Replaced hardcoded GPU indices 0000-0003 with dynamic `Get-DisplayAdapterIndices` registry scan in `Tweaks.GPU.ps1`
- Simplified DefendNot and RemoveWindowsAI: removed intermediate menus, replaced with single Y/N/R confirmation box with inline warnings and tool info
- Added `-SkipConfirm` parameter to `Invoke-Tool` in `Common.ps1` to prevent double confirmation prompts
- Added `[R] Review project source` option to PrivacySexy and WinScript menus
- Updated `AdminLaunch.ps1`: detect `$env:WT_SESSION` to open new tab in current WT window when already admin (`wt -w 0 new-tab`), fall back to new window otherwise
- Added `Common.ps1` load guard in `Benchmark.ps1` (`Get-Command Write-Log` check) to fix Pester test failure when dot-sourced
- Renamed `winrift.ps1` to `Winrift.ps1` (PascalCase); updated references in `Common.ps1`, `launch.ps1`, `CONTRIBUTING.md`
- Shortened Power Management warning text to fit within menu box width
- Cleaned VSCode settings: removed Cyrillic `allowedCharacters`, changed `cSpell.language` from `en,ru` to `en`
- Added `.mailmap` to unify 5 author name variants (Emylfy, Emalfai, emylfy, eai, ✦ Emylfy) into one

## [26.3.7] - 2026-03-21

### PowerShell 5.1 compatibility, test fixes, encoding cleanup

- Fixed all PS 7+ `$var = if () {} else {}` assignment syntax across `Common.ps1` (4 instances), `simplify11.ps1`, `UniGetUI.ps1` for PS 5.1 compatibility
- Fixed `simplify11.ps1` version.json path from root to `config/version.json` (was always showing "unknown")
- Fixed em-dash (U+2014) characters in `Common.ps1`, `Tweaks.Universal.ps1`, `ExternalLauncher.ps1` replaced with ASCII hyphen to resolve `PSUseBOMForUnicodeEncodedFile` warnings and PS 5.1 parse failures on files without BOM
- Fixed trailing whitespace in `Organizer.ps1`
- Fixed `Join-Path` calls with 3+ arguments in `Common.Tests.ps1`, `Common.Utilities.Tests.ps1`, `Config.Tests.ps1`, `ExternalLauncher.Tests.ps1` for PS 5.1 (only supports 2-argument `Join-Path`)
- Fixed `Invoke-SecureScript` test to match actual `throw` behavior on hash mismatch
- Fixed `Invoke-Tool` tests with missing `Mock Confirm-ExternalTool` to prevent null reference from unmocked `Read-Host`
- Fixed `Invoke-HybridTweaks` in `Tweaks.GPU.ps1` — no longer reports success when a GPU is not detected; now checks return values from both `Invoke-NvidiaTweaks` and `Invoke-AMDTweaks`
- Added NVIDIA GPU detection to `Invoke-NvidiaTweaks` — scans display adapter registry before applying tweaks, skips with WARNING if not found
- Changed `Invoke-NvidiaTweaks` and `Invoke-AMDTweaks` to return `$true`/`$false` indicating whether tweaks were applied

## [26.3.6] - 2026-03-21

### Power Management split, driver improvements, security hardening, docs overhaul

- Added `Tweaks.Power.ps1` — aggressive power tweaks extracted into separate module with AC power warning
- Added `Assert-WingetAvailable` in `Common.ps1` — auto-installs winget via `Add-AppxPackage`, falls back to Microsoft Store
- Added `Install-IntelDSA` in `Drivers.ps1` — Intel Driver & Support Assistant auto-install via winget
- Added registry write verification in `Set-RegistryValue` — reads back value after write to confirm success
- Added winget availability checks to Drivers, Tweaks.Cleanup, and UniGetUI modules
- Added `Initialize-Logging` to Drivers and UniGetUI modules
- Added input path validation in `Set-OtherVSCConfig`
- Added 25H2 to README compatibility table
- Changed `Invoke-SecureScript` hash mismatch from WARNING to hard ERROR with throw
- Changed `Invoke-AMDTweaks` — dynamically detects AMD GPU device index instead of assuming `\0000`
- Changed `Invoke-PowerTweaks` — split into lightweight (Universal) and aggressive (separate Power Management menu)
- Changed Drivers menu — split into GPU drivers (NVIDIA/AMD/Intel) and OEM manufacturer sections
- Changed `tweaks_guide.md` — added Table of Contents, Before You Start, risk levels, Power Management section, How to Revert, missing source attributions
- Changed `autounattend_guide.md` — updated Method 3 to tiny11maker-reforged with 25H2 support; added Unattend-Generator re-import tip
- Changed README — removed duplicate tweak description, fixed emoji duplication, added tweaks guide link

## [26.3.5] - 2026-03-16

### Secure tool dispatch, Invoke-Tool refactor, and expanded tests

- Added `Get-ToolConfig`, `Invoke-SecureScript`, `Invoke-SecureDownload`, `Invoke-Tool`, and `Invoke-NativeCommand` to `Common.ps1` — unified, config-driven tool dispatch with optional SHA256 hash verification
- Added 10 new tool entries to `config/tools.json`: `defendnot`, `privacysexy`, `removewindowsai`, `winscript`, `spotx`, `spicetify`, `steam-millennium`, `spacetheme`, `macos-cursor`, `chocolatey`
- Added `tests/Common.Utilities.Tests.ps1` — Pester tests for `Get-ToolConfig`, `Invoke-NativeCommand`, and `Invoke-SecureDownload`
- Changed `DefendNot.ps1`, `PrivacySexy.ps1`, `RemoveWindowsAI.ps1`, `WinScript.ps1`, `Windots.Apps.ps1`, `Windots.Configs.ps1` — inline `irm | iex` and download logic replaced with `Invoke-Tool`
- Changed `ExternalLauncher.ps1` — simplified from ~40 lines to ~6 using `Get-ToolConfig` + `Invoke-Tool`
- Changed `Drivers.ps1`, `SecurityMenu.ps1`, `Tweaks.ps1`, `Tweaks.GPU.ps1`, `Tweaks.Cleanup.ps1`, `Windots.Menu.ps1` — remaining inline `while` menu loops migrated to `Invoke-MenuLoop`
- Changed `Tweaks.Cleanup.ps1` — removed "Remove Virtual Memory" option; DISM commands use `Invoke-NativeCommand`; winget exit code extracted to `$WINGET_ALREADY_INSTALLED` constant
- Changed `Tweaks.Universal.ps1` — SSD tweaks wrapped in try/catch; inline comments added for accessibility registry flag values
- Changed `Tweaks.GPU.ps1` — inline comments added for AMD display adapter registry path
- Changed `UniGetUI.ps1` — winget stderr suppressed; removed redundant `Test-Winget` function
- Changed `Windots.Customization.ps1` — added Explorer restart guard after `Stop-Process explorer`
- Changed `tests/Config.Tests.ps1` — updated type whitelist to include `browser`; added `fallbackUrl` HTTPS test and `docs` property test; fixed `BeforeAll` scoping for bundle file list
- Removed "Why Simplify11?" comparison table and FAQ section from README

## [26.3.4] - 2026-03-16

### Windots refactor, Pester tests, and CI pipeline

- Added `Copy-ConfigFiles` helper in `Windots.Configs.ps1` — reusable config-copy-with-logging for all dotfile installers
- Added `Test-IsExcluded` function in `Organizer.ps1` — centralizes file/folder exclusion logic
- Added `Assert-AdminOrElevate`, `Initialize-Logging`, `Invoke-MenuLoop` utilities in `Common.ps1`
- Added smart install prompts for Oh My Posh and FastFetch — detect missing tools and offer install/skip/cancel
- Added Pester test suite (`tests/`) — Common.ps1 functions, config validation, ExternalLauncher params, module exports, script syntax
- Added Pester CI job in `.github/workflows/lint.yml` with NUnit XML artifact upload
- Added DefendNot, RemoveWindowsAI, and Sparkle to README tools grid
- Changed Windots modules from `.psm1` to `.ps1` — dot-sourced instead of `Import-Module`, all `Export-ModuleMember` blocks removed
- Changed `Organizer.ps1` migrated from `Write-Host` to `Write-Log` throughout
- Changed `ExternalLauncher.ps1` header from `Write-Header` to `Write-Log`
- Changed `Windots.Customization.ps1` uses shared `Set-RegistryValue` instead of `Set-ItemProperty` with inline try/catch
- Changed `Set-OtherVSCConfig` delegates to `Set-VSCodeConfig` instead of duplicating copy logic
- Changed `Set-VSCodeConfig` validates target path before copying
- Changed Steam Millennium install from piped `irm | iex` to direct `.exe` download
- Changed CI workflow renamed from "PSScriptAnalyzer" to "CI"; path triggers expanded to include `config/**` and `tests/**`
- Changed README tools grid expanded to 8 entries (two rows of 4 at 25% width)
- Changed Windots README rewritten — emoji-free headings, structured tables for Configs/Apps/Customization
- Changed main menu box width normalized to 59 characters
- Changed `Write-Log` catch block now surfaces warning instead of silently swallowing errors
- Fixed `Expand-StartFolders` path resolution — uses `$PSScriptRoot` directly instead of double parent traversal

## [26.3.3] - 2026-03-16

### Bundle overhaul, return-to-menu navigation, and documentation rewrite

- Added `Invoke-ReturnToMenu` in `Common.ps1` — reads saved launch directory from temp file and re-launches `simplify11.ps1` in the same window
- Added launch directory persistence — `simplify11.ps1` writes `$PSScriptRoot` to `$env:TEMP\simplify11_launchdir.txt` at startup so child modules can navigate back
- Added `CreativeMedia.ubundle` — new bundle with Audacity, CapCut, Affinity, OBS Studio, Spotify, YouTube Music
- Added "Creative & Media" category in UniGetUI app category menu
- Added "Back to menu" option in UniGetUI install prompt
- Added "Open Documentation" option in Tweaks menu
- Added Claude, Android Studio, fastfetch, scrcpy, Android SDK Platform-Tools, FFmpeg to Development bundle
- Added Telegram Desktop to Communications bundle
- Changed "Back to menu" across all modules to use `Invoke-ReturnToMenu` — returns to main menu instead of leaving empty prompt (Drivers, DefendNot, PrivacySexy, RemoveWindowsAI, SecurityMenu, Tweaks, WinScript, UniGetUI, Windots)
- Changed `Windots.Menu.psm1` — dot-sources `Common.ps1` for module scope access to `Invoke-ReturnToMenu`
- Changed Tweaks menu reordered — GPU Tweaks moved before Free Up Space
- Changed UniGetUI refactored — conditional install prompt (`Show-InstallPrompt`) shown only when not installed, then straight to app categories
- Changed media/creative apps split from Productivity into new CreativeMedia bundle; dev tools moved from Utilities to Development; Raycast to Productivity; Proton Pass and RustDesk to Utilities; Flow Launcher to Productivity
- Changed bundle `export_version` upgraded to 3; removed verbose `InstallationOptions`/`Updates` metadata from Games and Utilities bundles
- Changed bundle `incompatible_packages_info` text updated from "WingetUI" to "UniGetUI"
- Changed `ExternalLauncher.ps1` — moved `Common.ps1` import after `param` block (fixes script parameter handling)
- Changed UniGetUI bundle path resolution updated to use project root `config\bundles\` with PascalCase names
- Changed `docs/autounattend_guide.md` fully rewritten — stage-by-stage installation breakdown, removed apps table, warnings section, and improved installation methods
- Changed `iwr` replaced with `irm` and dub.sh shortlinks replaced with direct GitHub raw URLs
- Changed updated project logo
- Removed unused `Simplify11` function from `Windots.Menu.psm1`

## [26.3.2] - 2026-03-15

### Loop menus, Show-MenuBox, logging, and Tweaks submodules

- Added reusable `Show-Menu` framework in `Common.ps1` — eliminates hundreds of lines of duplicated menu code
- Added `Write-Header` helper in `Common.ps1` for consistent section headers
- Added `Test-AdminRights` helper in `Common.ps1` for checking admin elevation
- Added `Get-AppVersion` function in `Common.ps1` — centralized version loading from `config/version.json`
- Added screenshot template filenames defined: `media/screenshot-main.png`, `media/screenshot-tweaks.png`, `media/screenshot-security.png`, `media/demo.gif`
- Changed all module menus refactored to use the shared `Show-Menu` framework (SecurityMenu, DefendNot, RemoveWindowsAI, PrivacySexy, WinScript, UniGetUI, Drivers/Lenovo, Windots, Tweaks)
- Changed `Tweaks.ps1` split into submodules: `Tweaks.Universal.ps1`, `Tweaks.GPU.ps1`, `Tweaks.Cleanup.ps1`
- Changed README.md fully rewritten — Quick Start at top, feature comparison table, screenshot placeholders, star history badge
- Changed function names standardized to use approved PowerShell verbs:
  - `Apply-Cursor` → `Set-Cursor`
  - `FreeUpSpace` → `Clear-SystemSpace`
  - `Extract-StartFolders` → `Expand-StartFolders`
  - `Configure-VSCode` → `Set-VSCodeConfig`
  - `Configure-WinTerm` → `Set-WinTermConfig`
  - `Configure-Pwsh` → `Set-PwshConfig`
  - `Configure-OhMyPosh` → `Set-OhMyPoshConfig`
  - `Configure-FastFetch` → `Set-FastFetchConfig`
  - `Run-Portable` → `Invoke-Portable`
  - All `Apply-*` tweaks functions → `Invoke-*` in `Tweaks.ps1`
  - `Check-Winget` → `Test-Winget` in `UniGetUI.ps1`
- Fixed all main menu options now behave consistently — every option auto-starts its module
- Fixed version loading centralized via `Get-AppVersion` — `simplify11.ps1` no longer reads `version.json` directly
- Fixed version tag in `CHANGELOG.md` aligned to `[26.3]` to match `version.json` (CalVer)

## [26.3.1] - 2026-03-13

### Architecture refactor with shared utilities, config-driven tools, and CI

- Added `config/` directory for centralized configuration: `version.json`, `tools.json`, `bundles/`
- Added config-driven `ExternalLauncher.ps1` — single file handles all external tool launches via `tools.json`
- Added PSScriptAnalyzer CI workflow (`.github/workflows/lint.yml`) — lints all `.ps1`/`.psm1`/`.psd1` on push and PR
- Changed `Common.ps1` expanded from 5 color variables to a full shared utilities module containing `Set-RegistryValue`, `New-SafeRestorePoint`, `Show-Menu`, `Write-Header`, and `Test-AdminRights`
- Changed `Tweaks.ps1` no longer contains its own `Set-RegistryValue` and `New-SafeRestorePoint` — uses shared versions from `Common.ps1`
- Changed `version.json` moved to `config/version.json`
- Changed UniGetUI `.ubundle` files moved to `config/bundles/`
- Changed external tools defined in `config/tools.json` instead of hardcoded wrapper scripts
- Removed `modules/privacy/` directory — `PrivacySexy.ps1` merged into `modules/security/`
- Removed individual tool wrapper files (`WinUtil.ps1`, `Sparkle.ps1`, `GTweak.ps1`) — replaced by `ExternalLauncher.ps1`
- Removed `.DS_Store` tracked file from repository

## [26.3.0] - 2026-03-10

### Code quality, safety, docs, and UX

- Added System Restore Point creation before applying any tweaks
- Added selective tweak application — choose which categories to apply
- Added session logging via `Start-Transcript` (logs saved to `~/Simplify11/logs/`)
- Added "What was changed" summary displayed after tweak application
- Added version system via `version.json` (replaces hardcoded version string)
- Added `CHANGELOG.md` for tracking project changes
- Added `CONTRIBUTING.md` with setup, testing, and PR guidelines
- Added GitHub issue templates for bug reports and feature requests
- Added comprehensive `.gitignore` for Windows, IDE, and temp files
- Added safety check for missing modules in main menu — shows friendly error instead of crashing
- Fixed inconsistent tab/space indentation in `AdminLaunch.ps1`
- Fixed main menu option "3" (Security Menu) now gets consistent sub-menu like all other options
- Fixed error handling added to all external script downloads (`irm | iex` patterns)
- Fixed menu "back" actions no longer spawn new PowerShell processes — replaced with `return` to prevent stack overflow
- Fixed removed orphaned unreachable `exit` statement in `WinScript.ps1`
- Fixed Drivers menu now uses 1-based numbering instead of 0-based, with hashtable lookup replacing fragile array indexing
- Fixed icon install path in `install.ps1` now uses `$env:APPDATA\Simplify11` subfolder instead of bare `$env:APPDATA`
- Fixed shortcut `WorkingDirectory` corrected from Start Menu path to `$env:USERPROFILE`
- Fixed ASCII art in `launch.ps1` corrected for proper rendering
- Removed `Add-MpPreference` Defender exclusion from `launch.ps1` — unnecessary for zip download and raised security concerns

## [25.05.1] - 2025-05-17

### Added

- SSD-specific tweak section in system optimizations
- Enhanced `Organizer.ps1` with refined file filtering and new exclusions
- Trae, GitHub Desktop, Spotify, and Android SDK Platform-Tools added to bundles
- Windots integration — configurations for VSCode, Windows Terminal, PowerShell, Oh My Posh, and FastFetch
- Visual customizations: Rectify11, SpotX, Spicetify, Steam Millennium (Space Theme), and macOS cursor

### Changed

- Reorganized configuration files and scripts
- UI enhancements and simplified admin process elevation
- Strengthened PowerShell reliability through improved error management for profiles

### Fixed

- Removed outdated tweaks
- Fixed GPU tweak exit issue

## [25.05] - 2025-05-01

### Added

- GTweak launcher integration
- WizTree and RyTuneX added to Utilities bundle
- Privacy.sexy now supports launching latest standard preset from privacylearn.com

### Fixed

- Corrected UniGetUI bundle paths
- Removed tweak that caused "USB not recognized" after executing Universal tweaks

## [25.04] - 2025-04-06

### Added

- WinScript now operational in portable mode without installation requirement
- Expanded UniGetUI bundles with additional packages

### Changed

- All scripts now run on PowerShell, resolving issues where tweaks would fail silently

### Fixed

- Refactored project structure for better organization
- Fixed script launch from command
- Updated README

## [25.03] - 2025-03-18

Initial public release (pre-release).

- Console menu system with 10 main options
- System tweaks: SSD, GPU, CPU, network, and memory optimizations
- Driver manufacturer links for NVIDIA, AMD, HP, Lenovo, ASUS, MSI
- Privacy tools and security hardening
- Third-party tool integrations (WinUtil, WinScript, privacy.sexy)
- Autounattend.xml configuration guide for automated Windows installation
- UniGetUI bundles by category (Development, Browsers, Utilities, Productivity, Games, Communications)
- Windots integration for Windows ricing and desktop customization
- Gradual transition from batch scripts to PowerShell

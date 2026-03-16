# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Calendar Versioning](https://calver.org/) (YY.M format).

## [26.3] - 2026-03-16

### March 16 — Secure tool dispatch, `Invoke-Tool` refactor, and expanded tests

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

### March 16 — Windots refactor, Pester tests, and CI pipeline

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

### March 16 — Bundle overhaul, return-to-menu navigation, and documentation rewrite

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

### March 15 — Loop menus, Show-MenuBox, logging, and Tweaks submodules

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

### March 13 — Architecture refactor with shared utilities, config-driven tools, and CI

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

### March 10 — Code quality, safety, docs, and UX

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

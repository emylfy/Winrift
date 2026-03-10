# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Calendar Versioning](https://calver.org/) (YY.M format).

## [26.3] - 2026-03-10

### Added
- System Restore Point creation before applying any tweaks
- Selective tweak application — choose which categories to apply
- Session logging via `Start-Transcript` (logs saved to `~/Simplify11/logs/`)
- "What was changed" summary displayed after tweak application
- Version system via `version.json` (replaces hardcoded version string)
- `CHANGELOG.md` for tracking project changes
- `CONTRIBUTING.md` with setup, testing, and PR guidelines
- GitHub issue templates for bug reports and feature requests
- Comprehensive `.gitignore` for Windows, IDE, and temp files
- README: disclaimers, FAQ section, and compatibility table
- Safety check for missing modules in main menu — shows friendly error instead of crashing

### Fixed
- Main menu option "3" (Security Menu) now gets consistent sub-menu (Run/Docs/Back) like all other options
- Inconsistent tab/space indentation in `AdminLaunch.ps1`
- Error handling added to all external script downloads (`irm | iex` patterns)
- Menu "back" actions no longer spawn new PowerShell processes — replaced with `return` to prevent stack overflow from recursive process chains
- Removed orphaned unreachable `exit` statement in `WinScript.ps1`
- Drivers menu now uses 1-based numbering instead of 0-based, with hashtable lookup replacing fragile array indexing
- Icon install path in `install.ps1` now uses `$env:APPDATA\Simplify11` subfolder instead of bare `$env:APPDATA`
- Shortcut `WorkingDirectory` corrected from Start Menu path to `$env:USERPROFILE`
- Version tag in `CHANGELOG.md` aligned to `[26.3]` to match `version.json` (CalVer)

### Removed
- `Add-MpPreference` Defender exclusion from `launch.ps1` — unnecessary for zip download and raised security concerns

### Changed
- Function names standardized to use approved PowerShell verbs:
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

## [Pre-release] - Prior versions

- Initial toolkit with system tweaks, driver links, privacy tools, and third-party integrations
- Console menu system with 10 main options
- Autounattend.xml configuration guide
- Windots integration for Windows ricing and customization

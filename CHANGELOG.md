# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-10

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

### Fixed
- Main menu option "3" (Security Menu) now gets consistent sub-menu (Run/Docs/Back) like all other options
- Inconsistent tab/space indentation in `AdminLaunch.ps1`
- Error handling added to all external script downloads (`irm | iex` patterns)

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

## [Pre-release] - Prior versions

- Initial toolkit with system tweaks, driver links, privacy tools, and third-party integrations
- Console menu system with 10 main options
- Autounattend.xml configuration guide
- Windots integration for Windows ricing and customization

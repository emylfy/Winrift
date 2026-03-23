<h1 align="center">Customize</h1>

<p align="center">
  <a href="https://github.com/emylfy/winrift/stargazers"><img src="https://img.shields.io/github/stars/emylfy/winrift?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=C9CBFF&labelColor=302D41" alt="GitHub Stars"></a>&nbsp;&nbsp;
  <a href="https://github.com/emylfy/winrift/blob/main/LICENSE"><img src="https://img.shields.io/github/license/emylfy/winrift?style=for-the-badge&logo=apache&color=CBA6F7&logoColor=CBA6F7&labelColor=302D41&label=License" alt="License"></a>&nbsp;&nbsp;
  <a href="https://github.com/emylfy/winrift/commits/main/"><img src="https://img.shields.io/github/last-commit/emylfy/winrift?style=for-the-badge&logo=github&logoColor=eba0ac&label=Last%20Commit&labelColor=302D41&color=eba0ac" alt="Last Commit"></a>
</p>

> Part of the [Winrift](https://github.com/emylfy/winrift) toolkit — the complete Windows 11 post-install pipeline.

---

## About

Transform your Windows 11 into an elegant and productive environment. Set up a tiling window manager, status bar, app launcher, shell prompt, and themed apps — or pick only what you need.

---

## Prerequisites

- Windows 11 (22H2 or newer)
- PowerShell 5.1 (included with Windows 11)
- [winget](https://aka.ms/getwinget) (required for Desktop Environment, Oh My Posh, Starship, FastFetch)
- Internet connection

---

## Quick Launch

Launch via Winrift (recommended):

```powershell
irm https://raw.githubusercontent.com/emylfy/winrift/main/scripts/launch.ps1 | iex
```

---

## Desktop Environment

Set up a full riced desktop with tiling windows, a status bar, and an app launcher.

| Component | Description |
| --- | --- |
| [GlazeWM](https://github.com/glzr-io/glazewm) | i3-inspired tiling window manager with YAML config |
| [Zebar](https://github.com/glzr-io/zebar) | Status bar and widgets (pairs with GlazeWM) |
| [Flow Launcher](https://github.com/Flow-Launcher/Flow.Launcher) | Productivity launcher (Alfred/Raycast for Windows) |
| [Windhawk](https://windhawk.net/) | Marketplace for reversible Windows UI mods |
| [Rainmeter](https://www.rainmeter.net/) | Desktop widgets and skins |

---

## Configs Installer

Copy opinionated dotfiles for your favorite tools. All config files are bundled in `config/` and copied to the standard user directories.

| Component | Supported Apps | Config Source |
| --- | --- | --- |
| **Code Editors** | [VSCode](https://code.visualstudio.com/), [AIDE](https://github.com/codestoryai/aide), [Cursor](https://cursor.sh/), [Windsurf](https://windsurf.io/), [VSCodium](https://vscodium.com/), [Trae](https://trae.ai/) | `config/vscode/` |
| **Terminal** | [Windows Terminal](https://github.com/microsoft/terminal) (includes Nerd Font setup) | `config/cli/terminal.json` |
| **Shell** | [PowerShell](https://learn.microsoft.com/en-us/powershell/) + [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) | `config/cli/Microsoft.PowerShell_profile.ps1` |
| **Prompt** | [Oh My Posh](https://ohmyposh.dev/) (Zen theme), [Starship](https://starship.rs/) | `config/cli/zen.toml` |
| **System Info** | [FastFetch](https://github.com/fastfetch-cli/fastfetch) | `config/cli/fastfetch.jsonc` |

---

## Apps & Themes

Download and install additional customization tools.

| Tool | Description |
| --- | --- |
| [Rectify11](https://rectify11.net/) | Windows 11 UI consistency fixes |
| [SpotX](https://github.com/SpotX-Official/SpotX) | Spotify ad-blocker mod |
| [Spicetify](https://spicetify.app/) | Spotify customization framework |
| [Steam Millennium](https://steambrew.app/) | Steam theming framework + optional [Space Theme](https://github.com/SpaceTheme/Steam) |
| [macOS Cursor](https://github.com/ful1e5/apple_cursor) | Apple cursor theme for Windows |

---

## Windows Look & Feel

Windows shell and UI adjustments applied via registry.

| Tweak | Description |
| --- | --- |
| **Short Date & Time Format** | Sets taskbar format to `MMM dd yyyy` and `HH:mm` (e.g. Feb 17 2026, 17:57) |
| **Disable Quick Access Pinning** | Stops Windows from automatically pinning folders to Quick Access |
| **Start Menu Organizer** | Selectively pulls app shortcuts out of folders to the Start menu root |

---

<div align="center">
  <a href="https://github.com/emylfy/winrift">Back to Winrift</a>
</div>

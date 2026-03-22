<h1 align="center">Windots</h1>

<p align="center">
  <a href="https://github.com/emylfy/winrift/stargazers"><img src="https://img.shields.io/github/stars/emylfy/winrift?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=C9CBFF&labelColor=302D41" alt="GitHub Stars"></a>&nbsp;&nbsp;
  <a href="https://github.com/emylfy/winrift/blob/main/LICENSE"><img src="https://img.shields.io/github/license/emylfy/winrift?style=for-the-badge&logo=apache&color=CBA6F7&logoColor=CBA6F7&labelColor=302D41&label=License" alt="License"></a>&nbsp;&nbsp;
  <a href="https://github.com/emylfy/winrift/commits/main/"><img src="https://img.shields.io/github/last-commit/emylfy/winrift?style=for-the-badge&logo=github&logoColor=eba0ac&label=Last%20Commit&labelColor=302D41&color=eba0ac" alt="Last Commit"></a>
</p>

> Part of the [Winrift](https://github.com/emylfy/winrift) toolkit — the complete Windows 11 post-install pipeline.

---

## About

Collection of configurations and tools to transform your Windows 11 into an elegant and productive environment. Install opinionated configs for your favorite editors, terminal, and shell — or pick only what you need.

---

## Prerequisites

- Windows 11 (22H2 or newer)
- PowerShell 5.1 (included with Windows 11)
- Internet connection

---

## Quick Launch

Launch via Winrift (recommended):

```powershell
irm https://raw.githubusercontent.com/emylfy/winrift/main/scripts/launch.ps1 | iex
```

---

## Configs Installer

Copy opinionated dotfiles for your favorite tools. All config files are bundled in `config/` and copied to the standard user directories.

| Component | Supported Apps | Config Source |
| --- | --- | --- |
| **Code Editors** | [VSCode](https://code.visualstudio.com/), [AIDE](https://github.com/codestoryai/aide), [Cursor](https://cursor.sh/), [Windsurf](https://windsurf.io/), [VSCodium](https://vscodium.com/), [Trae](https://trae.ai/) | `config/vscode/` |
| **Terminal** | [Windows Terminal](https://github.com/microsoft/terminal) (includes Fira Code font setup) | `config/cli/terminal.json` |
| **Shell** | [PowerShell](https://learn.microsoft.com/en-us/powershell/) + [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) | `config/cli/Microsoft.PowerShell_profile.ps1` |
| **Prompt** | [Oh My Posh](https://ohmyposh.dev/) (Zen theme) | `config/cli/zen.toml` |
| **System Info** | [FastFetch](https://github.com/fastfetch-cli/fastfetch) | `config/cli/fastfetch.jsonc` |

---

## Apps & Tools

Download and install additional customization tools — no dotfiles, just installers.

| Tool | Description |
| --- | --- |
| [Rectify11](https://rectify11.net/) | Windows 11 UI theme (opens download page) |
| [SpotX](https://github.com/SpotX-Official/SpotX) | Spotify ad-blocker mod |
| [Spicetify](https://spicetify.app/) | Spotify customization framework |
| [Steam Millennium](https://steambrew.app/) | Steam theming framework + optional [Space Theme](https://github.com/SpaceTheme/Steam) |
| [macOS Cursor](https://github.com/ful1e5/apple_cursor) | Apple cursor theme for Windows |

---

## Customization Tweaks

Windows shell and UI adjustments applied via registry.

| Tweak | Description |
| --- | --- |
| **Short Date & Time Format** | Sets taskbar format to `dd MMM yyyy` and `HH:mm` (e.g. Feb 17, 17:57) |
| **Disable Quick Access Pinning** | Stops Windows from automatically pinning folders to Quick Access |
| **Start Menu Organizer** | Selectively pulls app shortcuts out of folders to the Start menu root |

---

<div align="center">
  <a href="https://github.com/emylfy/winrift">Back to Winrift</a>
</div>

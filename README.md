<div align="center">

# Winrift

**Set up Windows once. Bring your setup to the next install.**

Set up, save, and restore your Windows environment — apps, settings, and configs.

![Winrift terminal menu demonstration](media/demo.gif)

<a href="https://github.com/emylfy/winrift/stargazers"><img src="https://img.shields.io/github/stars/emylfy/winrift?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=C9CBFF&labelColor=302D41" alt="GitHub Stars"></a>&nbsp;&nbsp;
<a href="https://github.com/emylfy/winrift/blob/main/LICENSE"><img src="https://img.shields.io/github/license/emylfy/winrift?style=for-the-badge&logo=apache&color=CBA6F7&logoColor=CBA6F7&labelColor=302D41&label=License" alt="GitHub License"></a>&nbsp;&nbsp;
<a href="https://github.com/emylfy/winrift/commits/main/"><img src="https://img.shields.io/github/last-commit/emylfy/winrift?style=for-the-badge&logo=github&logoColor=eba0ac&label=Last%20Commit&labelColor=302D41&color=eba0ac" alt="Last Commit"></a>&nbsp;&nbsp;
<a href="https://github.com/emylfy/winrift/releases"><img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Femylfy%2Fwinrift%2Fmain%2Fconfig%2Fversion.json&query=%24.version&prefix=v&style=for-the-badge&label=Version&color=a6e3a1&labelColor=302D41" alt="Version"></a>

</div>

---

## ⚡ Quick Start

Open PowerShell on **Windows 11 26H2** and run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; irm https://github.com/emylfy/winrift/releases/latest/download/launch.ps1 | iex
```

This runs the launcher attached to the latest stable release and downloads that release at its resolved commit. Winrift downloads portable PowerShell 7 if needed.

Prefer a local copy? [Download the latest release](https://github.com/emylfy/winrift/releases/latest), extract its source archive, and open **Winrift.cmd**. See [release channels](docs/tests.md#release-channels) to opt into development builds.

<details>
<summary><strong>Add a Start Menu shortcut</strong></summary>

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; irm https://github.com/emylfy/winrift/releases/latest/download/install.ps1 | iex
```

</details>

**From a downloaded copy:** Open the Winrift folder and double-click **Winrift.cmd**.

<details>
<summary><strong>Preview mode</strong></summary>

Run from the Winrift folder:

```powershell
.\Winrift.cmd -DryRun
```

</details>

---

## 💾 Take your setup with you

1. **Set up your PC.** Pick your Windows tweaks, install your apps, and configure your terminal, editor, or desktop.
2. **Save what you want to keep.** Open **Save / Restore Setup → Save Setup** and select the settings, app list, and supported configs to carry over.
3. **Bring it back after a reinstall.** Open **Restore Setup**, choose what to restore, and review the changes before applying them.

A saved setup contains supported Windows settings, app IDs, and selected configuration files. It is not a disk image or a complete backup: personal documents, app data, licenses, and every Windows preference are not captured. App installs use versions available from their package sources. [See the save/restore walkthrough](docs/setup.md).

## 🧩 What you can do

| | Section | What you can do |
| :-: | :-- | :-- |
| 🖥️ | **Update Windows & Drivers** | Open Windows Update and find Intel Driver & Support Assistant on compatible hardware. |
| ⚙️ | **Set Up Windows** | Review Windows tweaks, apply AMD, NVIDIA, or DirectX presets, and review Privacy Setup before applying it. |
| 📦 | **Install Your Apps** | Build an install queue from the catalog or import a bundle. Edit and save your own copy in UniGetUI. |
| 🎨 | **Configure Your Apps** | Set up Windows Terminal, PowerShell, editors, and GlazeWM, and organize Start Menu shortcuts. |
| ↩️ | **Undo Changes** | Browse action history and restore previous settings or configuration backups where available. |

<details>
<summary><strong>Tools and customization</strong></summary>

- **Privacy & maintenance** — App updater controls, DNS Benchmark, disk cleanup, and external tool collections.
- **Shell & editors** — Starship or Oh My Posh, FastFetch, editor settings, and extension installation.
- **Desktop & browser** — GlazeWM configs, wallpaper collections, and JustTheBrowser.

</details>

---

## 💿 Installation Media (experimental)

Under **Save / Restore Setup → Create Windows Installation Media**, select a Windows ISO and optionally include a saved setup for first sign-in. You can keep the standard Windows installer or supply your own answer file.

[See the installation media guide](docs/autounattend_guide.md).

---

## ✅ Compatibility

**Target: Windows 11 26H2.** The documented manual validation used an ARM64 Parallels VM; a complete x64/hardware matrix and fresh-install restore cycle have not yet been established. See [validation and known limits](docs/validation.md).

Winrift can download portable PowerShell 7 when needed. Administrator access is required for system changes, and downloads require an internet connection.

Optional GPU, DirectX, and advanced power presets are experimental. Matching a source preset or verifying a registry write does not establish a performance gain. Preview and Undo cover supported operations; package removal, cleanup, and external tools are not universally reversible.

## 🔧 Troubleshooting

| Problem | Where to look |
| :-- | :-- |
| **Winrift fails to start** | Check the startup logs in `%LOCALAPPDATA%\Winrift\logs`. |
| **An app install fails** | Review the package result and choose **Retry Failed Items**. |
| **A setting or config needs restoring** | Open **Undo Changes** and choose **Action History** or **Restore Configuration Backup**. |

## Documentation

- [Save and restore your setup](docs/setup.md)
- [Tweaks and what they change](docs/tweaks_guide.md)
- [Validation and known limits](docs/validation.md)
- [Development tests](docs/tests.md)

---

## 🏆 Credits

Built on the work of [AlchemyTweaks/Verified-Tweaks](https://github.com/AlchemyTweaks/Verified-Tweaks), [ashish0kumar/windots](https://github.com/ashish0kumar/windots), [marticliment/UniGetUI](https://github.com/marticliment/UniGetUI), and the [schneegans unattend generator](https://schneegans.de/windows/unattend-generator/).

<div align="center">

[MIT License](LICENSE) · [Contributing](CONTRIBUTING.md) · [Changelog](CHANGELOG.md) · [Report a Bug](https://github.com/emylfy/winrift/issues)

<sub>If Winrift improved your setup, consider leaving a ⭐</sub>

</div>

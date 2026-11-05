<div align="center">

# Winrift

**Set up Windows once. Bring your setup to the next install.**

Windows tweaks, app installs, and app configuration in one terminal menu.

<a href="https://github.com/emylfy/winrift/stargazers"><img src="https://img.shields.io/github/stars/emylfy/winrift?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=C9CBFF&labelColor=302D41" alt="GitHub Stars"></a>&nbsp;&nbsp;
<a href="https://github.com/emylfy/winrift/blob/main/LICENSE"><img src="https://img.shields.io/github/license/emylfy/winrift?style=for-the-badge&logo=apache&color=CBA6F7&logoColor=CBA6F7&labelColor=302D41&label=License" alt="GitHub License"></a>&nbsp;&nbsp;
<a href="https://github.com/emylfy/winrift/commits/main/"><img src="https://img.shields.io/github/last-commit/emylfy/winrift?style=for-the-badge&logo=github&logoColor=eba0ac&label=Last%20Commit&labelColor=302D41&color=eba0ac" alt="Last Commit"></a>&nbsp;&nbsp;
<a href="https://github.com/emylfy/winrift/releases"><img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Femylfy%2Fwinrift%2Fmain%2Fconfig%2Fversion.json&query=%24.version&prefix=v&style=for-the-badge&label=Version&color=a6e3a1&labelColor=302D41" alt="Version"></a>

</div>

---

## ⚡ Quick Start

Open PowerShell on **Windows 11 26H2** and run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; irm https://raw.githubusercontent.com/emylfy/winrift/main/scripts/launch.ps1 | iex
```

This launches the version on the project's `main` branch. Winrift downloads portable PowerShell 7 if needed.

<details>
<summary><strong>Add a Start Menu shortcut</strong></summary>

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; irm https://raw.githubusercontent.com/emylfy/winrift/main/scripts/install.ps1 | iex
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

- **Privacy & maintenance** — RemoveWindowsAI, app updater controls, DNS Benchmark, disk cleanup, and DefendNot.
- **Shell & editors** — Starship or Oh My Posh, FastFetch, editor settings, and extension installation.
- **Desktop & browser** — GlazeWM configs, wallpaper collections, and JustTheBrowser.

</details>

---

## 💿 Installation Media

Under **Save / Restore Setup → Create Windows Installation Media**, select a Windows ISO and optionally include a saved setup for first sign-in. You can keep the standard Windows installer or supply your own answer file.

[See the installation media guide](docs/autounattend_guide.md).

---

## ✅ Compatibility

**Windows 11 26H2**. Winrift can download portable PowerShell 7 when needed. Administrator access is required for system changes, and downloads require an internet connection.

## 🔧 Troubleshooting

| Problem | Where to look |
| :-- | :-- |
| **Winrift fails to start** | Check the startup logs in `%LOCALAPPDATA%\Winrift\logs`. |
| **An app install fails** | Review the package result and choose **Retry Failed Items**. |
| **A setting or config needs restoring** | Open **Undo Changes** and choose **Action History** or **Restore Configuration Backup**. |

## Documentation

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

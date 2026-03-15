<h1>Simplify11 <img src="https://raw.githubusercontent.com/emylfy/simplify11/refs/heads/main/media/icon.ico" width="24px" alt="Simplify11 icon"></h1>

**From fresh Windows ISO to fully riced desktop — one script.** Automates post-installation configuration, applies performance tweaks, installs drivers and software, and sets up your personalized desktop environment.

<p align="center">
	<img src="media/logo.png" alt="Simplify11 Logo" width="70%">
</p>

<p align="center">
	<a href="#-why-simplify11">Why Simplify11?</a> •
	<a href="#-features">Features</a> •
	<a href="#-installation">Installation</a> •
	<a href="#-troubleshooting">Troubleshooting</a> •
	<a href="#-integrations">Integrations</a> •
	<a href="#-compatibility">Compatibility</a> •
	<a href="#-faq">FAQ</a> •
	<a href="#-credits">Credits</a>
</p>

<div align="center">
 <p>
 <a href="https://github.com/emylfy/simplify11/stargazers"><img src="https://img.shields.io/github/stars/emylfy/simplify11?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=C9CBFF&labelColor=302D41" alt="GitHub Stars"></a>&nbsp;&nbsp;
 <a href="https://github.com/emylfy/simplify11/"><img src="https://img.shields.io/github/repo-size/emylfy/simplify11?style=for-the-badge&logo=git&logoColor=f9e2af&label=Size&labelColor=302D41&color=f9e2af" alt="Repository Size"></a>&nbsp;&nbsp;
 <a href="https://github.com/emylfy/simplify11/commits/main/"><img src="https://img.shields.io/github/last-commit/emylfy/simplify11?style=for-the-badge&logo=github&logoColor=eba0ac&label=Last%20Commit&labelColor=302D41&color=eba0ac" alt="Last Commit"></a>&nbsp;&nbsp;
 <a href="https://github.com/emylfy/simplify11/blob/main/LICENSE"><img src="https://img.shields.io/github/license/emylfy/simplify11?style=for-the-badge&logo=apache&color=CBA6F7&logoColor=CBA6F7&labelColor=302D41&label=License" alt="GitHub License"></a>&nbsp;&nbsp;
 </p>
</div>

> **No other tool covers this complete pipeline:** Windows ISO → System tweaks → Driver install → Desktop customization

![](https://github.com/emylfy/simplify11/blob/main/media/separator.png)

## 🎯 Why Simplify11?

| Feature | Simplify11 | WinUtil | Win11Debloat |
| :--- | :---: | :---: | :---: |
| Autounattend.xml ISO guide | ✅ | ❌ | ❌ |
| GPU-specific tweaks (NVIDIA/AMD) | ✅ | ❌ | ❌ |
| Desktop ricing (Windots, themes) | ✅ | ❌ | ❌ |
| Driver installation links | ✅ | ❌ | ❌ |
| Package manager GUI (UniGetUI) | ✅ | ❌ | ❌ |
| Selective tweaks by category | ✅ | ✅ | ❌ |
| System restore before tweaks | ✅ | ❌ | ✅ |
| Session logs with timestamps | ✅ | ❌ | ❌ |
| Multi-tool hub (10+ tools) | ✅ | ❌ | ❌ |

![](https://github.com/emylfy/simplify11/blob/main/media/separator.png)

## ✨ Features

<div align="center">

### Everything you need for perfect Windows 11 setup

</div>

### 🛠️ System Configuration

- Windows installation [answer file](https://github.com/emylfy/simplify11/blob/main/docs/autounattend_guide.md) creation guide
- System performance tweaks for SSD, GPU, CPU, Network, Memory optimization
- Driver installation support for NVIDIA, AMD, HP, Lenovo, ASUS, MSI and more
- Security tools: Disable Defender, remove Copilot/Recall, privacy hardening

### ⚡ Optimization

- 13 selectable tweak categories with progress feedback
- GPU-specific tweaks for NVIDIA and AMD
- Enhanced input responsiveness (mouse & keyboard)
- DirectX enhancements and power management
- Disk space management and cleanup

### 📦 Software Management

- UniGetUI — modern graphical interface for Windows Package Manager
- Pre-built app bundles: Development, Browsers, Utilities, Productivity, Gaming, Communications

### 🎨 Desktop Customization ([Windots](https://github.com/emylfy/windots))

- Config installer for VSCode-based editors, Windows Terminal, PowerShell
- Spotify tools (SpotX, Spicetify), Steam Millennium theme
- macOS cursor, Rectify11 UI theme, Oh My Posh prompt

![](https://github.com/emylfy/simplify11/blob/main/media/separator.png)

## ⚡ Installation

### Prerequisites

- Windows 11 (22H2 or newer)
- PowerShell 5.1 (included with Windows 11 by default)
- Administrator rights
- Internet connection

### Quick Start

**Step 1.** Open PowerShell as Administrator

> Press `Win + X` → select **Windows Terminal (Admin)** or **PowerShell (Admin)**

**Step 2.** Run the launcher:

```powershell
iwr "https://dub.sh/simplify11" | iex
```

**Step 3.** The interactive menu opens automatically. No further installation needed.

### Persistent Start Menu Shortcut (Optional)

Creates a shortcut to always launch the latest version:

```powershell
iwr "https://dub.sh/s11install" | iex
```

### Security Note

> This uses `irm | iex` — a common PowerShell pattern in the community. The full source code is open at [github.com/emylfy/simplify11](https://github.com/emylfy/simplify11) for review. Always create a restore point before applying system tweaks — **Simplify11 does this automatically**.

![](https://github.com/emylfy/simplify11/blob/main/media/separator.png)

## 🔧 Troubleshooting

| Problem | Solution |
| :--- | :--- |
| "Running scripts is disabled on this system" | Run: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| "Module not found" error | Re-run the Quick Start command to get the latest version |
| UAC prompt appears on launch | Normal — click **Yes** for operations requiring admin rights |
| Registry errors in tweaks | Check `%USERPROFILE%\Simplify11\logs\` for the session log |
| UniGetUI won't install | Run `winget source reset --force` in an admin PowerShell |
| WinUtil / Sparkle won't launch | Check your internet connection and firewall settings |

![](https://github.com/emylfy/simplify11/blob/main/media/separator.png)

## 🔄 Integrations

<div align="center">

### Powerful tools in one place

</div>

<table>
<tr>
<td align="center" width="20%">
<img src="https://github.com/ChrisTitusTech/winutil/blob/main/docs/assets/favicon.png?raw=true" width="60px" alt="WinUtil Logo"><br/>
<b><a href="https://github.com/ChrisTitusTech/winutil" title="Visit WinUtil on GitHub">WinUtil</a></b><br/>
<sub>Install programs, tweaks, fixes and updates</sub>
</td>
<td align="center" width="20%">
<img src="https://raw.githubusercontent.com/flick9000/winscript/refs/heads/main/app/public/logo.svg" width="60px" alt="WinScript Logo"><br/>
<b><a href="https://github.com/flick9000/winscript" title="Visit WinScript on GitHub">WinScript</a></b><br/>
<sub>Build custom setup scripts</sub>
</td>
<td align="center" width="20%">
<img src="https://github.com/Greedeks/GTweak/blob/main/Assets/GTweak.png" width="60px" alt="GTweak Logo"><br/>
<b><a href="https://github.com/Greedeks/GTweak" title="Visit GTweak on GitHub">GTweak</a></b><br/>
<sub>Tweaking tool and debloater</sub>
</td>
<td align="center" width="20%">
<img src="https://raw.githubusercontent.com/undergroundwires/privacy.sexy/refs/heads/master/img/logo.svg" width="60px" alt="Privacy.sexy Logo"><br/>
<b><a href="https://github.com/undergroundwires/privacy.sexy" title="Visit Privacy.sexy on GitHub">Privacy.sexy</a></b><br/>
<sub>Security enhancement</sub>
</td>
<td align="center" width="20%">
<img src="https://raw.githubusercontent.com/marticliment/UniGetUI/refs/heads/main/media/icon.svg" width="60px" alt="UniGetUI Logo"><br/>
<b><a href="https://github.com/marticliment/UniGetUI" title="Visit UniGetUI on GitHub">UniGetUI</a></b><br/>
<sub>Discover, install and update packages</sub>
</td>
</tr>
</table>

![](https://github.com/emylfy/simplify11/blob/main/media/separator.png)

## 💻 Compatibility

| Windows Version | Status |
| :---: | :---: |
| Windows 11 24H2 | Fully tested ✅ |
| Windows 11 23H2 | Supported ✅ |
| Windows 11 22H2 | Should work (not actively tested) ⚠️ |
| Windows 10 | Not supported ❌ |
| Insider Builds | Use at your own risk ⚠️ |

**Requirements:** PowerShell 5.1+ (included with Windows 11), Administrator privileges for system tweaks, Internet connection.

![](https://github.com/emylfy/simplify11/blob/main/media/separator.png)

## ❓ FAQ

**Is this safe to use?**
All tweaks have been tested across multiple sources and only the most effective, well-documented registry modifications are included. A System Restore Point is created automatically before applying any tweaks. Full source code is available for review.

**Can I undo the changes?**
A System Restore Point is created before tweaks are applied. You can revert to it via **Settings → System → Recovery → Advanced startup**, or by booting into Advanced Startup and choosing System Restore.

**Does this disable Windows Update?**
No. Simplify11 does not touch Windows Update settings. Updates will continue to work normally.

**Can I choose which tweaks to apply?**
Yes! The tweaks menu lets you select individual categories (SSD, GPU, CPU, Network, Memory, DirectX, etc.) or apply all at once with progress feedback.

**Where are the logs stored?**
Session logs are saved to `%USERPROFILE%\Simplify11\logs\` with timestamps. Separate logs exist for tweaks, security tools, and Windots operations.

![](https://github.com/emylfy/simplify11/blob/main/media/separator.png)

## 🌟 Credits

<div align="center">

| Project | Description |
| :-----: | :---------: |
| [AlchemyTweaks/Verified-Tweaks](https://github.com/AlchemyTweaks/Verified-Tweaks) | A collection of verified and tested Windows modifications |
| [ashish0kumar/windots](https://github.com/ashish0kumar/windots) | Windows customization and dotfiles management |
| [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil) | Windows utility tool by Chris Titus Tech |
| [flick9000/winscript](https://github.com/flick9000/winscript) | Custom Windows script builder |
| [Greedeks/GTweak](https://github.com/Greedeks/GTweak) | Windows tweaking tool and debloater |
| [Parcoil/Sparkle](https://github.com/Parcoil/Sparkle) | Windows Package Manager wrapper |
| [marticliment/UniGetUI](https://github.com/marticliment/UniGetUI) | Modern GUI for Windows package managers |

</div>

<div align="center">

### ⭐ Love this project? Show your support by giving it a star!

#### 📫 Have suggestions or found a bug? Open an [**Issue**](https://github.com/emylfy/simplify11/issues/).

</div>

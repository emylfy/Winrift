<h1>Simplify11 <img src="https://raw.githubusercontent.com/emylfy/simplify11/refs/heads/main/media/icon.ico" width="24px" alt="Simplify11 icon"></h1>

**The complete Windows 11 fresh install toolkit — from ISO to fully customized desktop in one script.** Automates post-installation configuration, applies performance tweaks, installs drivers and software, and sets up your personalized desktop environment.

<p align="center">
	<img src="media/logo.png" alt="Simplify11 Logo" width="70%">
</p>

<p align="center">
	<a href="#-features">Features</a> •
	<a href="#-installation">Installation</a> •
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

![](https://github.com/emylfy/simplify11/blob/main/media/separator.png)

## ✨ Features

<div align="center">

### Everything you need for perfect Windows 11 setup

</div>

### 🛠️ System Configuration

- Windows installation [answer file](https://github.com/emylfy/simplify11/blob/main/docs/autounattend_guide.md) creation guide
- System performance tweaks for SSD, GPU, CPU optimization
- Driver Installation support for NVIDIA, AMD and other device manufacturers
- Customization options including [Windots](https://github.com/emylfy/windots) integration

### ⚡ Optimization

- Enhanced input responsiveness
- System performance improvements
- DirectX enhancements
- Disk space management and cleanup

### 📦 Software Management

- UniGetUI — modern graphical interface for Windows Package Manager
- Software Categories:
  - Development, Browsers, System Tools
  - Productivity, Gaming, Microsoft Apps

## ⚡ Installation

### Quick Start

Launch Simplify11 from PowerShell:

```powershell
iwr "https://dub.sh/simplify11" | iex
```

### Full Installation

Creates a shortcut in the Start Menu to launch the latest version:

```powershell
iwr "https://dub.sh/s11install" | iex
```

### Important

> **Always create a system restore point before running system tweaks.** Simplify11 creates one automatically when applying tweaks, but having a manual backup is recommended. Some tweaks modify Windows registry settings and may not be easily reversible. Tested on Windows 11 24H2.

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
| Windows 11 24H2 | Fully tested |
| Windows 11 23H2 | Supported |
| Windows 11 22H2 | Should work (not actively tested) |
| Windows 10 | Not supported |
| Insider Builds | Use at your own risk |

**Requirements:** PowerShell 5.1+ (included with Windows 11), Administrator privileges for system tweaks.

![](https://github.com/emylfy/simplify11/blob/main/media/separator.png)

## ❓ FAQ

**Is this safe to use?**
All tweaks have been tested across multiple sources and only the most effective, well-documented registry modifications are included. A System Restore Point is created automatically before applying any tweaks.

**Can I undo the changes?**
A System Restore Point is created before tweaks are applied. You can revert to it via Settings > System > Recovery > Go Back, or by booting into Advanced Startup and choosing System Restore.

**Does this disable Windows Update?**
No. Simplify11 does not touch Windows Update settings. Updates will continue to work normally.

**Can I choose which tweaks to apply?**
Yes! The tweaks menu lets you select individual categories (SSD, GPU, CPU, Network, etc.) or apply all at once.

**Where are the logs stored?**
Session logs are saved to `%USERPROFILE%\Simplify11\logs\` with timestamps.

**Why use this instead of WinUtil or Win11Debloat?**
Simplify11 covers the entire journey from Windows ISO creation (autounattend.xml) through system tweaks and all the way to desktop customization (Windots, themes, dotfiles). No other tool offers this complete fresh-install-to-finished-desktop pipeline.

![](https://github.com/emylfy/simplify11/blob/main/media/separator.png)

## 🌟 Credits

<div align="center">

| Project | Description |
| :-----: | :---------: |
| [AlchemyTweaks/Verified-Tweaks](https://github.com/AlchemyTweaks/Verified-Tweaks) | A collection of verified and tested Windows modifications |
| [ashish0kumar/windots](https://github.com/ashish0kumar/windots) | Windows customization and dotfiles management |

</div>

<div align="center">

### ⭐ Love this project? Show your support by giving it a star!

#### 📫 If you have specific recommendations on how to improve or change this project or any suggestions and wishes, you can write everything in [**Issues**](https://github.com/emylfy/simplify11/issues/).

</div>
<h1>Winrift <img src="https://raw.githubusercontent.com/emylfy/winrift/refs/heads/main/media/icon.ico" width="24px" alt="Winrift icon"></h1>

**Break through default Windows.** Most tweakers ask you to trust them. Winrift proves it works — built-in benchmarks measure every change.

<p align="center">
	<img src="media/logo.png" alt="Winrift — Windows 11 optimization and benchmarking tool" width="70%">
</p>

<div align="center">
 <p>
 <a href="https://github.com/emylfy/winrift/stargazers"><img src="https://img.shields.io/github/stars/emylfy/winrift?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=C9CBFF&labelColor=302D41" alt="GitHub Stars"></a>&nbsp;&nbsp;
 <a href="https://github.com/emylfy/winrift/blob/main/LICENSE"><img src="https://img.shields.io/github/license/emylfy/winrift?style=for-the-badge&logo=apache&color=CBA6F7&logoColor=CBA6F7&labelColor=302D41&label=License" alt="GitHub License"></a>&nbsp;&nbsp;
 <a href="https://github.com/emylfy/winrift/commits/main/"><img src="https://img.shields.io/github/last-commit/emylfy/winrift?style=for-the-badge&logo=github&logoColor=eba0ac&label=Last%20Commit&labelColor=302D41&color=eba0ac" alt="Last Commit"></a>
 </p>
</div>

<p align="center">
	<a href="#install">Install</a> •
	<a href="#benchmark--dont-trust-verify">Benchmark</a> •
	<a href="#features">Features</a> •
	<a href="#compatibility">Compatibility</a> •
	<a href="#troubleshooting">Troubleshooting</a>
</p>

> **No other tool covers this complete pipeline:** Measure → Optimize → Verify → Customize

<!-- TODO: record demo.gif with ShareX or Windows Terminal screen capture
<p align="center">
	<img src="media/demo.gif" alt="Winrift demo — launching benchmarks, applying tweaks, viewing results" width="80%">
</p>
-->

---

## Install

Open PowerShell as Admin (`Win + X` → Terminal Admin) and run:

```powershell
irm https://raw.githubusercontent.com/emylfy/winrift/main/scripts/launch.ps1 | iex
```

A restore point is created automatically before any system changes.

<details>
<summary>Create a persistent Start Menu shortcut</summary>

```powershell
irm https://raw.githubusercontent.com/emylfy/winrift/main/scripts/install.ps1 | iex
```

</details>

<details>
<summary>Security note on irm | iex</summary>

This is a common PowerShell install pattern (similar to `curl | sh`). The full source code is open at [github.com/emylfy/winrift](https://github.com/emylfy/winrift). All external scripts are verified with SHA256 hashes before execution.

</details>

---

## Benchmark — Don't Trust, Verify

Other tools apply tweaks and hope for the best. Winrift measures 13 system metrics before and after — so you see exactly what changed.

> Typical results on clean Windows 11 24H2 (your numbers will vary):

| Metric | Before | After | Change |
| :--- | ---: | ---: | ---: |
| CPU idle load | 3.2% | 1.1% | -66% |
| RAM usage | 2,800 MB | 2,100 MB | -25% |
| Running processes | 142 | 98 | -31% |
| Running services | 187 | 151 | -19% |
| DPC rate | 48 /s | 22 /s | -54% |
| Context switches | 12,400 /s | 8,600 /s | -31% |

<sub>Full methodology and metric explanations: <a href="docs/tests.md">Testing & Benchmarks Guide</a></sub>

<!-- TODO: screenshot-benchmark.png — capture the benchmark report output at 1920x1080
<p align="center">
	<img src="media/screenshot-benchmark.png" alt="Winrift benchmark comparison report showing before and after metrics" width="70%">
</p>
-->

---

## Features

<!-- TODO: capture screenshots at 1920x1080
<p align="center">
	<img src="media/screenshot-main.png" alt="Winrift main menu" width="45%">&nbsp;&nbsp;
	<img src="media/screenshot-tweaks.png" alt="Winrift system tweaks menu" width="45%">
</p>
<p align="center">
	<img src="media/screenshot-ricing.png" alt="Winrift desktop ricing" width="45%">&nbsp;&nbsp;
	<img src="media/screenshot-security.png" alt="Winrift security tools" width="45%">
</p>
-->

| Feature | What it does |
| :--- | :--- |
| **[Benchmark](docs/tests.md)** | Measure 13 system metrics (CPU, RAM, DPC rate, disk latency, context switches...) before and after tweaks |
| **[System Tweaks](docs/tweaks_guide.md)** | 13 optimization categories — latency, input, SSD/NVMe, GPU scheduling, network, CPU, power, boot, memory, DirectX |
| **GPU Tweaks** | NVIDIA and AMD-specific optimizations with automatic device detection; hybrid GPU support |
| **Security & Privacy** | Disable Defender ([DefendNot](https://github.com/es3n1n/defendnot)), remove Copilot/Recall ([RemoveWindowsAI](https://github.com/zoicware/RemoveWindowsAI)), privacy hardening ([privacy.sexy](https://github.com/undergroundwires/privacy.sexy)) |
| **Drivers** | NVIDIA, AMD, Intel DSA auto-install, HP, Lenovo, ASUS, Acer, MSI, Dell, Huawei, Xiaomi, Gigabyte |
| **Desktop Ricing** | Configs for VSCode/Cursor/Windsurf, Terminal, PowerShell, Oh My Posh, FastFetch, SpotX, Spicetify, Steam themes, Rectify11, macOS cursor |
| **App Bundles** | Curated winget collections via [UniGetUI](https://github.com/marticliment/UniGetUI) — Development, Browsers, Utilities, Productivity, Creative & Media, Gaming, Communications |
| **[Answer File](docs/autounattend_guide.md)** | Automated Windows 11 install — removes 25 bloatware apps, disables telemetry, cleans taskbar |

<details>
<summary><strong>Community Tools</strong> — integrated third-party launchers</summary>

<br>

| Tool | Description |
| :--- | :--- |
| [WinUtil](https://github.com/ChrisTitusTech/winutil) | Install programs, apply tweaks, fixes and updates |
| [WinScript](https://github.com/flick9000/winscript) | Build custom Windows setup scripts |
| [Sparkle](https://github.com/Parcoil/Sparkle) | Optimize and debloat Windows |
| [GTweak](https://github.com/Greedeks/GTweak) | GUI tweaking tool and debloater |

</details>

---

## Compatibility

| Windows Version | Status |
| :---: | :---: |
| Windows 11 25H2 | Supported |
| Windows 11 24H2 | Fully tested |
| Windows 11 23H2 | Supported |
| Windows 11 22H2 | Should work |
| Windows 10 | Not supported |

**Requirements:** PowerShell 5.1+ (included with Windows 11), Administrator privileges, Internet connection.

---

## Troubleshooting

| Problem | Solution |
| :--- | :--- |
| Scripts disabled | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| Module not found | Re-run the install command for the latest version |
| Registry errors | Check `%USERPROFILE%\Winrift\logs\` for the session log |
| UniGetUI fails | `winget source reset --force` in admin PowerShell |

---

## Credits

Built on the work of [AlchemyTweaks/Verified-Tweaks](https://github.com/AlchemyTweaks/Verified-Tweaks), [ashish0kumar/windots](https://github.com/ashish0kumar/windots), [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil), [flick9000/winscript](https://github.com/flick9000/winscript), [Greedeks/GTweak](https://github.com/Greedeks/GTweak), [Parcoil/Sparkle](https://github.com/Parcoil/Sparkle), [marticliment/UniGetUI](https://github.com/marticliment/UniGetUI).

<div align="center">

[MIT License](LICENSE) &bull; [Contributing](CONTRIBUTING.md) &bull; [Report a Bug](https://github.com/emylfy/winrift/issues)

</div>

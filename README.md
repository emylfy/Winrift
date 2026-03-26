<div align="center">

# Winrift

**Benchmark-driven Windows 11 optimization toolkit — tweak, customize**

<a href="https://github.com/emylfy/winrift/stargazers"><img src="https://img.shields.io/github/stars/emylfy/winrift?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=C9CBFF&labelColor=302D41" alt="GitHub Stars"></a>&nbsp;&nbsp;
<a href="https://github.com/emylfy/winrift/blob/main/LICENSE"><img src="https://img.shields.io/github/license/emylfy/winrift?style=for-the-badge&logo=apache&color=CBA6F7&logoColor=CBA6F7&labelColor=302D41&label=License" alt="GitHub License"></a>&nbsp;&nbsp;
<a href="https://github.com/emylfy/winrift/commits/main/"><img src="https://img.shields.io/github/last-commit/emylfy/winrift?style=for-the-badge&logo=github&logoColor=eba0ac&label=Last%20Commit&labelColor=302D41&color=eba0ac" alt="Last Commit"></a>&nbsp;&nbsp;
<a href="https://github.com/emylfy/winrift/releases"><img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Femylfy%2Fwinrift%2Fmain%2Fconfig%2Fversion.json&query=%24.version&prefix=v&style=for-the-badge&label=Version&color=a6e3a1&labelColor=302D41" alt="Version"></a>

<img src="media/screenshot-main.png" alt="Winrift terminal interface main menu" width="90%">

</div>

<h6 align="center">
  <a href="#quick-start">Quick Start</a> ·
  <a href="#features">Features</a> ·
  <a href="#benchmark">Benchmark</a> ·
  <a href="#health-score">Health Score</a> ·
  <a href="#compatibility">Compatibility</a>
</h6>

---

<a id="quick-start"></a>

## ⚡ Quick Start

Open PowerShell as admin — <kbd>Win</kbd> + <kbd>X</kbd> → Terminal Admin:

```powershell
irm https://raw.githubusercontent.com/emylfy/winrift/main/scripts/launch.ps1 | iex
```

> [!NOTE]
> A system restore point is created automatically before any changes. Every registry modification is backed up to JSON for rollback.

<details>
<summary><strong>Pin shortcut to Start Menu</strong></summary>

<br>

```powershell
irm https://raw.githubusercontent.com/emylfy/winrift/main/scripts/install.ps1 | iex
```

</details>

> **Security note:** This is a common PowerShell install pattern (similar to `curl | sh`). The full source code is open at [github.com/emylfy/winrift](https://github.com/emylfy/winrift). Most external scripts are verified with SHA256 hashes before execution.

---

<a id="features"></a>

## 🧩 Features

<p align="center">
	<img src="media/screenshot-features.png" alt="Winrift features" width="80%">
</p>

|     | Feature                                        | What it does                                                                   |
| :-- | :--------------------------------------------- | :----------------------------------------------------------------------------- |
| 📊  | [**Benchmark**](docs/tests.md)                 | 13 metrics before & after, Markdown reports                                    |
| 🩺  | [**Health Score**](docs/health_score.md)       | 0–100 rating, delta tracking, recommendations                                  |
| ⚙️  | [**System Tweaks**](docs/tweaks_guide.md)      | 13 categories — latency, SSD, GPU, network, power, memory, DirectX             |
| 🔄  | [**Drift Detection**](docs/drift_detection.md) | Catches Windows Update reverting your tweaks; one-click reapply                |
| 🛡️  | **Security & Privacy**                         | Defender, Copilot/Recall removal, privacy hardening                            |
| 🖥️  | **Drivers**                                    | NVIDIA · AMD · Intel + 11 OEM manufacturers                                    |
| 🎨  | [**Customize**](modules/customize/README.md)   | Desktop, terminal, editors, app themes — all without admin                     |
| 📦  | **App Bundles**                                | 7 curated collections via [UniGetUI](https://github.com/marticliment/UniGetUI) |
| 💿  | [**ISO Builder**](docs/autounattend_guide.md)  | Embed answer file into Windows 11 ISO for automated install                    |

<br>

<details>
<summary><strong>⚙️ System Tweaks — all 13 categories</strong></summary>

<br>

Every tweak is backed up before applying. Choose individually or apply all.

|   # | Category       | Risk | What it does                                     |
| --: | :------------- | :--: | :----------------------------------------------- |
|   1 | System Latency |  🟡  | Interrupt steering, timer serialization          |
|   2 | Input Devices  |  🟢  | Queue sizes, sticky/filter keys, input delays    |
|   3 | SSD / NVMe     |  🟢  | TRIM, defrag, last access, 8.3 names, prefetcher |
|   4 | GPU Scheduling |  🟡  | Hardware scheduling, preemption                  |
|   5 | Network        |  🟢  | Network throttling, lazy mode                    |
|   6 | CPU            |  🟢  | MMCSS, multimedia scheduler                      |
|   7 | Power          |  🟡  | C-states, PCIe ASPM, Ultimate Performance plan   |
|   8 | Responsiveness |  🟢  | Program priority, IRQ optimization               |
|   9 | Boot           |  🟢  | Startup delays, desktop switch timeout           |
|  10 | UI             |  ⚠️  | Auto-end tasks, hung app timeout, menu delay     |
|  11 | Memory         |  🟡  | Large system cache (16 GB+), page combining      |
|  12 | Maintenance    |  🔧  | Automatic maintenance, I/O counting              |
|  13 | DirectX        |  ⚠️  | D3D12/D3D11 optimizations, multithreading        |

GPU-specific tweaks are auto-detected:

- **NVIDIA** — per-CPU core DPC optimization
- **AMD** — 40+ tweaks including power gating, color depth, latency

</details>

<details>
<summary><strong>🔄 Drift Detection — keep tweaks applied</strong></summary>

<br>

Windows Updates silently revert registry changes. Drift Detection catches this.

- Tracks every applied tweak in a desired-state JSON
- Compares current registry against desired state
- Reports each entry as **OK** · **Drifted** · **Missing**
- One-click reapply for all drifted values
- Optional scheduled task runs automatically after updates

<sub>→ <a href="docs/drift_detection.md">Drift Detection Guide</a></sub>

</details>

<details>
<summary><strong>🛡️ Security & Privacy tools</strong></summary>

<br>

| Tool                | Description                                                 |
| :------------------ | :---------------------------------------------------------- |
| **DefendNot**       | Disable Windows Defender via Security Center API            |
| **RemoveWindowsAI** | Remove Copilot and Recall packages                          |
| **privacy.sexy**    | Comprehensive privacy hardening — standard or custom preset |

All tools run only when explicitly selected.

</details>

<details>
<summary><strong>🎨 Desktop Customization</strong></summary>

<br>

Complete environment setup from one menu. Runs without admin.

**Desktop** — [GlazeWM](https://github.com/glzr-io/glazewm) tiling WM · [Zebar](https://github.com/glzr-io/zebar) status bar · [Flow Launcher](https://github.com/Flow-Launcher/Flow.Launcher) · [Windhawk](https://windhawk.net/) · [Rainmeter](https://www.rainmeter.net/)

**Terminal** — Windows Terminal config · Nerd Fonts · Oh My Posh / Starship · FastFetch · PowerShell profile

**Editors** — Config import for VSCode · Cursor · AIDE · Windsurf · VSCodium · Trae

**Themes** — Rectify11 · SpotX · Spicetify · Steam Millennium

</details>

<details>
<summary><strong>💿 ISO Builder</strong></summary>

<br>

Create a bootable Windows 11 ISO with automation baked in:

- Embeds `autounattend.xml` answer file
- Removes 25 bloatware apps (Cortana, Teams, Edge, News, OneDrive...)
- Disables telemetry and Copilot
- Bypasses TPM / SecureBoot / RAM checks
- Launches Winrift on first login

<sub>→ <a href="docs/autounattend_guide.md">Autounattend Guide</a></sub>

</details>

<details>
<summary><strong>📦 App Bundles</strong></summary>

<br>

Install curated app collections via [UniGetUI](https://github.com/marticliment/UniGetUI):

Development · Browsers · Utilities · Productivity · Creative & Media · Gaming · Communications

Uses winget, Chocolatey, and other package sources.

</details>

<details>
<summary><strong>🌐 Community Tools</strong></summary>

<br>

| Tool                                                 | Description                     |
| :--------------------------------------------------- | :------------------------------ |
| [WinUtil](https://github.com/ChrisTitusTech/winutil) | Tweaks, apps, fixes and updates |
| [WinScript](https://github.com/flick9000/winscript)  | Custom Windows setup scripts    |
| [Sparkle](https://github.com/Parcoil/Sparkle)        | Optimize and debloat            |
| [GTweak](https://github.com/Greedeks/GTweak)         | GUI tweaking and debloater      |

</details>

---

<a id="benchmark"></a>

## 📊 Benchmark

Other tools apply tweaks and hope for the best. Winrift measures 13 system metrics before and after — so you see exactly what changed.

> Typical results on clean Windows 11 24H2 (your numbers will vary):

| Metric            |    Before |    After |   Change |
| :---------------- | --------: | -------: | -------: |
| CPU idle load     |      3.2% |     1.1% | **−66%** |
| RAM usage         |  2,800 MB | 2,100 MB | **−25%** |
| Running processes |       142 |       98 | **−31%** |
| Running services  |       187 |      151 | **−19%** |
| DPC rate          |     48 /s |    22 /s | **−54%** |
| Context switches  | 12,400 /s | 8,600 /s | **−31%** |

<sub>Full methodology and metric explanations: <a href="docs/tests.md">Testing & Benchmarks Guide</a></sub>

---

<a id="health-score"></a>

## 🩺 Health Score

Composite **0–100 rating** across 7 weighted categories with delta tracking — see how your system improves over time.

| Category          | Weight | Checks                                       |
| :---------------- | :----: | :------------------------------------------- |
| **Latency**       |  20%   | DPC rate, context switches, interrupts       |
| **Privacy**       |  20%   | Telemetry, diagnostics, Copilot, ad tracking |
| **Memory**        |  15%   | RAM usage, committed ratio, page faults      |
| **Network**       |  15%   | Throttling, Nagle algorithm, TCP tuning      |
| **Process Bloat** |  10%   | Running processes and services count         |
| **Startup**       |  10%   | Startup apps and scheduled tasks             |
| **Storage**       |  10%   | SSD/NVMe optimization, TRIM, prefetcher      |

> [!TIP]
> Low-scoring categories get automatic recommendations. Run it before and after tweaks to track your improvement.

<sub>Scoring methodology → <a href="docs/health_score.md">Health Score Guide</a></sub>

---

<a id="compatibility"></a>

## ✅ Compatibility

| Windows Version        | Status        |
| :--------------------- | :------------ |
| Windows 11 25H2        | Fully tested  |
| Windows 11 24H2 / 22H2 | Supported     |
| Windows 10             | Not supported |

**Requirements:** PowerShell 5.1+ · Administrator · Internet connection

---

<a id="troubleshooting"></a>

## 🔧 Troubleshooting

| Problem               | Solution                                                     |
| :-------------------- | :----------------------------------------------------------- |
| Scripts disabled      | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`        |
| Module not found      | Re-run the install command for the latest version            |
| Registry errors       | Check `%USERPROFILE%\Winrift\logs\` for the session log      |
| Tweak broke something | System Tweaks → Restore Backup, or boot from a restore point |
| UniGetUI fails        | `winget source reset --force` in admin PowerShell            |

---

<a id="credits"></a>

## 🏆 Credits

Built on the work of [AlchemyTweaks/Verified-Tweaks](https://github.com/AlchemyTweaks/Verified-Tweaks), [ashish0kumar/windots](https://github.com/ashish0kumar/windots), [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil), [flick9000/winscript](https://github.com/flick9000/winscript), [Greedeks/GTweak](https://github.com/Greedeks/GTweak), [Parcoil/Sparkle](https://github.com/Parcoil/Sparkle), [marticliment/UniGetUI](https://github.com/marticliment/UniGetUI).

<div align="center">

[MIT License](LICENSE) · [Contributing](CONTRIBUTING.md) · [Changelog](CHANGELOG.md) · [Report a Bug](https://github.com/emylfy/winrift/issues)

<sub>If Winrift improved your setup, consider leaving a ⭐</sub>

</div>

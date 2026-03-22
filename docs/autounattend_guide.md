# 🪟 Windows Unattended Installation

<div align="center">
  <p><em>Install Windows 11 clean and debloated — without clicking through setup screens</em></p>
</div>

## ❓ What is this?

An `autounattend.xml` is a special file that automates the Windows installer. Place it on your USB drive or into your ISO, and Windows will configure itself automatically — no extra clicks, no bloatware, no telemetry prompts.

This file does more than skip setup screens. It also runs scripts during installation that remove pre-installed apps, disable tracking, and clean up the interface. You don't need any technical knowledge — just follow one of the installation methods below.

> 🛠️ **Want to customize?** This file was generated with [Unattend-Generator](https://schneegans.de/windows/unattend-generator/) — you can use it to create your own version

> 🔧 **Integrated with [Winrift](https://github.com/emylfy/winrift)** — a desktop shortcut is created automatically for further post-install tweaks

## ✨ What You'll Get

After installing Windows with this file, your system will have:

- **25 bloatware apps removed** — no Cortana, Clipchamp, Teams, News, Weather, etc. ([full list below](#-removed-apps))
- **No auto-installing apps** — Copilot, OneDrive, Teams, and Outlook won't sneak back in
- **Clean taskbar** — no widgets, no search box, no Task View button
- **Empty Start menu** — no pinned ads or suggested apps
- **File Explorer opens to "This PC"** — with file extensions and hidden files visible
- **No system sounds** — startup sound and all event sounds disabled
- **Works on unsupported hardware** — TPM 2.0, Secure Boot, and RAM checks bypassed
- **SmartScreen disabled** — see [Warnings](#%EF%B8%8F-warnings) for details
- **Winrift desktop shortcut** — one-click access to further customization

## 📥 Installation Guide

> **Download:** [autounattend.xml](https://github.com/emylfy/winrift/blob/main/docs/autounattend.xml)

### Method 1 — USB Flash Drive (Simplest)

1. Create a bootable Windows USB using [Rufus](https://rufus.ie/), the [Media Creation Tool](https://www.microsoft.com/software-download/windows11), or [Ventoy](https://www.ventoy.net/)
2. Download [autounattend.xml](https://github.com/emylfy/winrift/blob/main/docs/autounattend.xml)
3. Copy `autounattend.xml` to the **root** of the USB drive (same level as `setup.exe`)
4. Boot from the USB drive and install Windows as usual — the file is detected automatically

### Method 2 — Modify an Existing ISO (AnyBurn)

1. Download [AnyBurn](https://anyburn.com/) and the [autounattend.xml](https://github.com/emylfy/winrift/blob/main/docs/autounattend.xml) file
2. Open AnyBurn and select **"Edit Image File"**
3. Browse to your Windows ISO file
4. Click **"Add"** and select `autounattend.xml`
5. Make sure it's placed at the **root level** (not inside a folder)
6. Click **"Save"** to produce the modified ISO
7. Burn the ISO to a USB drive or mount it for a virtual machine

### Method 3 — Automated ISO Build

Use [tiny11maker-reforged](https://github.com/chrisGrando/tiny11maker-reforged) — a PowerShell script that builds a trimmed-down Windows 11 image (supports 24H2 and 25H2). This strips components at the image level rather than using an answer file, so it produces a smaller ISO.

## ⚠️ Warnings

> **SmartScreen is disabled system-wide.** It normally blocks unrecognized apps and downloads. Re-enable it anytime via **Windows Security > App & browser control**.

> **Windows Defender is NOT disabled** — only the tray icon is hidden. Defender still runs in the background. You can show the icon again in Windows Security settings.

> **Edge SmartScreen and PUA detection are disabled** for the default user profile. Re-enable in **Edge Settings > Privacy** if you want download warnings back.

> **TPM and Secure Boot checks are bypassed.** This allows installation on unsupported hardware, but BitLocker may not work without TPM.

> **All telemetry is disabled** with the most restrictive privacy setting Windows offers.

> **PowerShell execution policy is set to RemoteSigned.** Local scripts run freely; downloaded scripts need a digital signature.

## 🎛️ Customization

- **Generate your own:** Use the [Schneegans Unattend-Generator](https://schneegans.de/windows/unattend-generator/) to create a customized version with different app removals, settings, or configurations
- **Edit directly:** Advanced users can modify the XML file manually, or import it back into the [Unattend-Generator](https://schneegans.de/windows/unattend-generator/) to tweak settings through the UI and re-export
- **Post-install tweaks:** Use [Winrift](https://github.com/emylfy/winrift) after installation for additional optimization — a desktop shortcut is created automatically

## 📦 Removed Apps

<details>
<summary>25 pre-installed apps removed during installation (click to expand)</summary>

| App | Package ID |
|-----|-----------|
| 3D Viewer | Microsoft.Microsoft3DViewer |
| Bing Search | Microsoft.BingSearch |
| Clipchamp | Clipchamp.Clipchamp |
| Cortana | Microsoft.549981C3F5F10 |
| Family | MicrosoftCorporationII.MicrosoftFamily |
| Feedback Hub | Microsoft.WindowsFeedbackHub |
| Get Help | Microsoft.GetHelp |
| Get Started (Tips) | Microsoft.Getstarted |
| Mail & Calendar | microsoft.windowscommunicationsapps |
| Maps | Microsoft.WindowsMaps |
| Mixed Reality Portal | Microsoft.MixedReality.Portal |
| Movies & TV | Microsoft.ZuneVideo |
| News | Microsoft.BingNews |
| Office 365 Hub | Microsoft.MicrosoftOfficeHub |
| OneNote | Microsoft.Office.OneNote |
| Outlook (new) | Microsoft.OutlookForWindows |
| People | Microsoft.People |
| Power Automate | Microsoft.PowerAutomateDesktop |
| Quick Assist | MicrosoftCorporationII.QuickAssist |
| Skype | Microsoft.SkypeApp |
| Solitaire Collection | Microsoft.MicrosoftSolitaireCollection |
| Sticky Notes | Microsoft.MicrosoftStickyNotes |
| Teams | MicrosoftTeams / MSTeams |
| To Do | Microsoft.Todos |
| Weather | Microsoft.BingWeather |

**Also removed:**

- **Capabilities**: OneSync, Quick Assist (system capability), Steps Recorder
- **Features**: Remote Desktop Connection client

</details>

## 🔄 What Happens During Installation

<details>
<summary>Stage 1 — Before installation (Windows PE)</summary>

The very first stage, before Windows is installed on disk:

- Bypasses TPM 2.0, Secure Boot, and RAM checks
- Auto-accepts the EULA

> You still choose language, disk, and Windows edition yourself.

</details>

<details>
<summary>Stage 2 — System configuration (Specialize)</summary>

After Windows copies files to disk, scripts run to configure the system:

- **Removes 25 pre-installed apps** ([full list above](#-removed-apps))
- **Removes capabilities**: OneSync, Quick Assist, Steps Recorder
- **Disables feature**: Remote Desktop Connection client
- **Removes OneDrive** — deletes setup files and Start Menu shortcut
- **Blocks auto-install** — prevents Outlook and Teams from installing after setup
- **Allows upgrades on unsupported hardware** — sets AllowUpgradesWithUnsupportedTPMOrCPU
- **Sets password to never expire**
- **Disables SmartScreen** — turns off SmartScreen system-wide and hides Defender tray icon
- **Sets PowerShell execution policy** to RemoteSigned
- **Prevents auto-reboot** for Windows Update when users are logged in
- **Schedules active hours** — keeps Windows Update reboot window away from your usage time
- **Disables widgets and news**
- **Disables startup sound**
- **Disables consumer features** — blocks ads, app suggestions, and cloud-optimized content
- **Hides Edge first-run experience**
- **Clears Start menu pins**

</details>

<details>
<summary>Stage 3 — Default user profile settings</summary>

These settings apply to every new user account created on the system:

- **Disables Windows Copilot**
- **Removes OneDrive from startup**
- **Applies empty taskbar layout** — replaces default pins, locks then unlocks after first login
- **Shows file extensions** and **hidden files**
- **Hides Task View button**
- **Disables Edge SmartScreen** — both SmartScreen and PUA (Potentially Unwanted App) detection
- **Turns off all system sounds**
- **Disables all content delivery** — 15+ registry values covering app suggestions, pre-installed apps, subscribed content, and tips
- **Disables Bing search suggestions** in the search box

</details>

<details>
<summary>Stage 4 — First login (OOBE)</summary>

During the Out-of-Box Experience and first user login:

- **All telemetry/express settings disabled** (most restrictive)
- **EULA page hidden**
- **Wi-Fi and account screens remain interactive** — you still choose your network and create your account

Then two scripts run at first login:

**Per-user setup** (runs for every new user account):

- Removes Copilot app package
- Unlocks Start menu layout (so you can rearrange it)
- Sets sound scheme to "No Sounds"
- Opens File Explorer to "This PC" instead of Quick Access
- Hides search box on taskbar
- Hides all desktop icons
- Restarts Explorer to apply changes

**First logon only:**

- **Creates "Winrift" desktop shortcut** for post-install customization

</details>

## 🔧 Technical Details

<details>
<summary>Configuration Passes</summary>

- `windowsPE` — Hardware check bypasses, EULA acceptance
- `specialize` — App removal, registry tweaks, scheduled tasks, system configuration
- `oobeSystem` — Telemetry disable, first-logon shortcut creation

</details>

<details>
<summary>Script Locations (after installation)</summary>

| Script | Path | Purpose |
|--------|------|---------|
| Specialize.ps1 | C:\Windows\Setup\Scripts\ | Main system configuration orchestrator |
| RemovePackages.ps1 | C:\Windows\Setup\Scripts\ | Removes provisioned app packages |
| RemoveCapabilities.ps1 | C:\Windows\Setup\Scripts\ | Removes Windows capabilities |
| RemoveFeatures.ps1 | C:\Windows\Setup\Scripts\ | Disables optional features |
| DefaultUser.ps1 | C:\Windows\Setup\Scripts\ | Default user profile registry settings |
| UserOnce.ps1 | C:\Windows\Setup\Scripts\ | Per-user first-run configuration |
| FirstLogon.ps1 | C:\Windows\Setup\Scripts\ | Creates Winrift shortcut |
| SetStartPins.ps1 | C:\Windows\Setup\Scripts\ | Clears Start menu pins |
| TurnOffSystemSounds.ps1 | C:\Windows\Setup\Scripts\ | Disables system event sounds |
| UnlockStartLayout.vbs | C:\Windows\Setup\Scripts\ | Unlocks Start layout after login |
| MoveActiveHours.vbs | C:\Windows\Setup\Scripts\ | Sets Windows Update active hours |

</details>

<details>
<summary>Log Files</summary>

Logs are written during installation for debugging:

- `C:\Windows\Setup\Scripts\Specialize.log`
- `C:\Windows\Setup\Scripts\RemovePackages.log`
- `C:\Windows\Setup\Scripts\RemoveCapabilities.log`
- `C:\Windows\Setup\Scripts\RemoveFeatures.log`
- `C:\Windows\Setup\Scripts\DefaultUser.log`
- `C:\Windows\Setup\Scripts\FirstLogon.log`
- `%TEMP%\UserOnce.log`

</details>

![](https://github.com/emylfy/winrift/blob/main/media/separator.png)

<div align="center">
  <p>Made with ❤️ for the Windows community</p>
  <p>Star ⭐ this repo if you found it useful!</p>
</div>

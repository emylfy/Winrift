# 🪟 Windows Unattended Installation Configuration

<div align="center">
  <p><em>Automate your Windows installation with precision and style</em></p>
  <p>An answer file that tells Windows how to install itself — so you get a clean, debloated system without clicking through setup screens</p>
</div>

## ❓ What is an Autounattend.xml?

When you install Windows from a USB drive or ISO, the installer looks for a file called `autounattend.xml` at the root of your installation media. If it finds one, it uses the instructions inside to answer setup questions automatically — things like accepting the EULA, skipping hardware checks, and configuring settings.

This particular file goes further: it also embeds PowerShell scripts that remove bloatware, disable telemetry, and clean up the UI during installation. No coding knowledge required — you just place the file on your USB drive or into your ISO and install Windows as usual.

> 🛠️ **Want to customize?** This file was generated with [Unattend-Generator](https://schneegans.de/windows/unattend-generator/) — you can use it to create your own version

> 🔧 **Integrated with [Simplify11](https://github.com/emylfy/simplify11)** — a desktop shortcut is created automatically for further post-install tweaks

## ✨ What You'll Get

After installing Windows with this file, your system will have:

- **25 bloatware apps removed** — no Cortana, Clipchamp, Teams, News, Weather, etc. ([full list below](#-removed-apps))
- **No auto-installing apps** — Copilot, OneDrive, Teams, and Outlook won't sneak back in
- **Clean taskbar** — no widgets, no search box, no Task View button
- **Empty Start menu** — no pinned ads or suggested apps
- **File Explorer opens to "This PC"** — with file extensions and hidden files visible
- **No system sounds** — startup sound and all event sounds disabled
- **Works on unsupported hardware** — TPM 2.0, Secure Boot, and RAM checks bypassed
- **SmartScreen disabled** — see [Warnings](#-warnings) for details
- **Simplify11 desktop shortcut** — one-click access to further customization

## 🔄 What Happens During Installation

Here's what the file does at each stage of Windows Setup:

### Stage 1 — Windows PE (Pre-Installation)

The very first stage, before Windows is even installed on disk:

- Bypasses TPM 2.0 check
- Bypasses Secure Boot check
- Bypasses RAM check (minimum 4GB requirement)
- Auto-accepts the EULA

> Language, disk partitioning, and edition selection remain interactive — you still choose these yourself.

### Stage 2 — Specialize (System Configuration)

After Windows copies files to disk, these scripts run to configure the system:

- **Removes 25 pre-installed apps** ([full list below](#-removed-apps))
- **Removes capabilities**: OneSync, Quick Assist, Steps Recorder
- **Disables feature**: Remote Desktop Connection client
- **Removes OneDrive** — deletes setup files and Start Menu shortcut
- **Blocks auto-install** — prevents Outlook and Teams from installing after setup
- **Allows upgrades on unsupported hardware** — sets AllowUpgradesWithUnsupportedTPMOrCPU
- **Sets password to never expire**
- **Disables SmartScreen** — turns off SmartScreen system-wide and hides Defender tray icon
- **Sets PowerShell execution policy** to RemoteSigned
- **Prevents auto-reboot** for Windows Update when users are logged in
- **Schedules active hours** — keeps Windows Update reboot window away from your current usage time
- **Disables widgets and news**
- **Disables startup sound**
- **Disables consumer features** — blocks ads, app suggestions, and cloud-optimized content
- **Hides Edge first-run experience**
- **Clears Start menu pins**

### Stage 3 — Default User Profile

These settings are baked into the default user profile, so every new user account gets them:

- **Disables Windows Copilot**
- **Removes OneDrive from startup**
- **Applies empty taskbar layout** — replaces default taskbar pins with an empty layout, locks it then unlocks after first login
- **Shows file extensions** (HideFileExt = 0)
- **Shows hidden files** (Hidden = 1)
- **Hides Task View button**
- **Disables Edge SmartScreen** — both main SmartScreen and PUA (Potentially Unwanted App) detection
- **Turns off all system sounds**
- **Disables all content delivery** — 15+ registry values covering app suggestions, pre-installed apps, subscribed content, and soft-landing tips
- **Disables Bing search suggestions** in the search box

### Stage 4 — First Login (OOBE + User Setup)

During the Out-of-Box Experience and first user login:

- **All telemetry/express settings disabled** (ProtectYourPC = 3, the most restrictive setting)
- **EULA page hidden**
- **Wi-Fi and account screens remain interactive** — you still choose your network and create your account

Then, two scripts run at first login:

**Per-user setup** (runs via RunOnce for every new user account):

- Removes Copilot app package
- Unlocks Start menu layout (so you can rearrange it)
- Sets sound scheme to "No Sounds"
- Opens File Explorer to "This PC" instead of Quick Access
- Hides search box on taskbar
- Hides all desktop icons
- Restarts Explorer to apply changes

**First logon only** (runs once during OOBE):

- **Creates "Simplify11" desktop shortcut** — launches the Simplify11 tool for post-install customization

## 📦 Removed Apps

All 25 provisioned apps are removed during installation (26 package selectors — Teams has two entries):

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

## ⚠️ Warnings

> **SmartScreen is disabled system-wide.** SmartScreen normally blocks unrecognized apps and downloads. This config turns it off to avoid prompts when running legitimate tools. If you download software from unknown sources, consider re-enabling it via **Windows Security > App & browser control**.

> **Windows Defender tray icon is hidden** — but Defender itself is NOT disabled. It still runs in the background. You can re-enable the tray icon through Windows Security settings.

> **Edge SmartScreen and PUA detection are disabled** for the default user profile. This means Edge won't warn about potentially unwanted apps or suspicious downloads. You can re-enable these in **Edge Settings > Privacy**.

> **TPM and Secure Boot checks are bypassed.** This allows installation on unsupported hardware, but means you lose some hardware-backed security features. BitLocker may not function without TPM.

> **All telemetry and express settings are disabled** (ProtectYourPC = 3). This is the most restrictive privacy setting Windows offers during setup.

> **PowerShell execution policy is set to RemoteSigned.** This means locally created scripts run freely, but scripts downloaded from the internet need a digital signature. This is less restrictive than the default (Restricted) but safer than Unrestricted.

## 📥 Installation Guide

> **Download:** [autounattend.xml](https://github.com/emylfy/simplify11/blob/main/docs/autounattend.xml)

### Method 1 — USB Flash Drive (Simplest)

1. Create a bootable Windows USB using [Rufus](https://rufus.ie/), the [Media Creation Tool](https://www.microsoft.com/software-download/windows11), or [Ventoy](https://www.ventoy.net/)
2. Download [autounattend.xml](https://github.com/emylfy/simplify11/blob/main/docs/autounattend.xml)
3. Copy `autounattend.xml` to the **root** of the USB drive (same level as `setup.exe`)
4. Boot from the USB drive and install Windows as usual — the file is detected automatically

### Method 2 — Modify an Existing ISO (AnyBurn)

1. Download [AnyBurn](https://anyburn.com/) and the [autounattend.xml](https://github.com/emylfy/simplify11/blob/main/docs/autounattend.xml) file
2. Open AnyBurn and select **"Edit Image File"**
3. Browse to your Windows ISO file
4. Click **"Add"** and select `autounattend.xml`
5. Make sure it's placed at the **root level** (not inside a folder)
6. Click **"Save"** to produce the modified ISO
7. Burn the ISO to a USB drive or mount it for a virtual machine

### Method 3 — Automated ISO Build

Use [tiny11builder-24H2](https://github.com/chrisGrando/tiny11builder-24H2) — a PowerShell script that builds a trimmed-down Windows 11 24H2 image. This strips components at the image level rather than using an answer file, so it produces a smaller ISO.

## 🎛️ Customization

- **Generate your own:** Use the [Schneegans Unattend-Generator](https://schneegans.de/windows/unattend-generator/) to create a customized version with different app removals, settings, or configurations
- **Edit directly:** Advanced users can modify the XML file — the embedded PowerShell scripts in the `<Extensions>` section are where app removal and registry tweaks live
- **Post-install tweaks:** Use [Simplify11](https://github.com/emylfy/simplify11) after installation for additional optimization — a desktop shortcut is created automatically

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
| FirstLogon.ps1 | C:\Windows\Setup\Scripts\ | Creates Simplify11 shortcut |
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

![](https://github.com/emylfy/simplify11/blob/main/media/separator.png)

<div align="center">
  <p>Made with ❤️ for the Windows community</p>
  <p>Star ⭐ this repo if you found it useful!</p>
</div>

# 🪟 Windows Installation Media (experimental)

The complete build → boot → install → restore cycle has not yet been validated for this version. Test the generated image in a disposable VM before relying on it. [Validation procedure](setup.md#manual-validation).

<div align="center">
  <p><em>Build a Windows ISO with your tweaks, apps, and configs ready for first sign-in.</em></p>
</div>

## ❓ What can I put in the ISO?

- **Your saved Winrift setup** brings your selected tweaks, apps, and configs to a fresh Windows install. You go through Windows Setup as usual, then Winrift runs at first sign-in.
- **An answer file** (`autounattend.xml`) automates Windows Setup itself. Use your own file to decide what happens during installation.

You can include either file or both. If you just want your usual apps and settings back after a reinstall, save your setup in Winrift and keep the standard Windows installer.

## 📥 Build an ISO in Winrift

Start with a Windows 11 26H2 ISO and enough free space for a temporary copy of its contents and the finished image. To bring over your current setup, export it from **Save / Restore Setup → Save Setup**.

Open **Save / Restore Setup → Create Windows Installation Media**.

1. **Select Windows ISO** and choose your source image.
2. Under **Windows Installation Options**, keep **Standard interactive Windows Setup** or choose your own `autounattend.xml`.
3. Under **Include Saved Setup**, choose the setup you exported if you want Winrift to apply it at first sign-in.
4. Open **Review & Build**, give the new ISO a path, and check what will go into it. Choose **Build ISO**.

Winrift uses Microsoft's `oscdimg.exe`. If it can't find the tool, it offers to download it or open the Windows ADK download page. Your source ISO stays intact.

Boot the new ISO in a VM or use it to create a bootable USB. If you included a saved setup, the ISO contains the Winrift scripts from the copy you used to build it. Windows runs those scripts locally at first sign-in. PowerShell 7 and app installs may still need internet access.

## 🔌 Other ways to prepare your installation media

### Use an answer file on a bootable Windows USB

If you need to create the USB first, use a Windows media creation tool such as Rufus or Microsoft's Media Creation Tool. Once the Windows installer files are on the drive, copy `autounattend.xml` to the root, next to `setup.exe`, and boot from it.

### Add an answer file to an ISO with AnyBurn

1. Open AnyBurn and choose **Edit image file**.
2. Open your Windows ISO. Add `autounattend.xml` at the top level, alongside `setup.exe`.
3. Choose **Next** and save to a new ISO path. Boot the new ISO in a VM or use it to create a bootable USB.

Both methods carry your installer choices. To embed a saved Winrift setup and its scripts, use **Include Saved Setup** in the Winrift builder. [AnyBurn's ISO editing guide](https://www.anyburn.com/tutorials/edit-iso-file.htm).

### Build a trimmed Windows image

[tiny11maker-reforged](https://github.com/chrisGrando/tiny11maker-reforged) removes components from the Windows image itself. Its project documents Windows 11 24H2 and 25H2. For the 26H2 workflow in this guide, start with the standard Windows ISO.

## 🎛️ Customize your answer file

Create your own with the [Schneegans Unattend Generator](https://schneegans.de/windows/unattend-generator/), or start from [Winrift's bundled answer file](../config/autounattend.xml). The bundled file is optional. Select it explicitly if you want the changes below.

> [!WARNING]
> The bundled answer file disables Windows and Edge SmartScreen and requests TPM, Secure Boot, and RAM check bypasses. Review the file before using it.

The bundled file creates a Winrift desktop shortcut that opens the online launcher. If you also choose **Include Saved Setup**, a separate first-sign-in command applies your setup using the scripts inside the ISO.

## 📦 What the bundled answer file changes

<details>
<summary>Packages selected for removal</summary>

| App | Package ID |
|-----|-----------|
| 3D Viewer | Microsoft.Microsoft3DViewer |
| Bing Search | Microsoft.BingSearch |
| Clipchamp | Clipchamp.Clipchamp |
| Copilot | Microsoft.Copilot |
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

- **Removes matching provisioned apps** from the list above
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

- **Express settings disabled** by the answer file
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

## 🧪 Check the result

Boot the finished ISO in a VM, install Windows, and sign in. If you included a saved setup, check that your settings, apps, and configs made it across. For Winrift errors, look under `%LOCALAPPDATA%\Winrift\logs`. The log paths above are for scripts in the bundled answer file.

The full ISO boot and installation cycle remains unverified for this version. See the [validation notes](validation.md).

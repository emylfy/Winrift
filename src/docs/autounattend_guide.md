# 🪟 Windows Unattended Installation Configuration

<div align="center">
  <p><em>Automate your Windows installation with precision and style</em></p>
</div>

## ✨ Overview

This XML configuration file automates the Windows installation process, providing a streamlined setup experience with pre-configured system settings, bloatware removal, and optimized user preferences.

> 🛠️ **Configure Your Own:** Visit [Unattend-Generator](https://schneegans.de/windows/unattend-generator/) to customize settings

> 🔧 **Integrated with [Simplify11](https://github.com/emylfy/simplify11) shorcut in Start Menu**

## 🚀 Key Features

<div align="center">
  <table>
    <tr>
      <td align="center">
        <img src="https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Gear/3D/gear_3d.png" width="60px" alt="Settings">
        <br/><b>System Settings</b>
        <br/><small>Language, Locale & Input</small>
      </td>
      <td align="center">
        <img src="https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Wastebasket/3D/wastebasket_3d.png" width="60px" alt="Cleanup">
        <br/><b>Bloatware Removal</b>
        <br/><small>20+ Pre-installed Apps</small>
      </td>
      <td align="center">
        <img src="https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Sparkles/3D/sparkles_3d.png" width="60px" alt="Customization">
        <br/><b>UI Customization</b>
        <br/><small>Taskbar & Desktop</small>
      </td>
    </tr>
  </table>
</div>

## 🎯 What It Does

### 🧹 Removes Bloatware
- Microsoft 3D Viewer, Bing apps
- Clipchamp, Maps, Mixed Reality
- OneNote, Outlook, Teams
- And many more...

### ⚙️ System Optimizations
- Disables system sounds
- Removes OneDrive integration
- Configures privacy settings
- Customizes Explorer settings

### 🎨 UI Enhancements
- Sets solid color background
- Removes taskbar clutter
- Shows file extensions
- Optimizes default view settings

## 📥 Installation Guide

1. Open AnyBurn and select "Edit Image File"
2. Choose your Windows ISO file
3. Paste the [autounattend.xml](https://github.com/emylfy/simplify11/blob/main/src/docs/autounattend.xml) file into ISO root
4. Complete the burning process to create your bootable media
5. Start the Windows installation process, the script will be applied automatically

> 📥 **Download XML File:** [autounattend.xml](https://github.com/emylfy/simplify11/blob/main/src/docs/autounattend.xml)

The configuration will be applied automatically during installation.

## 🔧 Technical Details

<details>
<summary>Configuration Passes</summary>

- `windowsPE`: Initial setup configuration
- `specialize`: System customization
- `oobeSystem`: Out-of-box experience settings
</details>

<details>
<summary>Script Locations</summary>

- Main scripts: `C:\Windows\Setup\Scripts\`
- Temp files: `C:\Windows\Temp\`
- Logs: Various `.log` files for debugging
</details>

## ⚠️ Important Notes

- Backup your data before using
- Requires Windows 11 ISO
- Internet connection recommended
- Some settings may vary by Windows version

---

<div align="center">
  <p>Made with ❤️ for the Windows community</p>
  <p>Star ⭐ this repo if you found it useful!</p>
</div>
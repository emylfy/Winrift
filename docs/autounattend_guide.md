# 🪟 Windows Unattended Installation Configuration

<div align="center">
  <p><em>Automate your Windows installation with precision and style</em></p>
</div>

## ✨ Overview

This XML configuration file automates the Windows installation process, ensuring a clean, optimized, and user-friendly setup. It removes unnecessary bloatware, configures system settings, enhances the user interface, and applies various optimizations to improve performance and privacy

> 🛠️ **Configure Your Own:** Visit [Unattend-Generator](https://schneegans.de/windows/unattend-generator/) to customize settings

> 🔧 **Integrated with [Simplify11](https://github.com/emylfy/simplify11) shorcut in Start Menu**

## 🎯 What It Does

### 🧹 **Bloatware Removal**

- Removes over 20 pre-installed apps and unnecessary Windows features like Quick Assist and Steps Recorder.

### ⚙️ **System Optimizations**

- Bypasses TPM 2.0 and Secure Boot for broader compatibility
- Disables telemetry, Cortana, Bing search, and other data collection
- Customizes File Explorer, Start Menu, and Taskbar for a cleaner experience
- Disables system sounds, removes OneDrive, and optimizes Windows Update settings

### 🎨 **UI Enhancements**

- Hides default desktop icons
- Customizes the Taskbar and Start Menu for a clutter-free look

### 🔒 **Security and Privacy**

- Disables SmartScreen and unnecessary Windows Defender notifications
- Turns off Edge’s first-run experience and consumer features like ads and suggestions

## 📥 Installation Guide

> **Download XML File:** [autounattend.xml](https://github.com/emylfy/simplify11/blob/main/docs/autounattend.xml)

For manual creation:

1. Open AnyBurn and select "Edit Image File"
2. Choose your Windows ISO file
3. Paste the [autounattend.xml](https://github.com/emylfy/simplify11/blob/main/docs/autounattend.xml) file into ISO root
4. Complete the burning process to create your bootable media

For automated creation:

Use [tiny11builder-24H2](https://github.com/chrisGrando/tiny11builder-24H2) - PowerShell script to build a Windows 11 24H2 image

## 🔧 Technical Details

<summary>Configuration Passes</summary>

- `windowsPE`: Initial setup configuration
- `specialize`: System customization
- `oobeSystem`: Out-of-box experience settings

<summary>Script Locations</summary>

- Main scripts: `C:\Windows\Setup\Scripts\`
- Temp files: `C:\Windows\Temp\`
- Logs: Various `.log` files for debugging

![](https://github.com/emylfy/simplify11/blob/main/media/separator.png)

<div align="center">
  <p>Made with ❤️ for the Windows community</p>
  <p>Star ⭐ this repo if you found it useful!</p>
</div>

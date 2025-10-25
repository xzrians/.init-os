# 📦 Package Manager Guide

This installation script supports both **Chocolatey** and **Winget** package managers with automatic setup and intelligent migration detection.

## 🚀 Quick Start

### First Run Auto-Setup

The script automatically installs both package managers on first run:

1. **Chocolatey** - Automatically downloaded and installed if missing
2. **Winget (App Installer)** - Opened in Microsoft Store for installation if missing

No manual setup required! Just run the script and follow the prompts.

---

## 📝 Unified YAML Format

All profiles are in `packages.yaml` with a clean, simplified structure.

### Basic Structure (Unified File)

All profiles in one `packages.yaml` file:

```yaml
---
# Profile sections
basic:
  winget:
    - Package.ID
    - 9NXXXXXX  # Microsoft Store Product ID
  
  choco:
    - packagename
    - another-package

developer:
  winget:
    - Microsoft.VisualStudioCode
  
  choco:
    - git.install
    - docker-desktop
```

### Complete Example

```yaml
---
# PowerShell Tools Profile
powershell:
  winget:
    # Terminal via winget (auto-updates from Microsoft Store)
    - Microsoft.WindowsTerminal
    - Microsoft.PowerShell

  choco:
    # PowerShell utilities
    - oh-my-posh
    - nerd-fonts-cascadiacode
    - posh-git

# Social Profile with Winget Store Apps
social:
  winget:
    - 9NKSQGP7F2NH              # WhatsApp (Microsoft Store)
    - Telegram.TelegramDesktop  # Telegram Desktop
  
  choco:
    - discord
    - slack
```

---

## 🎯 No More Repetitive Syntax!

### ❌ Old Format (Verbose - Deprecated):
```yaml
packages:
  messaging:
    - package: 9NKSQGP7F2NH
      manager: winget
      name: WhatsApp
    - package: Telegram.TelegramDesktop
      manager: winget
      name: Telegram
    - discord
```

### ✅ New Format (Clean & Organized):
```yaml
social:
  winget:
    - 9NKSQGP7F2NH              # WhatsApp
    - Telegram.TelegramDesktop  # Telegram

  choco:
    - discord
```

**Benefits:**
- 📦 All profiles in one file
- 🎯 Clear profile organization
- 📝 67% less code
- 🔍 Easier to find and manage packages

---

## 🔍 Finding Package IDs

### For Winget:
```powershell
# Search for packages
winget search telegram

# Example output:
# Name              Id                          Version
# ---------------------------------------------------------
# Telegram Desktop  Telegram.TelegramDesktop    5.2.3

# Search Microsoft Store apps by name
winget search whatsapp

# For Store apps, you can also use the Product ID directly:
# WhatsApp: 9NKSQGP7F2NH
# Windows Terminal: 9N0DX20HK701
```

### For Chocolatey:
```powershell
# Search for packages
choco search chrome

# Example output:
# googlechrome 123.0.6312.106
# chromium 123.0.6312.58

# Or visit the website:
# https://community.chocolatey.org/packages
```

### Finding Microsoft Store Product IDs

1. Open Microsoft Store app
2. Search for the app (e.g., WhatsApp)
3. Look at the URL: `https://www.microsoft.com/store/apps/9NKSQGP7F2NH`
4. The Product ID is the code at the end: `9NKSQGP7F2NH`

---

## 🎯 When to Use Each Manager

### Use Winget When:
- ✅ Installing **Microsoft Store apps** (WhatsApp, Windows Terminal)
- ✅ Want **automatic updates** via Microsoft Store
- ✅ Official vendor provides **winget package**
- ✅ Prefer **native Windows** package manager
- ✅ Apps with **frequent updates** from official sources

### Use Chocolatey When:
- ✅ Package **not available** in winget
- ✅ Installing **development tools** (many only in Chocolatey)
- ✅ More **mature package ecosystem** (established since 2011)
- ✅ **Default choice** for most apps
- ✅ Need **offline installation** capability
- ✅ Require **specific versions** or dependencies

---

## 📚 Real-World Examples

### Social Media & Communication
```yaml
social:
  winget:
    - 9NKSQGP7F2NH              # WhatsApp (Microsoft Store)
    - Telegram.TelegramDesktop  # Telegram Desktop

  choco:
    - discord
    - slack
    - zoom
```

### Development Environment
```yaml
developer:
  winget:
    - Microsoft.VisualStudioCode  # VS Code (auto-updates)
    - Git.Git                     # Git for Windows

  choco:
    - nodejs                      # Node.js
    - python                      # Python
    - docker-desktop              # Docker Desktop
    - postman                     # API Testing
```

### System Utilities & Tools
```yaml
tools:
  winget:
    - Microsoft.PowerToys         # PowerToys
    - 9N0DX20HK701                # Windows Terminal

  choco:
    - 7zip.install                # 7-Zip
    - sysinternals                # Sysinternals Suite
    - everything                  # Everything Search
    - cpu-z                       # CPU-Z
```

### Gaming Setup
```yaml
gaming:
  winget:
    - Valve.Steam                 # Steam (official)
    - EpicGames.EpicGamesLauncher # Epic Games

  choco:
    - discord                     # Discord
    - obs-studio                  # OBS Studio
    - msi-afterburner             # MSI Afterburner
```

---

## 🔄 Package Migration Detection

The script intelligently detects when you switch a package between managers and offers automatic migration.

### How It Works

1. **Detection Phase**
   - Script queries both `choco list` and `winget list`
   - Compares installed packages with `packages.yaml` configuration
   - Identifies packages installed via different manager

2. **Migration Prompt**
   ```
   ⚠️  Package 'telegram' is installed via Chocolatey
       but configured for Winget in packages.yaml
   
   Would you like to:
   1. Uninstall from Chocolatey
   2. Reinstall via Winget
   
   [Y/N]?
   ```

3. **Automatic Migration**
   - Uninstalls from old manager
   - Removes old database entry
   - Installs via new manager
   - Updates database with correct manager prefix

### Migration Example

**Before:**
```yaml
social:
  choco:
    - telegram  # Installed via Chocolatey
```

**After changing config:**
```yaml
social:
  winget:
    - Telegram.TelegramDesktop  # Want Winget version
  choco:
    # telegram removed from here
```

**Next run:**
- Script detects Telegram installed via Chocolatey
- Offers to uninstall Chocolatey version
- Installs Winget version
- Updates tracking database: `choco:telegram` → `winget:Telegram.TelegramDesktop`

### Database Tracking

The script tracks installations in `installed-packages.json`:

```json
{
  "choco:googlechrome": "123.0.6312.106",
  "winget:9NKSQGP7F2NH": "2.2450.6.0",
  "winget:Telegram.TelegramDesktop": "5.2.3",
  "choco:vscode": "1.87.0"
}
```

Manager prefix (`choco:` or `winget:`) ensures accurate tracking.

---

## 💡 Tips & Best Practices

1. **Inline Comments**: Use `#` for package descriptions
   ```yaml
   social:
     winget:
       - 9NKSQGP7F2NH  # WhatsApp (Microsoft Store)
       - Telegram.TelegramDesktop  # Telegram Desktop
   ```

2. **Organization**: Group related packages with section comments
   ```yaml
   developer:
     choco:
       # IDEs & Editors
       - vscode
       - sublimetext3
       
       # Version Control
       - git.install
       - github-desktop
       
       # Development Tools
       - nodejs
       - python
   ```

3. **Optional Packages**: Comment out packages you might want later
   ```yaml
   gaming:
     choco:
       - steam
       - discord
       # - obs-studio      # Uncomment if needed for streaming
       # - msi-afterburner # Uncomment for GPU overclocking
   ```

4. **Backup Configuration**: Keep a copy before major changes
   ```powershell
   Copy-Item packages\packages.yaml packages\packages.yaml.backup
   ```

5. **Test Changes**: Add one package at a time to verify
   ```yaml
   developer:
     choco:
       - vscode
       - nodejs  # Test this first before adding more
   ```

6. **Use .install Suffix**: For Chocolatey packages, prefer `.install` versions
   ```yaml
   basic:
     choco:
       - 7zip.install       # ✅ Better - system-wide installation
       # - 7zip             # ❌ Portable version
       - git.install        # ✅ Preferred
   ```

7. **Prefer Winget for Store Apps**: Microsoft Store apps update automatically
   ```yaml
   social:
     winget:
       - 9NKSQGP7F2NH              # WhatsApp - auto-updates via Store
       - Microsoft.WindowsTerminal # Terminal - auto-updates
   ```

8. **Check Both Managers**: Before adding, check which has the package
   ```powershell
   # Check Winget first
   winget search "Visual Studio Code"
   
   # Then check Chocolatey
   choco search vscode
   ```

---

## 🔧 Advanced Features

### Upgrade All Packages

The script includes an "Upgrade All" option (menu option 9):

```
🔄 Checking for outdated packages...

Outdated Packages:
  googlechrome: 122.0.6261.112 → 123.0.6312.106
  vscode: 1.86.2 → 1.87.0
  nodejs: 20.11.1 → 20.12.0

Total: 3 packages need updates

Proceed with upgrade? [Y/N]:
```

**Features:**
- ✅ Uses `choco outdated --limit-output`
- ✅ Shows current vs available versions
- ✅ Confirms before upgrading
- ✅ Upgrades all at once with `choco upgrade all -y`
- ✅ Updates tracking database automatically

### Installation History

View all installations with timestamps (menu option 10):

```
📋 INSTALLATION HISTORY

2025-10-25 14:30:15
  Profile: Developer
  Packages: vscode, git.install, docker-desktop (3 total)
  Duration: 5m 23s

2025-10-24 10:15:42
  Profile: Basic, PowerShell
  Packages: googlechrome, 7zip.install, oh-my-posh (8 total)
  Duration: 3m 47s
```

### Custom Package Selection

Choose specific packages without a profile (menu option 7):

```
Enter package names (comma-separated):
> git.install, vscode, docker-desktop, postman

Installing custom package selection...
  ✓ git.install
  ✓ vscode
  ✓ docker-desktop
  ✓ postman

Complete! 4 packages installed.
```

---

## 🐛 Troubleshooting

### Package Not Found

**Winget:**
```powershell
# Verify package exists
winget search <package-name>

# Check exact ID
winget show <Package.ID>
```

**Chocolatey:**
```powershell
# Verify package exists
choco search <package-name>

# View package details
choco info <package-name>
```

### Installation Fails

1. **Check internet connection**
2. **Run as Administrator**
3. **Disable antivirus temporarily**
4. **Check package name spelling**
5. **Try manual installation:**
   ```powershell
   # Winget
   winget install --id <Package.ID>
   
   # Chocolatey
   choco install <package-name> -y
   ```

### Migration Issues

If migration detection doesn't work:

1. **Manually check installed:**
   ```powershell
   choco list --local-only | Select-String "telegram"
   winget list telegram
   ```

2. **Force database update:**
   - Delete `installed-packages.json`
   - Re-run the script to rebuild database

3. **Manual cleanup:**
   ```powershell
   # Uninstall from old manager
   choco uninstall telegram -y
   
   # Install via new manager
   winget install Telegram.TelegramDesktop
   ```

---

## 📖 Quick Reference

### Common Commands

| Task | Chocolatey | Winget |
|------|-----------|--------|
| **Search** | `choco search <name>` | `winget search <name>` |
| **Install** | `choco install <pkg> -y` | `winget install --id <ID>` |
| **Uninstall** | `choco uninstall <pkg> -y` | `winget uninstall <ID>` |
| **List Installed** | `choco list --local-only` | `winget list` |
| **Upgrade One** | `choco upgrade <pkg> -y` | `winget upgrade <ID>` |
| **Upgrade All** | `choco upgrade all -y` | `winget upgrade --all` |
| **Info** | `choco info <pkg>` | `winget show <ID>` |

### Script Menu Options

| Option | Description |
|--------|-------------|
| **1-6** | Install predefined profiles |
| **7** | Custom package selection |
| **8** | Configure PowerShell profile |
| **9** | Upgrade all Chocolatey packages |
| **10** | View installation history |
| **11** | Exit |

---

## 🎓 Learn More

- **Chocolatey Documentation**: https://docs.chocolatey.org/
- **Winget Documentation**: https://learn.microsoft.com/windows/package-manager/
- **PowerShell Gallery**: https://www.powershellgallery.com/
- **Microsoft Store**: https://www.microsoft.com/store

---

## 📝 Summary

This guide covered:

✅ Unified YAML configuration structure  
✅ Auto-installation of both package managers  
✅ Finding package IDs for both managers  
✅ When to use Chocolatey vs Winget  
✅ Package migration detection system  
✅ Real-world configuration examples  
✅ Best practices and tips  
✅ Advanced features (upgrade all, history)  
✅ Troubleshooting common issues  

**Next Steps:**
1. Edit `packages.yaml` to customize your profiles
2. Run `install.ps1` as Administrator
3. Select your desired profiles
4. Let the script handle the rest!

Happy installing! 🚀


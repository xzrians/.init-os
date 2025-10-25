<div align="center">

# 🚀 Windows Installation Script

**Automated Windows software installation with style and simplicity**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Chocolatey](https://img.shields.io/badge/Chocolatey-Powered-red.svg)](https://chocolatey.org/)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-blue.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

*Set up your Windows PC in minutes with pre-configured installation profiles*

[Features](#-features) • [Quick Start](#-quick-start) • [Profiles](#-installation-profiles) • [Customization](#-customization)

---

</div>

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎯 **Multiple Profiles**
- 📦 **Basic** - Essential everyday apps
- 💻 **Developer** - Complete dev environment
- 🎮 **Gaming** - Gaming platforms & tools
- � **Social** - Messaging & communication
- 🔧 **Tools** - System utilities & power tools
- �🐚 **PowerShell** - Terminal & shell setup
- ⚙️ **Custom** - Build your own

</td>
<td width="50%">

### 🛠️ **Smart Features**
- ✅ Auto-install Chocolatey & Winget
- 🔄 Dual package manager support
- 📦 Unified YAML configuration
- 🔁 Package migration detection
- 🎨 Beautiful CLI interface
- 📊 Installation progress tracking
- 🔄 Multi-profile selection
- ⬆️ Upgrade all packages feature

</td>
</tr>
</table>

---

## 🚀 Quick Start

### Prerequisites
- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges

### Installation

```powershell
# 1. Clone the repository
git clone https://github.com/xzrians/.init-os.git
cd .init-os/init-script

# 2. Run the installer (as Administrator)
.\install.ps1

# 3. Select your profile and let it do the magic! ✨
```

> **💡 Tip:** You can select multiple profiles at once! Example: `1,2,4` for Basic + Developer + PowerShell

---

## 📦 Installation Profiles

### � Basic Profile

Perfect for everyday users who need essential applications.

<details>
<summary><b>📋 View Packages</b></summary>

| Category | Applications |
|----------|-------------|
| 🌐 **Browsers** | Google Chrome |
| 🎵 **Media** | VLC, Spotify |
| 🔧 **Utilities** | 7-Zip, Notepad++, WizTree, PowerToys, Adobe Reader |
| 🔒 **Security** | Bitwarden |
| ☁️ **Cloud Storage** | Google Drive (optional), Dropbox (optional) |

</details>

### 💻 Developer Profile

Complete development environment for programmers.

<details>
<summary><b>📋 View Packages</b></summary>

| Category | Tools |
|----------|-------|
| 🖥️ **IDEs & Editors** | VS Code |
| 🔀 **Version Control** | Git, GitHub Desktop, GitKraken |
| � **Containers** | Docker Desktop |
| � **Optional** | Node.js, Python, Go, PostgreSQL, MongoDB, Postman |

</details>

### 🎮 Gaming Profile

Everything you need for an optimal gaming experience.

<details>
<summary><b>📋 View Packages</b></summary>

| Category | Applications |
|----------|-------------|
| 🎯 **Platforms** | Steam, Epic Games, Origin |
| 💬 **Communication** | Discord |
| � **Streaming** | OBS Studio |
| 🎮 **Optional** | GOG Galaxy, EA App, Streamlabs OBS, DS4Windows |

</details>

### 💬 Social Profile

Messaging and communication apps.

<details>
<summary><b>📋 View Packages</b></summary>

| Category | Applications |
|----------|-------------|
| 💬 **Messaging** | WhatsApp (Winget), Telegram (Winget), Discord |
| 🎥 **Optional** | Slack, Microsoft Teams, Zoom, Skype, Signal |

**Note:** Uses Winget for Microsoft Store integration (WhatsApp, Telegram)

</details>

### 🔧 Tools Profile

System utilities and power user tools.

<details>
<summary><b>📋 View Packages</b></summary>

| Category | Applications |
|----------|-------------|
| 📦 **Package Managers** | WingetUI (Universal GUI) |
| � **System Monitoring** | CPU-Z, GPU-Z |
| 📁 **Optional** | Sysinternals Suite, Everything, Total Commander |
| � **Network Tools** | Wireshark, PuTTY, WinSCP, Nmap (optional) |
| 🖥️ **Remote Access** | AnyDesk, TeamViewer, RustDesk (optional) |

</details>

### 🐚 PowerShell Profile

Modern terminal setup with beautiful theming.

<details>
<summary><b>📋 View Packages</b></summary>

| Category | Tools |
|----------|-------|
| 🖥️ **Terminal** | Windows Terminal, PowerShell Core |
| 🎨 **Theming** | Oh My Posh, Nerd Fonts (Cascadia Code) |
| 📦 **Modules** | PSReadLine, Terminal-Icons, posh-git |

**Includes:**
- ✅ Configured PowerShell profile with aliases
- ✅ Windows Terminal setup (PowerShell 7 as default)
- ✅ Custom functions and shortcuts
- ✅ Beautiful prompt with Oh My Posh

</details>

---

## 🎨 Menu Interface

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║          Windows Installation Script Manager              ║
║          Powered by Chocolatey & Winget                    ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

Select Installation Profile(s):

  1. Basic            - Essential applications for everyday use
  2. Developer        - Programming tools, IDEs, and development environment
  3. Gaming           - Gaming platforms and related tools
  4. Social           - Messaging and communication apps
  5. Tools            - System utilities and power user tools
  6. PowerShell       - PowerShell tools and terminal setup
  7. Custom           - Choose packages manually
  8. Configure PowerShell Profile - Setup Oh-My-Posh, aliases, and functions
  9. Upgrade All      - Update all installed Chocolatey packages
  10. View History    - Show installation history
  11. Exit            - Exit the installer

TIP: You can select multiple options (e.g., 1,2,6 for Basic + Developer + PowerShell)
```

---

## 🛠️ Customization

### Unified Package Configuration

All packages are now in a single YAML file for easier management!

```
📁 packages/
├── 📄 packages.yaml      # 🌟 ALL profiles in one file!
├── 📄 modules.yaml       # PowerShell modules
├── 📄 profile-config.ps1 # PowerShell profile customization
├── 📄 template.yaml      # Template for reference
└── 📄 README.md          # Package management guide
```

### Structure of packages.yaml

```yaml
---
# All profiles in one file!
basic:
  winget:
    # - Google.Chrome
  choco:
    - googlechrome
    - vlc
    - 7zip.install

developer:
  winget:
    # - Microsoft.VisualStudioCode
  choco:
    - vscode
    - git.install
    - docker-desktop

gaming:
  winget:
    # - Valve.Steam
  choco:
    - steam
    - discord
    - obs-studio

social:
  winget:
    - 9NKSQGP7F2NH              # WhatsApp (Microsoft Store)
    - Telegram.TelegramDesktop  # Telegram
  choco:
    - discord

tools:
  winget:
    # - Microsoft.PowerToys
  choco:
    - wingetui  # Universal package manager GUI
    - cpu-z
    - gpu-z

powershell:
  winget:
    # - Microsoft.WindowsTerminal
  choco:
    - microsoft-windows-terminal
    - powershell-core
    - oh-my-posh
```

### Adding a Package

Simply edit `packages.yaml`:

```yaml
developer:
  choco:
    - vscode
    - git.install
    - nodejs       # <-- Just add this line!
```

### Removing a Package

Comment it out or delete the line:

```yaml
developer:
  choco:
    - vscode
    # - git.install     # Won't be installed
    - docker-desktop
```

### Finding Package IDs

**For Winget:**
```powershell
winget search telegram
# Example: Telegram.TelegramDesktop
```

**For Chocolatey:**
```powershell
choco search chrome
# Or visit: https://community.chocolatey.org/packages
```

### Dual Package Manager Support

The script supports both **Chocolatey** and **Winget**:
- ✅ **Chocolatey**: Default, mature ecosystem, most packages
- ✅ **Winget**: Microsoft Store integration, auto-updates for certain apps
- ✅ **Auto-detection**: Script automatically uses the right manager
- ✅ **Migration**: Detects if package switched managers, offers to migrate

**Example: WhatsApp from Microsoft Store**
```yaml
social:
  winget:
    - 9NKSQGP7F2NH  # Microsoft Store Product ID
```

---

## 📖 Usage Examples

### Single Profile Installation
```powershell
.\install.ps1
# Select: 2 (Developer)
```

### Multi-Profile Installation
```powershell
.\install.ps1
# Select: 1,2,6 (Basic + Developer + PowerShell)
```

### Upgrade All Packages
```powershell
.\install.ps1
# Select: 9 (Upgrade All)
# Script will check for updates and upgrade all Chocolatey packages
```

### Custom Package Installation
```powershell
.\install.ps1
# Select: 5 (Custom)
# Enter: git, vscode, docker-desktop, postman
```

---

## 🔧 Useful Commands

### Package Management
```powershell
# Search for Chocolatey packages
choco search <package-name>

# Search for Winget packages
winget search <app-name>

# List installed Chocolatey packages
choco list --local-only

# List installed Winget packages
winget list

# Update all Chocolatey packages
choco upgrade all -y

# Upgrade a specific Winget package
winget upgrade <Package.ID>

# Uninstall a Chocolatey package
choco uninstall <package-name> -y

# Uninstall a Winget package
winget uninstall <Package.ID>
```

### Script Features
```powershell
# Multi-selection installation
.\install.ps1
# Enter: 1,2,6 (Install multiple profiles)

# Upgrade all packages via menu
.\install.ps1
# Select option 9 (Upgrade All)

# View installation history
.\install.ps1
# Select option 10 (View History)

# First run auto-installs both package managers
# - Chocolatey (if not installed)
# - Winget/App Installer (via Microsoft Store if not installed)
```

---

## 🐛 Troubleshooting

<details>
<summary><b>Script Won't Run</b></summary>

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
</details>

<details>
<summary><b>Chocolatey Installation Fails</b></summary>

**Checklist:**
- ✅ Check internet connection
- ✅ Disable antivirus temporarily
- ✅ Run as Administrator
- ✅ Visit [Chocolatey Docs](https://chocolatey.org/install)
</details>

<details>
<summary><b>Package Installation Fails</b></summary>

**Troubleshooting:**
1. Check if package exists: `choco search <package-name>`
2. Try manual installation: `choco install <package-name> -y`
3. Check [Chocolatey Packages](https://community.chocolatey.org/packages)
</details>

---

## 📂 Project Structure

```
.init-os/
├── 📁 init-script/
│   ├── 📄 install.ps1                  # Main installation script
│   ├── � installed-packages.json      # Installation tracking database
│   └── � packages/
│       ├── 📄 packages.yaml            # 🌟 Unified package configuration
│       ├── 📄 modules.yaml             # PowerShell modules list
│       ├── 📄 profile-config.ps1       # PowerShell profile config
│       ├── 📄 template.yaml            # YAML template reference
│       ├── 📄 README.md                # Package management guide
│       └── 📄 PACKAGE_MANAGER_GUIDE.md # Dual package manager guide
├── � win-installation/
├── �📄 .gitignore                       # Git ignore rules
├── 📄 LICENSE                          # MIT License
└── 📄 README.md                        # This file
```

## 🎯 Key Features Explained

### 🔄 Package Migration Detection
If you change a package from Chocolatey to Winget (or vice versa) in `packages.yaml`, the script will:
1. Detect the package is installed via the old manager
2. Prompt you to uninstall from old manager
3. Reinstall via the new manager
4. Update the database with the correct manager

### ⬆️ Upgrade All Packages
Select option 9 to:
- Check for outdated Chocolatey packages
- View current vs available versions
- Confirm and upgrade all at once
- Update installation database

### 📦 Unified Configuration
All 6 profiles in one `packages.yaml` file:
- Easier to manage and search
- Better overview of all packages
- Single source of truth
- 83% reduction in configuration files

---

## 🤝 Contributing

Contributions are welcome! Feel free to:

- 🐛 Report bugs
- 💡 Suggest new features
- 📦 Add new package profiles
- 📝 Improve documentation

---

## 📝 License

This project is free to use and modify for personal use.

---

## 👤 Author

**Arif Johar**

- GitHub: [@xzrians](https://github.com/xzrians)

---

<div align="center">

### ⭐ Star this repo if it helped you set up your Windows PC faster!

Made with ❤️ and ☕ by Arif Johar

</div>

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
- � **Basic** - Essential everyday apps
- 💻 **Developer** - Complete dev environment
- 🎮 **Gaming** - Gaming platforms & tools
- 🐚 **PowerShell** - Terminal & shell setup
- ⚙️ **Custom** - Build your own

</td>
<td width="50%">

### 🛠️ **Smart Features**
- ✅ Automatic Chocolatey installation
- 🎨 Beautiful CLI interface
- 📊 Installation progress tracking
- 💾 Package list management
- 🔄 Multi-profile selection support

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

### 🔧 Basic Profile

Perfect for everyday users who need essential applications.

<details>
<summary><b>📋 View Packages</b></summary>

| Category | Applications |
|----------|-------------|
| 🌐 **Browsers** | Google Chrome, Firefox |
| 💬 **Communication** | Discord, Zoom |
| 🎵 **Media** | VLC, Spotify |
| 🔧 **Utilities** | 7-Zip, Notepad++, WizTree, PowerToys |
| 🔒 **Security** | Bitwarden |

</details>

### 💻 Developer Profile

Complete development environment for programmers.

<details>
<summary><b>📋 View Packages</b></summary>

| Category | Tools |
|----------|-------|
| 🖥️ **IDEs & Editors** | VS Code, PyCharm, IntelliJ IDEA, Android Studio |
| 🔀 **Version Control** | Git, GitHub Desktop, GitKraken |
| 🐍 **Languages** | Node.js, Python, .NET SDK, Java JDK 11 |
| 🗄️ **Databases** | PostgreSQL, MongoDB, Redis |
| 🐳 **Containers** | Docker Desktop, VirtualBox |
| 🧪 **API Tools** | Postman, Insomnia |
| 🔨 **Build Tools** | Maven, Gradle |

</details>

### 🎮 Gaming Profile

Everything you need for an optimal gaming experience.

<details>
<summary><b>📋 View Packages</b></summary>

| Category | Applications |
|----------|-------------|
| 🎯 **Platforms** | Steam, Epic Games, Origin, GOG Galaxy, Battle.net |
| 📹 **Streaming** | OBS Studio |
| ⚡ **Optimization** | MSI Afterburner, NVIDIA App |
| 🎮 **Controllers** | DS4Windows |

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
║                  Powered by Chocolatey                     ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

Select Installation Profile(s):

  1. Basic            - Essential applications for everyday use
  2. Developer        - Programming tools, IDEs, and development environment
  3. Gaming           - Gaming platforms and related tools
  4. PowerShell       - PowerShell tools and terminal setup
  5. Custom           - Choose packages manually
  6. Configure PowerShell Profile - Setup Oh-My-Posh, aliases, and functions
  7. Exit             - Exit the installer

TIP: You can select multiple options (e.g., 1,3 for Basic + Gaming)
```

---

## 🛠️ Customization

### Easy Package Management

All packages are stored in structured YAML files - no script editing needed!

```
📁 packages/
├── 📄 basic.yaml         # Edit to add/remove basic apps
├── 📄 developer.yaml     # Edit to add/remove dev tools
├── 📄 gaming.yaml        # Edit to add/remove games
├── 📄 powershell.yaml    # Edit to add/remove shell tools
├── 📄 modules.yaml       # Edit to add/remove PS modules
└── 📄 profile-config.ps1 # Customize PowerShell profile
```

### Adding a Package

Simply edit the appropriate `.yaml` file:

```yaml
# packages/basic.yaml
packages:
  browsers:
    - googlechrome
    - firefox
    - brave          # <-- Just add this line!
```

### Removing a Package

Comment it out or delete the line:

```yaml
packages:
  browsers:
    # - googlechrome     # Won't be installed
    - firefox
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
# Select: 1,2,4 (Basic + Developer + PowerShell)
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
# Search for packages
choco search <package-name>

# List installed packages
choco list --local-only

# Update all packages
choco upgrade all -y

# Uninstall a package
choco uninstall <package-name> -y
```

### Script Options
```powershell
# Run with multi-selection
.\install.ps1
# Enter: 1,2,4

# Update existing installations
choco upgrade all -y
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
│   ├── 📄 install.ps1              # Main installation script
│   └── 📁 packages/
│       ├── 📄 basic.yaml           # Basic packages list
│       ├── 📄 developer.yaml       # Developer packages list
│       ├── 📄 gaming.yaml          # Gaming packages list
│       ├── 📄 powershell.yaml      # PowerShell packages list
│       ├── 📄 modules.yaml         # PowerShell modules list
│       ├── 📄 profile-config.ps1   # PowerShell profile config
│       └── 📄 README.md            # Package management guide
├── 📄 .gitignore                   # Git ignore rules
├── 📄 LICENSE                      # MIT License
└── 📄 README.md                    # This file
```

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

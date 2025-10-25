# Package Configuration

This directory contains the unified package configuration file that the installation script reads from. You can easily add or remove packages without modifying the main script.

## 📄 Main Files

- **packages.yaml** - Unified configuration containing all profiles (basic, developer, gaming, social, tools, powershell)
- **modules.yaml** - PowerShell modules from PowerShell Gallery
- **template.yaml** - Template showing the unified YAML structure
- **profile-config.ps1** - PowerShell profile configuration (aliases, functions, Oh My Posh)
- **PACKAGE_MANAGER_GUIDE.md** - Complete guide for using Chocolatey and Winget

## 📋 Unified Structure (packages.yaml)

All profiles are now in one file for easier management:

```yaml
---
# Profile 1
basic:
  winget:
    - Package.ID
  choco:
    - packagename

# Profile 2
developer:
  winget:
    - Microsoft.VisualStudioCode
  choco:
    - vscode
    - git.install

# Profile 3
gaming:
  winget:
    - Valve.Steam
  choco:
    - steam
    - discord
```

## ✏️ How to Add/Remove Packages

### Adding a Package

1. Open `packages.yaml`
2. Find the profile section (basic, developer, gaming, etc.)
3. Add under `winget:` or `choco:` section:

```yaml
developer:
  winget:
    - Microsoft.VisualStudioCode
    - Git.Git                      # <-- Add new winget package
  
  choco:
    - vscode
    - git.install
    - nodejs                       # <-- Add new choco package
```

### Removing a Package

Either delete the line or comment it out with `#`:

```yaml
developer:
  choco:
    - vscode
    # - git.install                # <-- Commented out, won't install
    - docker-desktop
```

### Finding Package IDs

**For Winget:**
```powershell
winget search <app-name>
# Example: winget search telegram
```

**For Chocolatey:**
```powershell
choco search <app-name>
# Or visit: https://community.chocolatey.org/packages
```

### PowerShell Modules (modules.yaml)

**Add a Module:**

Add the module name from PowerShell Gallery:

```yaml
# modules.yaml
modules:
  code_editing_and_navigation:
    - PSReadLine
    - Terminal-Icons
    - posh-git
    - Az              # <-- Add Azure module
```

**Remove a Module:**

Comment it out or delete the line:

```yaml
modules:
  code_editing_and_navigation:
    # - PSReadLine
    - Terminal-Icons
    # - Az            # <-- Won't be installed
```

### Add Comments

Use `#` to add comments or organize your packages:

```
# Web Browsers
googlechrome
firefox

# Communication Tools
discord
zoom
```

## 🔍 Finding Package Names

### For Chocolatey Packages

To find the correct package name:

1. Visit [Chocolatey Packages](https://community.chocolatey.org/packages)
2. Search for your desired application
3. Use the package ID shown on the package page

Or use the command:
```powershell
choco search <application-name>
```

### For PowerShell Modules

To find PowerShell modules:

1. Visit [PowerShell Gallery](https://www.powershellgallery.com/)
2. Search for the module
3. Use the exact module name

Or use the command:
```powershell
Find-Module <module-name>
```

## 📝 File Format Rules

- YAML format with proper indentation (2 spaces)
- Lines starting with `#` are comments (ignored)
- Empty lines are ignored
- Packages are listed under categories with `- packagename` format

## 💡 Examples

### Valid Chocolatey Entries (basic.yaml, developer.yaml, gaming.yaml)
```yaml
packages:
  ides_and_editors:
    - vscode
    - git.install
    - 7zip.install
    - nodejs-lts
```

### Valid PowerShell Module Entries (modules.yaml)
```yaml
modules:
  code_editing_and_navigation:
    - PSReadLine
    - Terminal-Icons
    - posh-git
  
  cloud_tools:
    - Az
    - ImportExcel
```

### Also Valid (with comments)
```yaml
packages:
  ides_and_editors:
    - vscode              # Visual Studio Code
    # - pycharm           # Commented out - won't install
  
  version_control:
    - git.install         # Git for Windows
```

## 🎯 Profile Behavior

The unified `packages.yaml` contains all profiles in sections:

- **Basic Profile** → Installs packages from `basic:` section
- **Developer Profile** → Installs `basic:` + `developer:` sections
- **Gaming Profile** → Installs `basic:` + `gaming:` sections
- **Social Profile** → Installs `basic:` + `social:` sections
- **Tools Profile** → Installs `basic:` + `tools:` sections
- **PowerShell Profile** → Installs `basic:` + `powershell:` sections
- **PowerShell Config** → Installs modules from `modules.yaml` + applies `profile-config.ps1`

**Multi-Selection:**
When combining profiles (e.g., `1,2,6` for Basic + Developer + PowerShell), duplicates are automatically removed.

**Note:** Most profiles automatically include the `basic:` section to ensure essential tools are installed.

## 🚀 Quick Tips

1. **Backup before editing** - Copy `packages.yaml` first if you want to keep the original
2. **Use .install versions** when available (e.g., `git.install` instead of `git`)
3. **Test with one package** first before adding many
4. **Keep comments** to remember why you added specific packages
5. **PowerShell modules** are installed from PowerShell Gallery, not Chocolatey
6. **Profile customization** - Edit `profile-config.ps1` to change aliases, functions, and Oh My Posh theme
7. **Winget for Store apps** - Use Winget for Microsoft Store apps like WhatsApp (9NKSQGP7F2NH)
8. **Migration detection** - The script auto-detects when you switch package managers

## 📋 Example: Adding Packages

### Add Development Tools to Developer Profile

Edit `packages.yaml`:
```yaml
developer:
  choco:
    - vscode
    - git.install
    - nodejs       # <-- Add Node.js
    - python       # <-- Add Python
```

### Add WhatsApp to Social Profile (via Winget)

Edit `packages.yaml`:
```yaml
social:
  winget:
    - 9NKSQGP7F2NH              # WhatsApp (already added)
    - Telegram.TelegramDesktop  # Telegram (already added)
    - Zoom.Zoom                 # <-- Add Zoom
```

### Add Azure PowerShell Module

Edit `modules.yaml`:
```yaml
modules:
  additional_modules:
    - PSScriptAnalyzer
    - PowerShellGet
    - Az              # <-- Add Azure module
    - ImportExcel     # <-- Add Excel module
```

### Customize PowerShell Profile

Edit `profile-config.ps1`:
```powershell
# Change Oh My Posh theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\atomic.omp.json" | Invoke-Expression

# Add your own alias
Set-Alias -Name code -Value "C:\Program Files\Microsoft VS Code\Code.exe"
Set-Alias -Name g -Value git
```

## 🔄 Package Manager Migration

If you change a package from Chocolatey to Winget (or vice versa), the script will:

1. **Detect** the package is already installed via the old manager
2. **Prompt** you to confirm uninstallation from old manager
3. **Uninstall** from the old manager
4. **Reinstall** via the new manager
5. **Update** the tracking database

**Example Migration:**
```yaml
# Before (Chocolatey)
social:
  choco:
    - telegram

# After (Winget - Microsoft Store version)
social:
  winget:
    - Telegram.TelegramDesktop
  choco:
    # - telegram  # Removed from here
```

On next installation, the script will detect Telegram is installed via Chocolatey but should be Winget, and offer to migrate it.

That's it! Next time you run the script, these will be installed or applied.

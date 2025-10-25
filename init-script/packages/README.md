# Package List Files

This directory contains package list files that the installation script reads from. You can easily add or remove packages without modifying the main script.

## 📄 Package Files

- **basic.yaml** - Essential everyday applications
- **developer.yaml** - Development tools and environments
- **gaming.yaml** - Gaming platforms and tools
- **powershell.yaml** - PowerShell development tools and terminal setup
- **modules.yaml** - PowerShell modules from PowerShell Gallery
- **profile-config.ps1** - PowerShell profile configuration (aliases, functions, Oh My Posh)

## ✏️ How to Add/Remove Packages

### Chocolatey Packages (basic.yaml, developer.yaml, gaming.yaml, powershell.yaml)

**Add a Package:**

Simply add the package name to the appropriate category in YAML format:

```yaml
# basic.yaml
packages:
  browsers:
    - googlechrome
    - firefox
    - brave          # <-- Add new package here
```

**Remove a Package:**

Either delete the line or comment it out with `#`:

```yaml
packages:
  browsers:
    # - googlechrome     # <-- Commented out, won't be installed
    - firefox
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

- **Basic Profile** → Installs only `basic.yaml`
- **Developer Profile** → Installs `basic.yaml` + `developer.yaml`
- **Gaming Profile** → Installs `basic.yaml` + `gaming.yaml`
- **PowerShell Profile** → Installs `basic.yaml` + `powershell.yaml`
- **PowerShell Profile Config** → Installs modules from `modules.yaml` + applies `profile-config.ps1`

When combining profiles (e.g., `1,2,4`), duplicates are automatically removed.

## 🚀 Quick Tips

1. **Backup before editing** - Copy the file first if you want to keep the original
2. **Use .install versions** when available (e.g., `git.install` instead of `git`)
3. **Test with one package** first before adding many
4. **Keep comments** to remember why you added specific packages
5. **PowerShell modules** are installed from PowerShell Gallery, not Chocolatey
6. **Profile customization** - Edit `profile-config.ps1` to change aliases, functions, and Oh My Posh theme

## 📋 Example: Adding Packages

### Add Android Development Tools

Edit `developer.yaml`:
```yaml
packages:
  mobile_development:
    - androidstudio
    - android-sdk
    - flutter
```

### Add Azure PowerShell Module

Edit `modules.yaml`:
```yaml
modules:
  cloud_modules:
    - Az
    - AWSPowerShell.NetCore
```

### Customize PowerShell Profile

Edit `profile-config.ps1`:
```powershell
# Change Oh My Posh theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\atomic.omp.json" | Invoke-Expression

# Add your own alias
Set-Alias -Name code -Value "C:\Program Files\Microsoft VS Code\Code.exe"
```

That's it! Next time you run the script, these will be installed or applied.

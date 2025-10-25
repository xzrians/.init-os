# Package List Files

This directory contains package list files that the installation script reads from. You can easily add or remove packages without modifying the main script.

## 📄 Package Files

- **basic.txt** - Essential everyday applications
- **developer.txt** - Development tools and environments
- **gaming.txt** - Gaming platforms and tools
- **powershell.txt** - PowerShell development tools and terminal setup
- **modules.txt** - PowerShell modules from PowerShell Gallery
- **profile-config.ps1** - PowerShell profile configuration (aliases, functions, Oh My Posh)
- **windows-terminal-settings.json** - Windows Terminal configuration (default profile, font, theme)

## ✏️ How to Add/Remove Packages

### Chocolatey Packages (basic.txt, developer.txt, gaming.txt)

**Add a Package:**

Simply add the package name on a new line in the appropriate file:

```
# basic.txt
googlechrome
firefox
brave          # <-- Add new package here
```

**Remove a Package:**

Either delete the line or comment it out with `#`:

```
# googlechrome     # <-- Commented out, won't be installed
firefox
```

### PowerShell Modules (modules.txt)

**Add a Module:**

Add the module name from PowerShell Gallery:

```
# modules.txt
PSReadLine
Terminal-Icons
posh-git
Az              # <-- Add Azure module
```

**Remove a Module:**

Comment it out or delete the line:

```
# PSReadLine
Terminal-Icons
# Az            # <-- Won't be installed
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

- One package per line
- Lines starting with `#` are comments (ignored)
- Empty lines are ignored
- Whitespace is automatically trimmed

## 💡 Examples

### Valid Chocolatey Entries (basic.txt, developer.txt, gaming.txt)
```
vscode
git.install
7zip.install
nodejs-lts
```

### Valid PowerShell Module Entries (modules.txt)
```
PSReadLine
Terminal-Icons
posh-git
Az
ImportExcel
```

### Also Valid (with comments)
```
# IDEs
vscode              # Visual Studio Code
# pycharm           # Commented out - won't install

# Version Control
git.install         # Git for Windows
```

## 🎯 Profile Behavior

- **Basic Profile** → Installs only `basic.txt`
- **Developer Profile** → Installs `basic.txt` + `developer.txt`
- **Gaming Profile** → Installs `basic.txt` + `gaming.txt`
- **PowerShell Profile** → Installs `basic.txt` + `powershell.txt`
- **PowerShell Profile Config** → Installs modules from `modules.txt` + applies `profile-config.ps1`

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

Edit `developer.txt`:
```
# Mobile Development
androidstudio
android-sdk
flutter
```

### Add Azure PowerShell Module

Edit `modules.txt`:
```
# Cloud Modules
Az
AWSPowerShell.NetCore
```

### Customize PowerShell Profile

Edit `profile-config.ps1`:
```powershell
# Change Oh My Posh theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\atomic.omp.json" | Invoke-Expression

# Add your own alias
Set-Alias -Name code -Value "C:\Program Files\Microsoft VS Code\Code.exe"
```

### Customize Windows Terminal

Edit `windows-terminal-settings.json`:
```json
{
    "defaultProfile": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
    "profiles": {
        "defaults": {
            "font": {
                "face": "CaskaydiaCove Nerd Font",
                "size": 12
            }
        }
    }
}
```

**Common customizations:**
- Change font size (default: 11)
- Change color scheme (default: "One Half Dark")
- Adjust opacity (default: 95)
- Change default profile GUID

That's it! Next time you run the script, these will be installed or applied.

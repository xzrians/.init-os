# Windows Installation Script

Automated Windows software installation using Chocolatey package manager with different installation profiles.

## Features

- **Multiple Installation Profiles**:
  - 🔧 **Basic** - Essential applications for everyday use
  - 💻 **Developer** - Complete development environment setup
  - 🎮 **Gaming** - Gaming platforms and related tools
  - ⚙️ **Custom** - Manual package selection

- **Automated Package Management** via Chocolatey
- **Beautiful CLI Interface** with colored output
- **Error Handling** and installation summaries
- **Admin Privilege Checking**

## Prerequisites

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges

## Installation

### Quick Start

1. **Open PowerShell as Administrator**
   - Press `Win + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Navigate to the script directory**
   ```powershell
   cd "C:\Users\Arif Johar\repo\windows-installation\init-script"
   ```

3. **Run the installation script**
   ```powershell
   .\install.ps1
   ```

### Execution Policy

If you encounter execution policy errors, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Included Packages

### 📦 Basic Profile

**Browsers:**
- Google Chrome
- Firefox

**Communication:**
- Discord
- Zoom

**Media:**
- VLC Media Player
- Spotify

**Utilities:**
- 7-Zip
- Notepad++
- Adobe Reader
- WinDirStat

**Security:**
- Bitwarden

**Cloud Storage:**
- Dropbox
- Google Drive

### 💻 Developer Profile

Includes all Basic packages plus:

**IDEs & Editors:**
- Visual Studio Code
- PyCharm Community
- IntelliJ IDEA Community

**Version Control:**
- Git
- GitHub Desktop
- GitKraken

**Programming Languages:**
- Node.js LTS
- Python
- .NET SDK
- Java JDK 11

**Databases:**
- PostgreSQL
- MongoDB
- Redis

**Containers:**
- Docker Desktop
- VirtualBox

**API Tools:**
- Postman
- Insomnia

**Terminal:**
- Windows Terminal
- PowerShell Core

**Build Tools:**
- Maven
- Gradle

**Network Tools:**
- cURL
- wget
- Fiddler
- Wireshark

### 🎮 Gaming Profile

Includes all Basic packages plus:

**Gaming Platforms:**
- Steam
- Epic Games Launcher
- Origin
- GOG Galaxy
- Battle.net

**Recording & Streaming:**
- OBS Studio

**Optimization:**
- MSI Afterburner

**Controller Support:**
- DS4Windows

### ⚙️ Custom Installation

Select option 4 to manually specify packages. Enter package names separated by commas:

```
Packages: git, vscode, docker-desktop
```

Type `list` to open Chocolatey package search in your browser.

## Developer Package Categories

The `dev-package.ps1` file contains specialized package lists for different development stacks:

- **Frontend Development** - React, Vue, Angular tooling
- **Backend Development** - Server-side languages and databases
- **Full Stack** - Combined frontend and backend tools
- **DevOps & Cloud** - Container, orchestration, and cloud tools
- **Data Science & ML** - Python, R, Jupyter, and analytics tools
- **Mobile Development** - Android and cross-platform tools
- **Game Development** - Unity, Blender, and game dev tools
- **Database Development** - Database servers and management tools

## Usage Examples

### Installing Basic Profile
```powershell
.\install.ps1
# Select option 1
```

### Installing Developer Profile
```powershell
.\install.ps1
# Select option 2
```

### Custom Package Installation
```powershell
.\install.ps1
# Select option 4
# Enter: git, vscode, docker-desktop, postman
```

## Updating Packages

To update all installed Chocolatey packages:
```powershell
choco upgrade all -y
```

## Troubleshooting

### Script Won't Run
- Ensure you're running PowerShell as Administrator
- Check execution policy: `Get-ExecutionPolicy`
- Set appropriate policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Chocolatey Installation Fails
- Check internet connection
- Ensure antivirus isn't blocking the installation
- Visit [Chocolatey Installation Guide](https://chocolatey.org/install)

### Package Installation Fails
- Package might have been renamed or removed
- Check the package exists: Visit https://community.chocolatey.org/packages
- Try installing manually: `choco install <package-name> -y`

## Customization

### Adding New Packages

Edit `install.ps1` and modify the respective function:

```powershell
function Get-BasicPackages {
    return @(
        'googlechrome',
        'firefox',
        'your-new-package'  # Add your package here
    )
}
```

### Creating New Profiles

Add a new function in `install.ps1`:

```powershell
function Get-YourCustomProfile {
    return @(
        'package1',
        'package2',
        'package3'
    )
}
```

Then add it to the menu in the `Show-Menu` and switch statement.

## Useful Chocolatey Commands

```powershell
# Search for packages
choco search <package-name>

# List installed packages
choco list --local-only

# Uninstall a package
choco uninstall <package-name>

# Update a specific package
choco upgrade <package-name>

# Update all packages
choco upgrade all
```

## Contributing

Feel free to add more packages or create additional profiles based on your needs!

## License

Free to use and modify for personal use.

## Author

Arif Johar

---

**Note:** Always review packages before installation. Some packages may require additional configuration or licenses.

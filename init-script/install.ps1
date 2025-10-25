#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Installation Script with Chocolatey Package Manager
.DESCRIPTION
    Installs software packages for different profiles: Basic, Developer, or Gaming
.NOTES
    Author: Arif Johar
    Requires: PowerShell 5.1+ and Administrator privileges
#>

# Color scheme for output
$script:Colors = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'Cyan'
    Header = 'Magenta'
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = 'Info'
    )
    Write-Host $Message -ForegroundColor $script:Colors[$Type]
}

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor $script:Colors.Header
    Write-Host "║                                                            ║" -ForegroundColor $script:Colors.Header
    Write-Host "║          Windows Installation Script Manager              ║" -ForegroundColor $script:Colors.Header
    Write-Host "║                  Powered by Chocolatey                     ║" -ForegroundColor $script:Colors.Header
    Write-Host "║                                                            ║" -ForegroundColor $script:Colors.Header
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor $script:Colors.Header
    Write-Host ""
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Chocolatey {
    Write-ColorOutput "Checking for Chocolatey installation..." -Type Info
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-ColorOutput "✓ Chocolatey is already installed" -Type Success
        choco --version
    } else {
        Write-ColorOutput "Installing Chocolatey..." -Type Warning
        
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        
        try {
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-ColorOutput "✓ Chocolatey installed successfully!" -Type Success
            
            # Refresh environment variables
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } catch {
            Write-ColorOutput "✗ Failed to install Chocolatey: $($_.Exception.Message)" -Type Error
            exit 1
        }
    }
}

function Install-Packages {
    param(
        [string[]]$Packages,
        [string]$ProfileName
    )
    
    Write-ColorOutput "`nInstalling $ProfileName packages..." -Type Header
    
    # Check if package list is empty
    if ($null -eq $Packages -or $Packages.Count -eq 0) {
        Write-ColorOutput "⚠ No packages to install for $ProfileName profile" -Type Warning
        Write-ColorOutput "This is normal if the package file is empty or all packages are commented out" -Type Info
        return
    }
    
    # Get list of installed packages from Chocolatey
    Write-ColorOutput "`nChecking installed packages..." -Type Info
    $chocoList = choco list --local-only --limit-output
    $installedChocoPackages = @{}
    
    foreach ($line in $chocoList) {
        if ($line -match '^(.+?)\|(.+)$') {
            $installedChocoPackages[$matches[1]] = $matches[2]
        }
    }
    
    # Load installation history database
    $installedPackages = Get-InstalledPackagesDB
    
    # Filter out already installed packages
    $packagesToInstall = @()
    $skippedCount = 0
    
    foreach ($package in $Packages) {
        # Skip empty package names
        if ([string]::IsNullOrWhiteSpace($package)) {
            continue
        }
        
        # Check if package is installed via Chocolatey
        if ($installedChocoPackages.ContainsKey($package)) {
            $version = $installedChocoPackages[$package]
            Write-ColorOutput "⊳ Skipping $package (v$version already installed)" -Type Info
            $skippedCount++
            
            # Update database with actual installed package
            if (-not $installedPackages.ContainsKey($package)) {
                Add-PackageToInstalledDB -PackageName $package -ProfileName $ProfileName -Version $version
            }
        } else {
            $packagesToInstall += $package
        }
    }
    
    if ($skippedCount -gt 0) {
        Write-ColorOutput "`n$skippedCount package(s) already installed (skipped)" -Type Success
    }
    
    if ($packagesToInstall.Count -eq 0) {
        Write-ColorOutput "`nAll packages are already installed! ✓" -Type Success
        return
    }
    
    Write-ColorOutput "`nPackages to install: $($packagesToInstall.Count)" -Type Info
    
    $successCount = 0
    $failCount = 0
    
    foreach ($package in $packagesToInstall) {
        Write-ColorOutput "`nInstalling: $package" -Type Info
        
        try {
            choco install $package -y --ignore-checksums
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✓ $package installed successfully" -Type Success
                $successCount++
                
                # Get installed version
                $chocoInfo = choco list $package --local-only --limit-output --exact
                $version = "unknown"
                if ($chocoInfo -match '^.+?\|(.+)$') {
                    $version = $matches[1]
                }
                
                # Add to installation database
                Add-PackageToInstalledDB -PackageName $package -ProfileName $ProfileName -Version $version
            } else {
                Write-ColorOutput "✗ $package installation failed" -Type Warning
                $failCount++
            }
        } catch {
            Write-ColorOutput "✗ Error installing $package : $($_.Exception.Message)" -Type Error
            $failCount++
        }
    }
    
    Write-ColorOutput "`n═══════════════════════════════════" -Type Header
    Write-ColorOutput "Installation Summary:" -Type Header
    Write-ColorOutput "Successful: $successCount" -Type Success
    Write-ColorOutput "Failed: $failCount" -Type $(if ($failCount -eq 0) { 'Success' } else { 'Warning' })
    if ($skippedCount -gt 0) {
        Write-ColorOutput "Skipped: $skippedCount (already installed)" -Type Info
    }
    Write-ColorOutput "═══════════════════════════════════`n" -Type Header
}

function Get-InstalledPackagesDB {
    $scriptPath = Split-Path -Parent $MyInvocation.PSCommandPath
    $dbPath = Join-Path -Path $scriptPath -ChildPath "installed-packages.json"
    
    if (-not (Test-Path $dbPath)) {
        return @{}
    }
    
    try {
        $jsonContent = Get-Content -Path $dbPath -Raw -ErrorAction Stop
        $dbData = $jsonContent | ConvertFrom-Json
        
        # Convert to hashtable for faster lookups
        $installedPackages = @{}
        foreach ($property in $dbData.PSObject.Properties) {
            $installedPackages[$property.Name] = $property.Value
        }
        
        return $installedPackages
    } catch {
        Write-ColorOutput "⚠ Warning: Could not load installation database" -Type Warning
        return @{}
    }
}

function Add-PackageToInstalledDB {
    param(
        [string]$PackageName,
        [string]$ProfileName,
        [string]$Version = "unknown"
    )
    
    $scriptPath = Split-Path -Parent $MyInvocation.PSCommandPath
    $dbPath = Join-Path -Path $scriptPath -ChildPath "installed-packages.json"
    
    # Load existing database
    $installedPackages = Get-InstalledPackagesDB
    
    # Add or update package entry
    $installedPackages[$PackageName] = @{
        InstallDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Profile = $ProfileName
        Version = $Version
    }
    
    # Save to file
    try {
        $installedPackages | ConvertTo-Json -Depth 3 | Set-Content -Path $dbPath -Encoding UTF8
    } catch {
        Write-ColorOutput "⚠ Warning: Could not save to installation database" -Type Warning
    }
}

function Clear-InstalledPackagesDB {
    $scriptPath = Split-Path -Parent $MyInvocation.PSCommandPath
    $dbPath = Join-Path -Path $scriptPath -ChildPath "installed-packages.json"
    
    if (Test-Path $dbPath) {
        Remove-Item -Path $dbPath -Force
        Write-ColorOutput "✓ Installation database cleared" -Type Success
    } else {
        Write-ColorOutput "⚠ No installation database found" -Type Warning
    }
}

function Get-PackagesFromFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FileName
    )
    
    $scriptPath = Split-Path -Parent $MyInvocation.PSCommandPath
    $packagesFolder = Join-Path -Path $scriptPath -ChildPath "packages"
    $filePath = Join-Path -Path $packagesFolder -ChildPath $FileName
    
    if (-not (Test-Path $filePath)) {
        Write-ColorOutput "✗ Package file not found: $filePath" -Type Error
        return @()
    }
    
    Write-ColorOutput "Loading packages from: packages\$FileName" -Type Info
    
    # Read YAML file and extract packages
    $content = Get-Content -Path $filePath -Raw -ErrorAction SilentlyContinue
    
    # Handle empty or null content
    if ([string]::IsNullOrWhiteSpace($content)) {
        Write-ColorOutput "⚠ Package file is empty: $FileName" -Type Warning
        return @()
    }
    
    $packages = @()
    
    # Simple YAML parser for our package lists
    $lines = $content -split "`n"
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        # Skip comments, empty lines, and YAML keys
        if ($trimmed -match '^#' -or $trimmed -eq '' -or $trimmed -eq '---' -or 
            $trimmed -match '^\w+:$' -or $trimmed -match '^packages:$' -or $trimmed -match '^modules:$') {
            continue
        }
        # Extract package names from list items (- packagename)
        if ($trimmed -match '^\s*-\s+(.+)$') {
            $packageName = $matches[1].Trim()
            # Skip empty package names
            if (-not [string]::IsNullOrWhiteSpace($packageName)) {
                $packages += $packageName
            }
        }
    }
    
    # Notify if no packages found
    if ($packages.Count -eq 0) {
        Write-ColorOutput "⚠ No packages found in: $FileName (this is OK if intentional)" -Type Warning
    } else {
        Write-ColorOutput "Found $($packages.Count) package(s) in $FileName" -Type Success
    }
    
    return $packages
}

function Get-ProfilePackages {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProfileName,
        
        [switch]$IncludeBasic
    )
    
    $packages = @()
    
    # Include basic packages if requested (default for most profiles except basic itself)
    if ($IncludeBasic) {
        $packages += Get-PackagesFromFile -FileName "basic.yaml"
    }
    
    # Add profile-specific packages
    $profileFile = "$ProfileName.yaml"
    $packages += Get-PackagesFromFile -FileName $profileFile
    
    return $packages
}

function Get-AvailableProfiles {
    $scriptPath = Split-Path -Parent $MyInvocation.PSCommandPath
    $packagesFolder = Join-Path -Path $scriptPath -ChildPath "packages"
    
    # Get all YAML files except modules, template, and profile-config
    $profileFiles = Get-ChildItem -Path $packagesFolder -Filter "*.yaml" | 
        Where-Object { 
            $_.Name -ne 'modules.yaml' -and 
            $_.Name -ne 'template.yaml' 
        } | 
        Sort-Object Name
    
    $profiles = @()
    foreach ($file in $profileFiles) {
        $profileName = $file.BaseName
        $profiles += @{
            Name = $profileName
            DisplayName = (Get-Culture).TextInfo.ToTitleCase($profileName)
            File = $file.Name
        }
    }
    
    return $profiles
}

function Show-Menu {
    $profiles = Get-AvailableProfiles
    $menuColors = @('Yellow', 'Cyan', 'Green', 'Blue', 'White', 'Magenta', 'DarkYellow', 'DarkCyan', 'DarkGreen')
    
    Write-ColorOutput "Select Installation Profile(s):" -Type Header
    Write-Host ""
    
    # Dynamic profile menu
    $menuNumber = 1
    foreach ($profile in $profiles) {
        $colorIndex = ($menuNumber - 1) % $menuColors.Count
        $color = $menuColors[$colorIndex]
        
        # Add description based on profile name
        $description = switch ($profile.Name) {
            'basic' { "Essential applications for everyday use" }
            'developer' { "Programming tools, IDEs, and development environment" }
            'gaming' { "Gaming platforms and related tools" }
            'powershell' { "PowerShell tools and terminal setup" }
            'social' { "WhatsApp, Telegram, and social media apps" }
            'tools' { "System utilities, package managers, and power user tools" }
            default { "$($profile.DisplayName) packages" }
        }
        
        Write-Host ("  {0}. {1,-15} - {2}" -f $menuNumber, $profile.DisplayName, $description) -ForegroundColor $color
        $menuNumber++
    }
    
    # Static menu options
    $customOption = $menuNumber
    $profileOption = $menuNumber + 1
    $historyOption = $menuNumber + 2
    $exitOption = $menuNumber + 3
    
    Write-Host ("  {0}. {1,-15} - {2}" -f $customOption, "Custom", "Choose packages manually") -ForegroundColor Magenta
    Write-Host ("  {0}. {1,-15} - {2}" -f $profileOption, "Configure Profile", "Setup Oh-My-Posh, aliases, and functions") -ForegroundColor DarkCyan
    Write-Host ("  {0}. {1,-15} - {2}" -f $historyOption, "Install History", "View/clear installation history") -ForegroundColor Gray
    Write-Host ("  {0}. {1,-15} - {2}" -f $exitOption, "Exit", "Exit the installer") -ForegroundColor Red
    Write-Host ""
    Write-ColorOutput "TIP: You can select multiple profile numbers (e.g., 1,3,5 for multiple profiles)" -Type Info
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1-$exitOption or comma-separated)"
    return $choice
}

function Show-InstallHistory {
    Write-ColorOutput "`n═══════════════════════════════════" -Type Header
    Write-ColorOutput "Installation History" -Type Header
    Write-ColorOutput "═══════════════════════════════════" -Type Header
    
    $installedPackages = Get-InstalledPackagesDB
    
    if ($installedPackages.Count -eq 0) {
        Write-ColorOutput "`nNo packages tracked in database yet." -Type Info
        Write-ColorOutput "Note: Packages installed before database tracking won't appear here." -Type Info
        return
    }
    
    Write-ColorOutput "`nTotal packages tracked: $($installedPackages.Count)" -Type Success
    Write-Host ""
    
    # Group by profile
    $byProfile = @{}
    foreach ($pkg in $installedPackages.GetEnumerator()) {
        $profileName = $pkg.Value.Profile
        if (-not $byProfile.ContainsKey($profileName)) {
            $byProfile[$profileName] = @()
        }
        $byProfile[$profileName] += @{
            Name = $pkg.Key
            Date = $pkg.Value.InstallDate
            Version = $pkg.Value.Version
        }
    }
    
    # Display grouped by profile
    foreach ($profileName in ($byProfile.Keys | Sort-Object)) {
        Write-ColorOutput "`n$profileName Profile:" -Type Header
        $packages = $byProfile[$profileName] | Sort-Object Name
        foreach ($pkg in $packages) {
            $versionInfo = if ($pkg.Version -ne "unknown") { "v$($pkg.Version)" } else { "" }
            Write-Host ("  • {0,-30} {1,-15} (installed: {2})" -f $pkg.Name, $versionInfo, $pkg.Date) -ForegroundColor Cyan
        }
    }
    
    Write-Host "`n"
    Write-ColorOutput "Note: This shows packages tracked by this script." -Type Info
    Write-ColorOutput "Use 'choco list' to see all Chocolatey packages." -Type Info
    Write-Host "`n"
    
    $clearChoice = Read-Host "Would you like to clear the installation history? (y/n)"
    if ($clearChoice -eq 'y' -or $clearChoice -eq 'Y') {
        Clear-InstalledPackagesDB
        Write-ColorOutput "Note: Packages are still installed via Chocolatey." -Type Info
        Write-ColorOutput "The script will check Chocolatey and skip already installed packages." -Type Info
    }
}

function Start-CustomInstallation {
    Write-ColorOutput "`nCustom Package Installation" -Type Header
    Write-ColorOutput "Enter package names separated by commas (or type 'list' to see available packages)" -Type Info
    
    $pkgInput = Read-Host "Packages"
    
    if ($pkgInput -eq 'list') {
        Write-ColorOutput "`nOpening Chocolatey package search in browser..." -Type Info
        Start-Process "https://community.chocolatey.org/packages"
        return
    }
    
    $packages = $pkgInput -split ',' | ForEach-Object { $_.Trim() }
    
    if ($packages.Count -gt 0) {
        Install-Packages -Packages $packages -ProfileName "Custom"
    } else {
        Write-ColorOutput "No packages specified" -Type Warning
    }
}

function Update-AllPackages {
    Write-ColorOutput "`nUpdating all installed packages..." -Type Info
    choco upgrade all -y
}

function Update-PowerShellProfile {
    Write-ColorOutput "`nConfiguring PowerShell Profile..." -Type Header
    
    # Check if oh-my-posh is installed
    $ohMyPoshInstalled = Get-Command oh-my-posh -ErrorAction SilentlyContinue
    
    if (-not $ohMyPoshInstalled) {
        Write-ColorOutput "oh-my-posh is not installed. Installing now..." -Type Warning
        choco install oh-my-posh -y
        choco install nerd-fonts-cascadiacode -y
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
    
    # Create profile if it doesn't exist
    if (-not (Test-Path $PROFILE)) {
        Write-ColorOutput "Creating PowerShell profile at: $PROFILE" -Type Info
        New-Item -Path $PROFILE -ItemType File -Force | Out-Null
    }
    
    # Backup existing profile
    if (Test-Path $PROFILE) {
        $backupPath = "$PROFILE.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item -Path $PROFILE -Destination $backupPath -Force
        Write-ColorOutput "Backed up existing profile to: $backupPath" -Type Success
    }
    
    # Read profile content from external file
    $scriptPath = Split-Path -Parent $MyInvocation.PSCommandPath
    $packagesFolder = Join-Path -Path $scriptPath -ChildPath "packages"
    $profileConfigFile = Join-Path -Path $packagesFolder -ChildPath "profile-config.ps1"
    
    if (-not (Test-Path $profileConfigFile)) {
        Write-ColorOutput "✗ Profile configuration file not found: $profileConfigFile" -Type Error
        return
    }
    
    $profileContent = Get-Content -Path $profileConfigFile -Raw
    
    # Write to profile
    Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8
    Write-ColorOutput "✓ PowerShell profile configured successfully!" -Type Success
    
    # Install PowerShell modules from file
    Write-ColorOutput "`nInstalling/Updating PowerShell modules..." -Type Info
    
    $modulesFile = Join-Path -Path $packagesFolder -ChildPath "modules.yaml"
    
    if (Test-Path $modulesFile) {
        # Read modules from YAML file
        $moduleContent = Get-Content -Path $modulesFile -Raw -ErrorAction SilentlyContinue
        $modules = @()
        
        # Handle empty content
        if (-not [string]::IsNullOrWhiteSpace($moduleContent)) {
            # Parse YAML for module names
            $lines = $moduleContent -split "`n"
            foreach ($line in $lines) {
                $trimmed = $line.Trim()
                # Extract module names from list items (- modulename)
                if ($trimmed -match '^\s*-\s+(.+)$') {
                    $moduleName = $matches[1].Trim()
                    # Skip empty module names
                    if (-not [string]::IsNullOrWhiteSpace($moduleName)) {
                        $modules += $moduleName
                    }
                }
            }
        }
        
        if ($modules.Count -eq 0) {
            Write-ColorOutput "⚠ No modules found in modules.yaml (this is OK if intentional)" -Type Warning
            Write-ColorOutput "Skipping module installation..." -Type Info
        } else {
            Write-ColorOutput "Found $($modules.Count) module(s) to install" -Type Info
            
            foreach ($moduleName in $modules) {
                try {
                    if (-not (Get-Module -ListAvailable -Name $moduleName)) {
                        Write-ColorOutput "Installing: $moduleName" -Type Info
                        Install-Module -Name $moduleName -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
                        Write-ColorOutput "✓ $moduleName installed" -Type Success
                    } else {
                        Write-ColorOutput "✓ $moduleName already installed" -Type Success
                    }
                } catch {
                    Write-ColorOutput "✗ Failed to install $moduleName : $($_.Exception.Message)" -Type Warning
                }
            }
        }
    } else {
        Write-ColorOutput "✗ Modules file not found: $modulesFile" -Type Warning
        Write-ColorOutput "Installing default modules..." -Type Info
        
        # Fallback to default modules
        $defaultModules = @('PSReadLine', 'Terminal-Icons', 'posh-git')
        
        foreach ($moduleName in $defaultModules) {
            try {
                if (-not (Get-Module -ListAvailable -Name $moduleName)) {
                    Install-Module -Name $moduleName -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
                    Write-ColorOutput "✓ $moduleName installed" -Type Success
                } else {
                    Write-ColorOutput "✓ $moduleName already installed" -Type Success
                }
            } catch {
                Write-ColorOutput "✗ Failed to install $moduleName : $($_.Exception.Message)" -Type Warning
            }
        }
    }
    
    Write-ColorOutput "`n═══════════════════════════════════" -Type Header
    Write-ColorOutput "Profile Configuration Complete!" -Type Success
    Write-ColorOutput "═══════════════════════════════════" -Type Header
    Write-ColorOutput "`nProfile location: $PROFILE" -Type Info
    Write-ColorOutput "`nRestart your PowerShell terminal to apply changes." -Type Warning
    Write-ColorOutput "Or run: . `$PROFILE" -Type Info
    
    # Ask to reload profile
    $reload = Read-Host "`nWould you like to reload the profile now? (y/n)"
    if ($reload -eq 'y' -or $reload -eq 'Y') {
        try {
            . $PROFILE
            Write-ColorOutput "✓ Profile reloaded!" -Type Success
        } catch {
            Write-ColorOutput "✗ Error reloading profile. Please restart PowerShell." -Type Warning
        }
    }
    
    # Ask to configure Windows Terminal
    Write-Host ""
    $configTerminal = Read-Host "Would you like to configure Windows Terminal with PowerShell 7 as default? (y/n)"
    if ($configTerminal -eq 'y' -or $configTerminal -eq 'Y') {
        Update-WindowsTerminalSettings
    }
}

function Update-WindowsTerminalSettings {
    Write-ColorOutput "`nConfiguring Windows Terminal..." -Type Header
    
    # Windows Terminal settings path
    $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    
    if (-not (Test-Path $wtSettingsPath)) {
        Write-ColorOutput "✗ Windows Terminal settings file not found." -Type Warning
        Write-ColorOutput "Please make sure Windows Terminal is installed." -Type Info
        return
    }
    
    # Backup existing settings
    $backupPath = "$wtSettingsPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item -Path $wtSettingsPath -Destination $backupPath -Force
    Write-ColorOutput "Backed up existing Windows Terminal settings to: $backupPath" -Type Success
    
    try {
        # Read existing settings
        $existingSettings = Get-Content -Path $wtSettingsPath -Raw | ConvertFrom-Json
        
        # Find PowerShell 7 GUID
        $pwsh7Profile = $existingSettings.profiles.list | Where-Object { $_.source -eq "Windows.Terminal.PowershellCore" }
        
        if ($pwsh7Profile) {
            # Set PowerShell 7 as default profile
            $existingSettings.defaultProfile = $pwsh7Profile.guid
            Write-ColorOutput "✓ Set PowerShell 7 as default profile" -Type Success
            
            # Update font for PowerShell 7 profile
            if (-not $pwsh7Profile.font) {
                $pwsh7Profile | Add-Member -MemberType NoteProperty -Name "font" -Value @{
                    face = "CaskaydiaCove Nerd Font"
                    size = 11
                } -Force
            } else {
                $pwsh7Profile.font.face = "CaskaydiaCove Nerd Font"
                if (-not $pwsh7Profile.font.size) {
                    $pwsh7Profile.font | Add-Member -MemberType NoteProperty -Name "size" -Value 11 -Force
                }
            }
            Write-ColorOutput "✓ Configured Nerd Font for PowerShell 7" -Type Success
            
            # Add -NoLogo to commandline if not present
            if ($pwsh7Profile.commandline -notmatch "-NoLogo") {
                if ($pwsh7Profile.commandline) {
                    $pwsh7Profile.commandline = $pwsh7Profile.commandline + " -NoLogo"
                } else {
                    $pwsh7Profile | Add-Member -MemberType NoteProperty -Name "commandline" -Value "pwsh.exe -NoLogo" -Force
                }
                Write-ColorOutput "✓ Added -NoLogo flag to PowerShell 7" -Type Success
            }
        } else {
            Write-ColorOutput "✗ PowerShell 7 profile not found in Windows Terminal" -Type Warning
            Write-ColorOutput "Please install PowerShell 7 first" -Type Info
            return
        }
        
        # Update defaults for all profiles (optional)
        if (-not $existingSettings.profiles.defaults) {
            $existingSettings.profiles | Add-Member -MemberType NoteProperty -Name "defaults" -Value @{
                font = @{
                    face = "CaskaydiaCove Nerd Font"
                }
            } -Force
            Write-ColorOutput "✓ Set default font for all profiles" -Type Success
        } else {
            if (-not $existingSettings.profiles.defaults.font) {
                $existingSettings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "font" -Value @{
                    face = "CaskaydiaCove Nerd Font"
                } -Force
            } else {
                $existingSettings.profiles.defaults.font.face = "CaskaydiaCove Nerd Font"
            }
            Write-ColorOutput "✓ Updated default font" -Type Success
        }
        
        # Save updated settings
        $existingSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $wtSettingsPath -Encoding UTF8
        
        Write-ColorOutput "`n═══════════════════════════════════" -Type Header
        Write-ColorOutput "Windows Terminal Configuration Complete!" -Type Success
        Write-ColorOutput "═══════════════════════════════════" -Type Header
        Write-ColorOutput "`nSettings applied:" -Type Info
        Write-ColorOutput "  • Default Profile: PowerShell 7" -Type Success
        Write-ColorOutput "  • Font: CaskaydiaCove Nerd Font" -Type Success
        Write-ColorOutput "  • NoLogo flag: Enabled" -Type Success
        Write-ColorOutput "`nRestart Windows Terminal to see the changes." -Type Warning
        
    } catch {
        Write-ColorOutput "✗ Error updating Windows Terminal settings: $($_.Exception.Message)" -Type Error
        Write-ColorOutput "You can restore from backup: $backupPath" -Type Info
    }
}

# Main Script Execution
try {
    Show-Banner
    
    # Check for admin privileges
    if (-not (Test-Administrator)) {
        Write-ColorOutput "✗ This script requires Administrator privileges!" -Type Error
        Write-ColorOutput "Requesting elevation..." -Type Warning
        
        # Re-launch the script with elevated privileges
        $scriptPath = $MyInvocation.MyCommand.Path
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        exit
    }
    
    # Install Chocolatey if not present
    Install-Chocolatey
    
    # Get available profiles for dynamic menu handling
    $availableProfiles = Get-AvailableProfiles
    $profileCount = $availableProfiles.Count
    $customOption = $profileCount + 1
    $profileConfigOption = $profileCount + 2
    $historyOption = $profileCount + 3
    $exitOption = $profileCount + 4
    
    # Main menu loop
    do {
        Show-Banner
        $choice = Show-Menu
        
        # Handle multi-selection
        if ($choice -match ',') {
            $choices = $choice -split ',' | ForEach-Object { $_.Trim() }
            $allPackages = @()
            $profileNames = @()
            
            foreach ($selectedChoice in $choices) {
                $choiceNum = [int]$selectedChoice
                
                if ($choiceNum -ge 1 -and $choiceNum -le $profileCount) {
                    # Profile selection
                    $profile = $availableProfiles[$choiceNum - 1]
                    $includeBasic = $profile.Name -ne 'basic'
                    $allPackages += Get-ProfilePackages -ProfileName $profile.Name -IncludeBasic:$includeBasic
                    $profileNames += $profile.DisplayName
                }
                elseif ($choiceNum -eq $customOption) {
                    Write-ColorOutput "`nCustom installation cannot be combined with other profiles." -Type Warning
                }
                elseif ($choiceNum -eq $profileConfigOption) {
                    Write-ColorOutput "`nPowerShell profile configuration cannot be combined with other options." -Type Warning
                }
                elseif ($choiceNum -eq $historyOption) {
                    Write-ColorOutput "`nInstall history cannot be combined with other options." -Type Warning
                }
                elseif ($choiceNum -eq $exitOption) {
                    Write-ColorOutput "`nExiting installer. Goodbye!" -Type Info
                    exit 0
                }
                else {
                    Write-ColorOutput "`nInvalid choice: $selectedChoice" -Type Warning
                }
            }

            if ($allPackages.Count -gt 0) {
                # Remove duplicates
                $uniquePackages = $allPackages | Select-Object -Unique
                $profileName = $profileNames -join " + "
                Install-Packages -Packages $uniquePackages -ProfileName $profileName
            }
        }
        else {
            # Single selection
            $choiceNum = [int]$choice
            
            if ($choiceNum -ge 1 -and $choiceNum -le $profileCount) {
                # Profile selection
                $profile = $availableProfiles[$choiceNum - 1]
                $includeBasic = $profile.Name -ne 'basic'
                $packages = Get-ProfilePackages -ProfileName $profile.Name -IncludeBasic:$includeBasic
                Install-Packages -Packages $packages -ProfileName $profile.DisplayName
            }
            elseif ($choiceNum -eq $customOption) {
                Start-CustomInstallation
            }
            elseif ($choiceNum -eq $profileConfigOption) {
                Update-PowerShellProfile
            }
            elseif ($choiceNum -eq $historyOption) {
                Show-InstallHistory
            }
            elseif ($choiceNum -eq $exitOption) {
                Write-ColorOutput "`nExiting installer. Goodbye!" -Type Info
                exit 0
            }
            else {
                Write-ColorOutput "`nInvalid choice. Please select 1-$exitOption." -Type Warning
            }
        }
        
        if ($choice -ne $exitOption) {
            Write-Host "`n"
            Read-Host "Press Enter to return to main menu"
        }
        
    } while ($choice -ne $exitOption)
    
} catch {
    Write-ColorOutput "`n✗ An error occurred: $($_.Exception.Message)" -Type Error
    Write-ColorOutput $_.ScriptStackTrace -Type Error
    pause
    exit 1
}

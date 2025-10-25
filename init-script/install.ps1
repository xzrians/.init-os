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
    
    Write-ColorOutput "Packages to install: $($Packages.Count)" -Type Info
    
    $successCount = 0
    $failCount = 0
    
    foreach ($package in $Packages) {
        # Skip empty package names
        if ([string]::IsNullOrWhiteSpace($package)) {
            continue
        }
        
        Write-ColorOutput "`nInstalling: $package" -Type Info
        
        try {
            choco install $package -y --ignore-checksums
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✓ $package installed successfully" -Type Success
                $successCount++
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
    Write-ColorOutput "═══════════════════════════════════`n" -Type Header
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

function Get-BasicPackages {
    return Get-PackagesFromFile -FileName "basic.yaml"
}

function Get-DeveloperPackages {
    $basicPackages = Get-BasicPackages
    $devPackages = Get-PackagesFromFile -FileName "developer.yaml"
    
    return $basicPackages + $devPackages
}

function Get-GamingPackages {
    $basicPackages = Get-BasicPackages
    $gamingPackages = Get-PackagesFromFile -FileName "gaming.yaml"
    
    return $basicPackages + $gamingPackages
}

function Get-PowerShellPackages {
    $basicPackages = Get-BasicPackages
    $pwshPackages = Get-PackagesFromFile -FileName "powershell.yaml"
    
    return $basicPackages + $pwshPackages
}

function Show-Menu {
    Write-ColorOutput "Select Installation Profile(s):" -Type Header
    Write-Host ""
    Write-Host "  1. Basic            - Essential applications for everyday use" -ForegroundColor Yellow
    Write-Host "  2. Developer        - Programming tools, IDEs, and development environment" -ForegroundColor Cyan
    Write-Host "  3. Gaming           - Gaming platforms and related tools" -ForegroundColor Green
    Write-Host "  4. PowerShell       - PowerShell tools and terminal setup" -ForegroundColor Blue
    Write-Host "  5. Custom           - Choose packages manually" -ForegroundColor Magenta
    Write-Host "  6. Configure PowerShell Profile - Setup Oh-My-Posh, aliases, and functions" -ForegroundColor DarkCyan
    Write-Host "  7. Exit             - Exit the installer" -ForegroundColor Red
    Write-Host ""
    Write-ColorOutput "TIP: You can select multiple options (e.g., 1,3 for Basic + Gaming)" -Type Info
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1-7 or comma-separated like 1,2,4)"
    return $choice
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
                switch ($selectedChoice) {
                    '1' {
                        $allPackages += Get-BasicPackages
                        $profileNames += "Basic"
                    }
                    '2' {
                        $allPackages += Get-DeveloperPackages
                        $profileNames += "Developer"
                    }
                    '3' {
                        $allPackages += Get-GamingPackages
                        $profileNames += "Gaming"
                    }
                    '4' {
                        $allPackages += Get-PowerShellPackages
                        $profileNames += "PowerShell"
                    }
                    '5' {
                        Write-ColorOutput "`nCustom installation cannot be combined with other profiles." -Type Warning
                    }
                    '6' {
                        Write-ColorOutput "`nPowerShell profile configuration cannot be combined with other options." -Type Warning
                    }
                    '7' {
                        Write-ColorOutput "`nExiting installer. Goodbye!" -Type Info
                        exit 0
                    }
                    default {
                        Write-ColorOutput "`nInvalid choice: $selectedChoice" -Type Warning
                    }
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
            switch ($choice) {
                '1' {
                    $packages = Get-BasicPackages
                    Install-Packages -Packages $packages -ProfileName "Basic"
                }
                '2' {
                    $packages = Get-DeveloperPackages
                    Install-Packages -Packages $packages -ProfileName "Developer"
                }
                '3' {
                    $packages = Get-GamingPackages
                    Install-Packages -Packages $packages -ProfileName "Gaming"
                }
                '4' {
                    $packages = Get-PowerShellPackages
                    Install-Packages -Packages $packages -ProfileName "PowerShell"
                }
                '5' {
                    Start-CustomInstallation
                }
                '6' {
                    Update-PowerShellProfile
                }
                '7' {
                    Write-ColorOutput "`nExiting installer. Goodbye!" -Type Info
                    exit 0
                }
                default {
                    Write-ColorOutput "`nInvalid choice. Please select 1-7." -Type Warning
                }
            }
        }
        
        if ($choice -ne '7') {
            Write-Host "`n"
            Read-Host "Press Enter to return to main menu"
        }
        
    } while ($choice -ne '7')
    
} catch {
    Write-ColorOutput "`n✗ An error occurred: $($_.Exception.Message)" -Type Error
    Write-ColorOutput $_.ScriptStackTrace -Type Error
    pause
    exit 1
}

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
    Write-Host "║            Chocolatey + Winget Support                     ║" -ForegroundColor $script:Colors.Header
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

function Install-Winget {
    Write-ColorOutput "Checking for winget (App Installer) installation..." -Type Info
    
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-ColorOutput "✓ Winget is already installed" -Type Success
        $wingetVersion = (winget --version) -replace 'v', ''
        Write-Host "  Version: $wingetVersion" -ForegroundColor Gray
    } else {
        Write-ColorOutput "Installing App Installer (winget) from Microsoft Store..." -Type Warning
        
        try {
            # Install App Installer via winget bootstrap or direct download
            # Method 1: Try using Add-AppxPackage with Microsoft Store link
            Write-ColorOutput "Attempting to install via Microsoft Store..." -Type Info
            
            # Use ms-windows-store protocol to open App Installer page
            Start-Process "ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
            
            Write-ColorOutput "`nPlease complete the installation from Microsoft Store window that opened." -Type Warning
            Write-ColorOutput "After installation completes, press any key to continue..." -Type Info
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            
            # Verify installation
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Write-ColorOutput "✓ Winget installed successfully!" -Type Success
            } else {
                Write-ColorOutput "⚠ Winget not detected. You may need to restart your terminal." -Type Warning
                Write-ColorOutput "  Or install manually from: https://apps.microsoft.com/detail/9NBLGGH4NNS1" -Type Info
            }
        } catch {
            Write-ColorOutput "⚠ Could not auto-install winget: $($_.Exception.Message)" -Type Warning
            Write-ColorOutput "  Please install App Installer manually from Microsoft Store:" -Type Info
            Write-ColorOutput "  https://apps.microsoft.com/detail/9NBLGGH4NNS1" -Type Info
        }
    }
}

function Initialize-PackageManagers {
    Write-ColorOutput "`n═══════════════════════════════════" -Type Header
    Write-ColorOutput "Package Manager Setup" -Type Header
    Write-ColorOutput "═══════════════════════════════════`n" -Type Header
    
    # Install Chocolatey
    Install-Chocolatey
    Write-Host ""
    
    # Install Winget
    Install-Winget
    
    Write-ColorOutput "`n✓ Package managers ready!" -Type Success
    Start-Sleep -Seconds 2
}


function Install-Packages {
    param(
        [array]$Packages,
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
    
    # Get list of installed packages from winget
    $wingetList = winget list --accept-source-agreements 2>&1 | Out-String
    $installedWingetPackages = @{}
    
    # Parse winget output (format is more complex, look for installed packages)
    $wingetLines = $wingetList -split "`n"
    foreach ($line in $wingetLines) {
        # Match package ID patterns (skip header lines)
        if ($line -match '^\s*(.+?)\s+(.+?)\s+([\d\.]+)') {
            $pkgId = $matches[2].Trim()
            $installedWingetPackages[$pkgId] = $matches[3].Trim()
        }
    }
    
    # Load installation history database
    $installedPackages = Get-InstalledPackagesDB
    
    # Filter out already installed packages and detect migrations
    $packagesToInstall = @()
    $packagesToMigrate = @()
    $skippedCount = 0
    
    foreach ($pkg in $Packages) {
        # Handle both string and hashtable package formats
        $packageName = if ($pkg -is [hashtable]) { $pkg.package } else { $pkg }
        $packageManager = if ($pkg -is [hashtable]) { $pkg.manager } else { 'choco' }
        $displayName = if ($pkg -is [hashtable] -and $pkg.name) { $pkg.name } else { $packageName }
        
        # Skip empty package names
        if ([string]::IsNullOrWhiteSpace($packageName)) {
            continue
        }
        
        # Check if package is installed with DIFFERENT manager (migration needed)
        $needsMigration = $false
        $oldManager = $null
        $oldVersion = $null
        
        if ($packageManager -eq 'winget') {
            # Want winget, check if installed via choco
            if ($installedChocoPackages.ContainsKey($packageName)) {
                $needsMigration = $true
                $oldManager = 'choco'
                $oldVersion = $installedChocoPackages[$packageName]
            }
        } else {
            # Want choco, check if installed via winget
            if ($installedWingetPackages.ContainsKey($packageName)) {
                $needsMigration = $true
                $oldManager = 'winget'
                $oldVersion = $installedWingetPackages[$packageName]
            }
        }
        
        if ($needsMigration) {
            $packagesToMigrate += @{
                package = $packageName
                manager = $packageManager
                oldManager = $oldManager
                name = $displayName
                oldVersion = $oldVersion
            }
            continue
        }
        
        # Check if package is installed based on manager type
        $isInstalled = $false
        $version = "unknown"
        
        if ($packageManager -eq 'winget') {
            if ($installedWingetPackages.ContainsKey($packageName)) {
                $isInstalled = $true
                $version = $installedWingetPackages[$packageName]
            }
        } else {
            # Default to chocolatey
            if ($installedChocoPackages.ContainsKey($packageName)) {
                $isInstalled = $true
                $version = $installedChocoPackages[$packageName]
            }
        }
        
        if ($isInstalled) {
            Write-ColorOutput "⊳ Skipping $displayName (v$version already installed via $packageManager)" -Type Info
            $skippedCount++
            
            # Update database with actual installed package
            $dbKey = "$packageManager`:$packageName"
            if (-not $installedPackages.ContainsKey($dbKey)) {
                Add-PackageToInstalledDB -PackageName $dbKey -ProfileName $ProfileName -Version $version
            }
        } else {
            $packagesToInstall += @{
                package = $packageName
                manager = $packageManager
                name = $displayName
            }
        }
    }
    
    # Handle package migrations
    if ($packagesToMigrate.Count -gt 0) {
        Write-ColorOutput "`n⚠ Detected $($packagesToMigrate.Count) package(s) that need migration:" -Type Warning
        foreach ($pkg in $packagesToMigrate) {
            Write-Host "  • $($pkg.name): " -NoNewline -ForegroundColor Yellow
            Write-Host "$($pkg.oldManager) → $($pkg.manager)" -ForegroundColor Cyan
        }
        
        Write-Host "`nMigration will:" -ForegroundColor White
        Write-Host "  1. Uninstall from $($packagesToMigrate[0].oldManager)" -ForegroundColor Gray
        Write-Host "  2. Install via $($packagesToMigrate[0].manager)" -ForegroundColor Gray
        Write-Host "  3. Preserve your data/settings" -ForegroundColor Gray
        
        $confirm = Read-Host "`nProceed with migration? (Y/N)"
        
        if ($confirm -eq 'Y' -or $confirm -eq 'y') {
            foreach ($pkg in $packagesToMigrate) {
                Write-ColorOutput "`nMigrating $($pkg.name) from $($pkg.oldManager) to $($pkg.manager)..." -Type Info
                
                # Uninstall from old manager
                try {
                    if ($pkg.oldManager -eq 'choco') {
                        Write-ColorOutput "  Uninstalling from Chocolatey..." -Type Info
                        choco uninstall $pkg.package -y
                        
                        # Remove old database entry
                        $oldDbKey = "choco:$($pkg.package)"
                        Remove-PackageFromInstalledDB -PackageName $oldDbKey
                    } else {
                        Write-ColorOutput "  Uninstalling from Winget..." -Type Info
                        winget uninstall --id $pkg.package --silent
                        
                        # Remove old database entry
                        $oldDbKey = "winget:$($pkg.package)"
                        Remove-PackageFromInstalledDB -PackageName $oldDbKey
                    }
                    
                    Write-ColorOutput "  ✓ Uninstalled from $($pkg.oldManager)" -Type Success
                    
                    # Add to install queue
                    $packagesToInstall += @{
                        package = $pkg.package
                        manager = $pkg.manager
                        name = $pkg.name
                    }
                    
                } catch {
                    Write-ColorOutput "  ⚠ Failed to uninstall: $($_.Exception.Message)" -Type Warning
                    Write-ColorOutput "  You may need to uninstall manually" -Type Info
                }
            }
        } else {
            Write-ColorOutput "Migration cancelled. Existing installations will remain." -Type Warning
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
    
    foreach ($pkg in $packagesToInstall) {
        $packageName = $pkg.package
        $packageManager = $pkg.manager
        $displayName = $pkg.name
        
        Write-ColorOutput "`nInstalling: $displayName (via $packageManager)" -Type Info
        
        try {
            if ($packageManager -eq 'winget') {
                # Install via winget
                winget install --id $packageName --accept-source-agreements --accept-package-agreements --silent
                
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorOutput "✓ $displayName installed successfully" -Type Success
                    $successCount++
                    
                    # Get installed version from winget
                    $wingetInfo = winget list --id $packageName --accept-source-agreements 2>&1 | Out-String
                    $version = "unknown"
                    if ($wingetInfo -match '^\s*.+?\s+.+?\s+([\d\.]+)') {
                        $version = $matches[1]
                    }
                    
                    # Add to installation database
                    $dbKey = "winget:$packageName"
                    Add-PackageToInstalledDB -PackageName $dbKey -ProfileName $ProfileName -Version $version
                } else {
                    Write-ColorOutput "✗ $displayName installation failed" -Type Warning
                    $failCount++
                }
            } else {
                # Install via chocolatey (default)
                choco install $packageName -y --ignore-checksums
                
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorOutput "✓ $displayName installed successfully" -Type Success
                    $successCount++
                    
                    # Get installed version
                    $chocoInfo = choco list $packageName --local-only --limit-output --exact
                    $version = "unknown"
                    if ($chocoInfo -match '^.+?\|(.+)$') {
                        $version = $matches[1]
                    }
                    
                    # Add to installation database
                    $dbKey = "choco:$packageName"
                    Add-PackageToInstalledDB -PackageName $dbKey -ProfileName $ProfileName -Version $version
                } else {
                    Write-ColorOutput "✗ $displayName installation failed" -Type Warning
                    $failCount++
                }
            }
        } catch {
            Write-ColorOutput "✗ Error installing $displayName : $($_.Exception.Message)" -Type Error
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

function Remove-PackageFromInstalledDB {
    param(
        [string]$PackageName
    )
    
    $scriptPath = Split-Path -Parent $MyInvocation.PSCommandPath
    $dbPath = Join-Path -Path $scriptPath -ChildPath "installed-packages.json"
    
    if (-not (Test-Path $dbPath)) {
        return
    }
    
    try {
        $installedPackages = Get-InstalledPackagesDB
        
        if ($installedPackages.ContainsKey($PackageName)) {
            $installedPackages.Remove($PackageName)
            $installedPackages | ConvertTo-Json -Depth 3 | Set-Content -Path $dbPath -Encoding UTF8
        }
    } catch {
        Write-ColorOutput "⚠ Warning: Could not remove from installation database" -Type Warning
    }
}

function Update-AllPackages {
    Write-ColorOutput "`n═══════════════════════════════════" -Type Header
    Write-ColorOutput "Upgrade All Packages" -Type Header
    Write-ColorOutput "═══════════════════════════════════" -Type Header
    
    Write-ColorOutput "`nChecking for outdated packages..." -Type Info
    
    # Get list of outdated packages
    $outdatedOutput = choco outdated --limit-output 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "⚠ Error checking for updates" -Type Warning
        return
    }
    
    # Parse outdated packages (format: packagename|currentversion|availableversion|pinned)
    $outdatedPackages = @()
    foreach ($line in $outdatedOutput) {
        if ($line -match '^(.+?)\|(.+?)\|(.+?)\|') {
            $outdatedPackages += [PSCustomObject]@{
                Name = $matches[1]
                Current = $matches[2]
                Available = $matches[3]
            }
        }
    }
    
    if ($outdatedPackages.Count -eq 0) {
        Write-ColorOutput "`n✓ All packages are up to date!" -Type Success
        return
    }
    
    Write-ColorOutput "`nFound $($outdatedPackages.Count) package(s) with available updates:" -Type Info
    Write-Host ""
    
    foreach ($pkg in $outdatedPackages) {
        Write-Host "  • " -NoNewline -ForegroundColor Yellow
        Write-Host "$($pkg.Name) " -NoNewline -ForegroundColor White
        Write-Host "v$($pkg.Current) " -NoNewline -ForegroundColor DarkGray
        Write-Host "→ " -NoNewline -ForegroundColor Yellow
        Write-Host "v$($pkg.Available)" -ForegroundColor Green
    }
    
    Write-Host ""
    $confirm = Read-Host "Upgrade all packages? (Y/N)"
    
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-ColorOutput "Upgrade cancelled" -Type Warning
        return
    }
    
    Write-ColorOutput "`nUpgrading all packages..." -Type Info
    
    # Upgrade all packages
    choco upgrade all -y
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "`n✓ All packages upgraded successfully!" -Type Success
        
        # Update database with new versions
        $installedPackages = Get-InstalledPackagesDB
        $chocoList = choco list --local-only --limit-output
        
        foreach ($line in $chocoList) {
            if ($line -match '^(.+?)\|(.+)$') {
                $pkgName = $matches[1]
                $pkgVersion = $matches[2]
                
                if ($installedPackages.ContainsKey($pkgName)) {
                    $installedPackages[$pkgName].Version = $pkgVersion
                    $installedPackages[$pkgName].LastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                }
            }
        }
        
        # Save updated database
        $scriptPath = Split-Path -Parent $MyInvocation.PSCommandPath
        $dbPath = Join-Path -Path $scriptPath -ChildPath "installed-packages.json"
        try {
            $installedPackages | ConvertTo-Json -Depth 3 | Set-Content -Path $dbPath -Encoding UTF8
            Write-ColorOutput "✓ Database updated with new versions" -Type Success
        } catch {
            Write-ColorOutput "⚠ Warning: Could not update database" -Type Warning
        }
    } else {
        Write-ColorOutput "`n⚠ Some packages failed to upgrade" -Type Warning
    }
}

function Get-PackagesFromFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FileName,
        [string]$ProfileName = $null
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
    
    # Simplified YAML parser - supports profile sections and winget:/choco: subsections
    $lines = $content -split "`n"
    $currentManager = 'choco'  # Default manager
    $currentProfile = $null
    $inTargetProfile = $false
    
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        
        # Skip comments, empty lines, and document markers
        if ($trimmed -match '^#' -or $trimmed -eq '' -or $trimmed -eq '---') {
            continue
        }
        
        # Check for profile section (e.g., "basic:", "developer:")
        if ($trimmed -match '^([a-z_]+):$' -and $trimmed -ne 'winget:' -and $trimmed -ne 'choco:' -and $trimmed -ne 'packages:' -and $trimmed -ne 'modules:') {
            $currentProfile = $matches[1]
            
            # If specific profile requested, only parse that profile
            if ($ProfileName) {
                $inTargetProfile = ($currentProfile -eq $ProfileName.ToLower())
            } else {
                $inTargetProfile = $true
            }
            continue
        }
        
        # If we have a profile filter and we're not in target profile, skip
        if ($ProfileName -and -not $inTargetProfile) {
            continue
        }
        
        # Check for manager section headers (indented under profile)
        if ($trimmed -eq 'winget:') {
            $currentManager = 'winget'
            continue
        }
        elseif ($trimmed -eq 'choco:') {
            $currentManager = 'choco'
            continue
        }
        elseif ($trimmed -eq 'packages:' -or $trimmed -eq 'modules:') {
            # Legacy format - default to choco
            $currentManager = 'choco'
            continue
        }
        
        # Extract package names from list items (- packagename or - packagename # comment)
        if ($trimmed -match '^\s*-\s+([^\s#]+)') {
            $packageName = $matches[1].Trim()
            
            # Skip empty package names
            if (-not [string]::IsNullOrWhiteSpace($packageName)) {
                $packages += @{
                    package = $packageName
                    manager = $currentManager
                    name = $packageName
                }
            }
        }
    }
    
    # Notify if no packages found
    if ($packages.Count -eq 0) {
        if ($ProfileName) {
            Write-ColorOutput "⚠ No packages found for profile: $ProfileName" -Type Warning
        } else {
            Write-ColorOutput "⚠ No packages found in: $FileName" -Type Warning
        }
    } else {
        if ($ProfileName) {
            Write-ColorOutput "Found $($packages.Count) package(s) for profile: $ProfileName" -Type Success
        } else {
            Write-ColorOutput "Found $($packages.Count) package(s) in $FileName" -Type Success
        }
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
    
    # Use unified packages.yaml if it exists, otherwise fall back to individual files
    $scriptPath = Split-Path -Parent $MyInvocation.PSCommandPath
    $packagesFolder = Join-Path -Path $scriptPath -ChildPath "packages"
    $unifiedFile = Join-Path -Path $packagesFolder -ChildPath "packages.yaml"
    
    if (Test-Path $unifiedFile) {
        # Use unified file
        if ($IncludeBasic -and $ProfileName.ToLower() -ne 'basic') {
            # Include basic packages
            $packages += Get-PackagesFromFile -FileName "packages.yaml" -ProfileName "basic"
        }
        
        # Add profile-specific packages
        $packages += Get-PackagesFromFile -FileName "packages.yaml" -ProfileName $ProfileName
    } else {
        # Fall back to individual files (backward compatibility)
        if ($IncludeBasic) {
            $packages += Get-PackagesFromFile -FileName "basic.yaml"
        }
        
        $profileFile = "$ProfileName.yaml"
        $packages += Get-PackagesFromFile -FileName $profileFile
    }
    
    return $packages
}

function Get-AvailableProfiles {
    $scriptPath = Split-Path -Parent $MyInvocation.PSCommandPath
    $packagesFolder = Join-Path -Path $scriptPath -ChildPath "packages"
    $unifiedFile = Join-Path -Path $packagesFolder -ChildPath "packages.yaml"
    
    # Check if unified packages.yaml exists
    if (Test-Path $unifiedFile) {
        # Parse unified file to extract profile names
        $content = Get-Content -Path $unifiedFile -Raw -ErrorAction SilentlyContinue
        $lines = $content -split "`n"
        
        $profiles = @()
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            # Match profile sections (e.g., "basic:", "developer:")
            if ($trimmed -match '^([a-z_]+):$' -and $trimmed -ne 'winget:' -and $trimmed -ne 'choco:' -and $trimmed -ne 'packages:' -and $trimmed -ne 'modules:') {
                $profileName = $matches[1]
                $profiles += @{
                    Name = $profileName
                    DisplayName = (Get-Culture).TextInfo.ToTitleCase($profileName)
                    File = "packages.yaml"
                }
            }
        }
        
        return $profiles
    } else {
        # Fall back to individual YAML files (backward compatibility)
        $profileFiles = Get-ChildItem -Path $packagesFolder -Filter "*.yaml" | 
            Where-Object { 
                $_.Name -ne 'modules.yaml' -and 
                $_.Name -ne 'template.yaml' -and
                $_.Name -ne 'packages.yaml'
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
    $upgradeOption = $menuNumber + 2
    $historyOption = $menuNumber + 3
    $exitOption = $menuNumber + 4
    
    Write-Host ("  {0}. {1,-15} - {2}" -f $customOption, "Custom", "Choose packages manually") -ForegroundColor Magenta
    Write-Host ("  {0}. {1,-15} - {2}" -f $profileOption, "Configure Profile", "Setup Oh-My-Posh, aliases, and functions") -ForegroundColor DarkCyan
    Write-Host ("  {0}. {1,-15} - {2}" -f $upgradeOption, "Upgrade All", "Upgrade all installed packages") -ForegroundColor Yellow
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
    
    # Initialize package managers (Chocolatey and Winget)
    Initialize-PackageManagers
    
    # Get available profiles for dynamic menu handling
    $availableProfiles = Get-AvailableProfiles
    $profileCount = $availableProfiles.Count
    $customOption = $profileCount + 1
    $profileConfigOption = $profileCount + 2
    $upgradeOption = $profileCount + 3
    $historyOption = $profileCount + 4
    $exitOption = $profileCount + 5
    
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
                elseif ($choiceNum -eq $upgradeOption) {
                    Write-ColorOutput "`nUpgrade all cannot be combined with other options." -Type Warning
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
            elseif ($choiceNum -eq $upgradeOption) {
                Update-AllPackages
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

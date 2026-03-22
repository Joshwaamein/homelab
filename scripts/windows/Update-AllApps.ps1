#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Updates all installed applications using winget.
.DESCRIPTION
    This script ensures winget and its prerequisites are installed,
    then upgrades all installed packages including unknown sources.
    Must be run as Administrator.
#>

# Set execution preferences
$ErrorActionPreference = "Continue"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Winget - Update All Applications Script"   -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# --- Step 1: Ensure prerequisites ---

# Check if NuGet package provider is installed (required for some module operations)
Write-Host "[1/4] Checking NuGet package provider..." -ForegroundColor Yellow
$nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
if (-not $nuget) {
    Write-Host "  Installing NuGet package provider..." -ForegroundColor Gray
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers | Out-Null
    Write-Host "  NuGet installed." -ForegroundColor Green
} else {
    Write-Host "  NuGet already installed." -ForegroundColor Green
}

# Check if winget is available
Write-Host "[2/4] Checking for winget..." -ForegroundColor Yellow
$wingetPath = Get-Command winget -ErrorAction SilentlyContinue

if (-not $wingetPath) {
    Write-Host "  winget not found. Attempting to install App Installer (winget)..." -ForegroundColor Gray

    # Try installing via Add-AppxPackage from the Microsoft Store bundle
    # First, install VCLibs dependency
    Write-Host "  Installing VCLibs dependency..." -ForegroundColor Gray
    try {
        Add-AppxPackage -Path "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -ErrorAction Stop
        Write-Host "  VCLibs installed." -ForegroundColor Green
    } catch {
        Write-Host "  VCLibs may already be installed or failed: $($_.Exception.Message)" -ForegroundColor DarkYellow
    }

    # Install Microsoft.UI.Xaml dependency
    Write-Host "  Installing Microsoft.UI.Xaml dependency..." -ForegroundColor Gray
    try {
        # Download and install UI.Xaml NuGet package
        $uiXamlUrl = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.6"
        $uiXamlZip = "$env:TEMP\Microsoft.UI.Xaml.2.8.6.zip"
        $uiXamlExtract = "$env:TEMP\Microsoft.UI.Xaml.2.8.6"
        Invoke-WebRequest -Uri $uiXamlUrl -OutFile $uiXamlZip -UseBasicParsing
        Expand-Archive -Path $uiXamlZip -DestinationPath $uiXamlExtract -Force
        $xamlAppx = Get-ChildItem -Path $uiXamlExtract -Recurse -Filter "Microsoft.UI.Xaml.2.8*.appx" |
                    Where-Object { $_.FullName -match "x64" } | Select-Object -First 1
        if ($xamlAppx) {
            Add-AppxPackage -Path $xamlAppx.FullName -ErrorAction Stop
        }
        Write-Host "  Microsoft.UI.Xaml installed." -ForegroundColor Green
    } catch {
        Write-Host "  Microsoft.UI.Xaml may already be installed or failed: $($_.Exception.Message)" -ForegroundColor DarkYellow
    }

    # Install winget (App Installer) from GitHub latest release
    Write-Host "  Downloading latest winget release..." -ForegroundColor Gray
    try {
        $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest" -UseBasicParsing
        $msixBundleUrl = ($releases.assets | Where-Object { $_.name -match "\.msixbundle$" }).browser_download_url
        $licenseUrl = ($releases.assets | Where-Object { $_.name -match "License.*\.xml$" }).browser_download_url

        $msixBundlePath = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
        $licensePath = "$env:TEMP\WingetLicense.xml"

        Invoke-WebRequest -Uri $msixBundleUrl -OutFile $msixBundlePath -UseBasicParsing
        if ($licenseUrl) {
            Invoke-WebRequest -Uri $licenseUrl -OutFile $licensePath -UseBasicParsing
            Add-AppxProvisionedPackage -Online -PackagePath $msixBundlePath -LicensePath $licensePath -ErrorAction Stop | Out-Null
        } else {
            Add-AppxPackage -Path $msixBundlePath -ErrorAction Stop
        }
        Write-Host "  winget installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "  Failed to install winget: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Please install 'App Installer' from the Microsoft Store manually." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Refresh PATH so winget is discoverable
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    # Verify winget is now available
    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetPath) {
        Write-Host "  winget is still not found after installation. You may need to restart your session." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}
else {
    Write-Host "  winget is available at: $($wingetPath.Source)" -ForegroundColor Green
}

# Accept source agreements by listing sources (triggers agreement acceptance)
Write-Host "[3/4] Accepting winget source agreements..." -ForegroundColor Yellow
winget source update --accept-source-agreements 2>&1 | Out-Null
Write-Host "  Source agreements accepted." -ForegroundColor Green

# --- Step 2: Upgrade all packages ---
Write-Host "[4/4] Upgrading all installed packages..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Running: winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements" -ForegroundColor Gray
Write-Host "-------------------------------------------" -ForegroundColor DarkGray

winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements

Write-Host ""
Write-Host "-------------------------------------------" -ForegroundColor DarkGray
Write-Host "All available updates have been processed!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan

Read-Host "Press Enter to exit"

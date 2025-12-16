# Script to install required dependencies for analyze_m3u8_durations.ps1
# This script will install ffmpeg (which includes ffprobe) using available package managers

param(
    [switch]$Force
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installing Dependencies for M3U8 Analyzer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Function to check if a command exists
function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Function to install with Chocolatey
function Install-WithChocolatey {
    Write-Host "Attempting to install ffmpeg using Chocolatey..." -ForegroundColor Yellow
    
    if (-not $isAdmin) {
        Write-Host "Note: Administrator privileges may be required for Chocolatey installation." -ForegroundColor Yellow
    }
    
    try {
        choco install ffmpeg -y
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] ffmpeg installed successfully using Chocolatey" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "[ERROR] Chocolatey installation failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    return $false
}

# Function to install with Scoop
function Install-WithScoop {
    Write-Host "Attempting to install ffmpeg using Scoop..." -ForegroundColor Yellow
    
    try {
        scoop install ffmpeg
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] ffmpeg installed successfully using Scoop" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "[ERROR] Scoop installation failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    return $false
}

# Function to install with winget
function Install-WithWinget {
    Write-Host "Attempting to install ffmpeg using winget..." -ForegroundColor Yellow
    
    try {
        winget install --id=Gyan.FFmpeg -e --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] ffmpeg installed successfully using winget" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "[ERROR] winget installation failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    return $false
}

# Function to download and install manually
function Install-Manually {
    Write-Host ""
    Write-Host "Manual Installation Instructions:" -ForegroundColor Yellow
    Write-Host "1. Download ffmpeg from: https://www.gyan.dev/ffmpeg/builds/" -ForegroundColor Cyan
    Write-Host "2. Or visit: https://ffmpeg.org/download.html" -ForegroundColor Cyan
    Write-Host "3. Extract the zip file" -ForegroundColor Cyan
    Write-Host "4. Add the 'bin' folder to your system PATH" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Quick download link (Windows builds):" -ForegroundColor Yellow
    Write-Host "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -ForegroundColor Cyan
    Write-Host ""
    
    $response = Read-Host "Would you like to open the download page in your browser? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        Start-Process "https://www.gyan.dev/ffmpeg/builds/"
    }
}

# Check if ffprobe is already installed
Write-Host "Checking if ffprobe is already installed..." -ForegroundColor Yellow
$ffprobeInstalled = Test-Command "ffprobe"

if ($ffprobeInstalled -and -not $Force) {
    Write-Host "[OK] ffprobe is already installed!" -ForegroundColor Green
    $ffprobeVersion = & ffprobe -version 2>&1 | Select-Object -First 1
    Write-Host "Version: $ffprobeVersion" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "If you want to reinstall, run: .\install_dependencies.ps1 -Force" -ForegroundColor Yellow
    exit 0
}

if ($ffprobeInstalled -and $Force) {
    Write-Host "Force flag detected. Proceeding with installation..." -ForegroundColor Yellow
    Write-Host ""
}

# Try different package managers
$installed = $false

# Try Chocolatey
if (Test-Command "choco") {
    Write-Host "[OK] Chocolatey detected" -ForegroundColor Green
    $installed = Install-WithChocolatey
    if ($installed) {
        Write-Host ""
        Write-Host "Please restart your PowerShell session or refresh your PATH environment variable." -ForegroundColor Yellow
        $pathCmd = '$env:Path = [System.Environment]::GetEnvironmentVariable(''Path'',''Machine'') + '';'' + [System.Environment]::GetEnvironmentVariable(''Path'',''User'')'
        Write-Host "You can refresh PATH by running: $pathCmd" -ForegroundColor Cyan
        exit 0
    }
}

# Try Scoop
if (-not $installed -and (Test-Command "scoop")) {
    Write-Host "[OK] Scoop detected" -ForegroundColor Green
    $installed = Install-WithScoop
    if ($installed) {
        exit 0
    }
}

# Try winget
if (-not $installed -and (Test-Command "winget")) {
    Write-Host "[OK] winget detected" -ForegroundColor Green
    $installed = Install-WithWinget
    if ($installed) {
        Write-Host ""
        Write-Host "Please restart your PowerShell session or refresh your PATH environment variable." -ForegroundColor Yellow
        exit 0
    }
}

# If all automated methods failed, provide manual instructions
if (-not $installed) {
    Write-Host ""
    Write-Host "[ERROR] Automated installation failed or no package manager found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Available package managers:" -ForegroundColor Yellow
    Write-Host "  - Chocolatey: https://chocolatey.org/install" -ForegroundColor Cyan
    Write-Host "  - Scoop: https://scoop.sh/" -ForegroundColor Cyan
    Write-Host "  - winget: Usually pre-installed on Windows 10/11" -ForegroundColor Cyan
    Write-Host ""
    
    Install-Manually
}

Write-Host ""
Write-Host "After installation, verify by running: ffprobe -version" -ForegroundColor Yellow


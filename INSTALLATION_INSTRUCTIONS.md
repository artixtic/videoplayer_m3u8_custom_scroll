# Installation Instructions for M3U8 Analyzer on Windows

## ✅ What Has Been Created

I've created the following files for you:

1. **`analyze_m3u8_durations.ps1`** - The main PowerShell script (Windows version of the bash script)
2. **`install_dependencies.ps1`** - Automated installation script for dependencies
3. **`README_WINDOWS.md`** - Complete documentation for Windows usage

## 📦 Installing FFmpeg (Required Dependency)

FFmpeg (which includes ffprobe) is required to run the script. You have several options:

### Option 1: Using Chocolatey (Recommended - Requires Admin)

1. **Open PowerShell as Administrator:**
   - Right-click on PowerShell
   - Select "Run as Administrator"

2. **Run the installation:**
   ```powershell
   cd "C:\Users\HP PROBOOK 450 G10\Desktop\MahboobAhmed\videoplayer_m3u8_custom_scroll"
   choco install ffmpeg -y
   ```

3. **Refresh your PATH:**
   ```powershell
   $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
   ```

4. **Verify installation:**
   ```powershell
   ffprobe -version
   ```

### Option 2: Using winget (Requires Admin)

1. **Open PowerShell as Administrator**

2. **Run:**
   ```powershell
   winget install --id=Gyan.FFmpeg -e --accept-package-agreements --accept-source-agreements
   ```

3. **Restart PowerShell** or refresh PATH:
   ```powershell
   $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
   ```

4. **Verify:**
   ```powershell
   ffprobe -version
   ```

### Option 3: Manual Installation (No Admin Required)

1. **Download FFmpeg:**
   - Visit: https://www.gyan.dev/ffmpeg/builds/
   - Download: **ffmpeg-release-essentials.zip**

2. **Extract:**
   - Extract to a folder like `C:\ffmpeg` or `C:\Users\HP PROBOOK 450 G10\ffmpeg`

3. **Add to PATH:**
   - Open System Properties → Environment Variables
   - Under "User variables", find "Path" and click "Edit"
   - Click "New" and add: `C:\ffmpeg\bin` (or wherever you extracted it)
   - Click OK on all dialogs

4. **Restart PowerShell** and verify:
   ```powershell
   ffprobe -version
   ```

### Option 4: Run the Automated Installer Script

1. **Open PowerShell as Administrator**

2. **Run:**
   ```powershell
   cd "C:\Users\HP PROBOOK 450 G10\Desktop\MahboobAhmed\videoplayer_m3u8_custom_scroll"
   .\install_dependencies.ps1
   ```

## 🚀 Using the Script

Once ffmpeg is installed, you can use the script:

### Basic Usage:
```powershell
.\analyze_m3u8_durations.ps1 <M3U8_URL>
```

### Examples:
```powershell
# Analyze all segments
.\analyze_m3u8_durations.ps1 https://example.com/playlist.m3u8

# With custom output file
.\analyze_m3u8_durations.ps1 https://example.com/playlist.m3u8 results.txt

# Analyze only first 10 segments (for testing)
.\analyze_m3u8_durations.ps1 https://example.com/playlist.m3u8 results.txt 10
```

## ⚠️ Important Notes

1. **Execution Policy:** If you get an execution policy error, run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **PATH Refresh:** After installing ffmpeg, you may need to:
   - Restart PowerShell, OR
   - Refresh PATH manually:
     ```powershell
     $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
     ```

3. **Verification:** Always verify ffmpeg is installed:
   ```powershell
   ffprobe -version
   ```

## 📝 Files Created

- ✅ `analyze_m3u8_durations.ps1` - Main analysis script
- ✅ `install_dependencies.ps1` - Dependency installer
- ✅ `README_WINDOWS.md` - Full documentation
- ✅ `INSTALLATION_INSTRUCTIONS.md` - This file

## 🆘 Troubleshooting

### "ffprobe is not recognized"
- Make sure ffmpeg is installed
- Verify it's in your PATH
- Restart PowerShell after installation

### "Execution Policy" Error
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Installation Requires Admin
- Right-click PowerShell → "Run as Administrator"
- Or use manual installation (Option 3) which doesn't require admin

## 📚 More Information

See `README_WINDOWS.md` for complete documentation and usage examples.


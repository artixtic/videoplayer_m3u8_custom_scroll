# M3U8 Duration Analysis Tool - Windows Version

This is a Windows PowerShell version of the M3U8 duration analysis script. It analyzes M3U8 playlist files and compares declared segment durations with actual durations.

## Prerequisites

- Windows 10 or later
- PowerShell 5.1 or later (usually pre-installed)
- ffmpeg (includes ffprobe) - **Required**

## Installation

### Option 1: Automated Installation (Recommended)

Run the installation script to automatically install ffmpeg:

```powershell
.\install_dependencies.ps1
```

This script will try to install ffmpeg using:
1. Chocolatey (if installed)
2. Scoop (if installed)
3. winget (if available)

### Option 2: Manual Installation

1. **Download ffmpeg:**
   - Visit: https://www.gyan.dev/ffmpeg/builds/
   - Download the "ffmpeg-release-essentials.zip" file

2. **Extract and Install:**
   - Extract the zip file to a location (e.g., `C:\ffmpeg`)
   - Add the `bin` folder to your system PATH:
     - Open System Properties → Environment Variables
     - Edit the "Path" variable
     - Add: `C:\ffmpeg\bin` (or wherever you extracted it)

3. **Verify Installation:**
   ```powershell
   ffprobe -version
   ```

### Option 3: Using Package Managers

**Chocolatey:**
```powershell
choco install ffmpeg
```

**Scoop:**
```powershell
scoop install ffmpeg
```

**winget:**
```powershell
winget install --id=Gyan.FFmpeg -e
```

## Usage

### Basic Usage

```powershell
.\analyze_m3u8_durations.ps1 <M3U8_URL>
```

### With Custom Output File

```powershell
.\analyze_m3u8_durations.ps1 <M3U8_URL> <output_file.txt>
```

### Limit Number of Segments (for testing)

```powershell
.\analyze_m3u8_durations.ps1 <M3U8_URL> <output_file.txt> 10
```

### Examples

```powershell
# Analyze all segments
.\analyze_m3u8_durations.ps1 https://example.com/playlist.m3u8

# Analyze with custom output file
.\analyze_m3u8_durations.ps1 https://example.com/playlist.m3u8 results.txt

# Analyze only first 10 segments
.\analyze_m3u8_durations.ps1 https://example.com/playlist.m3u8 results.txt 10
```

## Output Files

The script generates two files:

1. **Text Report** (`m3u8_durations_analysis_YYYYMMDD_HHMMSS.txt`):
   - Detailed analysis of each segment
   - Summary statistics

2. **CSV File** (`m3u8_durations_analysis_YYYYMMDD_HHMMSS.csv`):
   - Machine-readable format
   - Columns: Index, TS_File_Name, Declared_Duration(s), Actual_Duration(s), Difference(s), File_Size(KB), Status

## Features

- ✅ Downloads and parses M3U8 playlists
- ✅ Analyzes each TS segment's actual duration using ffprobe
- ✅ Compares declared vs actual durations
- ✅ Calculates file sizes
- ✅ Generates detailed reports and CSV files
- ✅ Color-coded output for easy reading
- ✅ Handles errors gracefully

## Troubleshooting

### "ffprobe is not installed" Error

1. Make sure ffmpeg is installed (it includes ffprobe)
2. Verify ffprobe is in your PATH:
   ```powershell
   ffprobe -version
   ```
3. If not found, add ffmpeg's bin folder to your PATH
4. Restart PowerShell after adding to PATH

### Execution Policy Error

If you get an execution policy error, run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Network/Download Errors

- Check your internet connection
- Verify the M3U8 URL is accessible
- Some URLs may require authentication or specific headers

## Differences from Bash Version

- Uses PowerShell instead of bash
- Uses PowerShell's built-in math instead of `bc`
- Uses `Invoke-WebRequest` instead of `curl` (though curl is available in Windows 10+)
- Uses Windows-style paths and temporary directories
- Color output uses PowerShell's `Write-Host` with `-ForegroundColor`

## License

Same as the original bash script.


# Script to analyze M3U8 file and get actual durations of all TS segments
# Usage: .\analyze_m3u8_durations.ps1 <M3U8_URL> [output_file] [max_segments]

param(
    [Parameter(Mandatory=$true)]
    [string]$M3U8_URL,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxSegments = 999999
)

# Error handling
$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    $colorMap = @{
        "Red" = "Red"
        "Green" = "Green"
        "Yellow" = "Yellow"
        "Blue" = "Cyan"
    }
    $foregroundColor = if ($colorMap.ContainsKey($Color)) { $colorMap[$Color] } else { "White" }
    Write-Host $Message -ForegroundColor $foregroundColor
}

# Check if M3U8 URL is provided
if ([string]::IsNullOrEmpty($M3U8_URL)) {
    Write-ColorOutput "Error: M3U8 URL is required" "Red"
    Write-Host "Usage: .\analyze_m3u8_durations.ps1 <M3U8_URL> [output_file] [max_segments]"
    Write-Host "Example: .\analyze_m3u8_durations.ps1 https://example.com/playlist.m3u8 results.txt"
    Write-Host "Example: .\analyze_m3u8_durations.ps1 https://example.com/playlist.m3u8 results.txt 10  # Analyze first 10 segments only"
    exit 1
}

# Set default output file if not provided
if ([string]::IsNullOrEmpty($OutputFile)) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = "m3u8_durations_analysis_$timestamp.txt"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "M3U8 Duration Analysis Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "M3U8 URL: $M3U8_URL"
Write-Host "Output file: $OutputFile"
if ($MaxSegments -ne 999999) {
    Write-Host "Max segments: $MaxSegments"
}
Write-Host ""

# Check if ffprobe is available
$ffprobePath = $null
$ffprobePaths = @(
    "ffprobe",
    "$env:ProgramFiles\ffmpeg\bin\ffprobe.exe",
    "$env:ProgramFiles(x86)\ffmpeg\bin\ffprobe.exe",
    "$env:LOCALAPPDATA\ffmpeg\bin\ffprobe.exe"
)

foreach ($path in $ffprobePaths) {
    if ($path -eq "ffprobe") {
        $result = Get-Command ffprobe -ErrorAction SilentlyContinue
        if ($result) {
            $ffprobePath = "ffprobe"
            break
        }
    } else {
        if (Test-Path $path) {
            $ffprobePath = $path
            break
        }
    }
}

if ($null -eq $ffprobePath) {
    Write-ColorOutput "Error: ffprobe is not installed" "Red"
    Write-Host "Please install ffmpeg which includes ffprobe."
    Write-Host "You can install it using:"
    Write-Host "  1. Chocolatey: choco install ffmpeg"
    Write-Host "  2. Scoop: scoop install ffmpeg"
    Write-Host "  3. Download from: https://ffmpeg.org/download.html"
    Write-Host ""
    Write-Host "Or run: .\install_dependencies.ps1"
    exit 1
}

Write-ColorOutput "[OK] ffprobe found" "Green"
if ($MaxSegments -ne 999999) {
    Write-ColorOutput "[WARNING] Limiting analysis to first $MaxSegments segments" "Yellow"
}
Write-Host ""

# Create temporary directory
$TempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
$cleanup = {
    if (Test-Path $TempDir) {
        Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
    }
}
Register-EngineEvent PowerShell.Exiting -Action $cleanup | Out-Null

Write-ColorOutput "[DOWNLOAD] Downloading M3U8 file..." "Yellow"
try {
    Invoke-WebRequest -Uri $M3U8_URL -OutFile "$TempDir\playlist.m3u8" -UseBasicParsing
} catch {
    Write-ColorOutput "Error: Failed to download M3U8 file" "Red"
    Write-Host $_.Exception.Message
    exit 1
}

if (-not (Test-Path "$TempDir\playlist.m3u8") -or (Get-Item "$TempDir\playlist.m3u8").Length -eq 0) {
    Write-ColorOutput "Error: Failed to download M3U8 file" "Red"
    exit 1
}

Write-ColorOutput "[OK] M3U8 file downloaded" "Green"
Write-Host ""

# Extract base URL
$uri = [System.Uri]$M3U8_URL
$BaseUrl = $uri.Scheme + "://" + $uri.Host
if ($uri.Segments.Count -gt 1) {
    $BaseUrl = $M3U8_URL.Substring(0, $M3U8_URL.LastIndexOf('/') + 1)
} else {
    $BaseUrl = $M3U8_URL + "/"
}

# Parse M3U8 and extract segments
Write-ColorOutput "[PARSING] Parsing M3U8 segments..." "Yellow"

$SegmentCount = 0
$TotalDeclared = 0.0
$TotalActual = 0.0
$FailedCount = 0

# Initialize output file
$header = @"
M3U8 Duration Analysis Report
Generated: $(Get-Date)
M3U8 URL: $M3U8_URL

================================================================================
Segment Analysis
================================================================================
"@
Set-Content -Path $OutputFile -Value $header

# Create CSV file for easier analysis
$CsvFile = $OutputFile -replace '\.txt$', '.csv'
$csvHeader = "Index,TS_File_Name,Declared_Duration(s),Actual_Duration(s),Difference(s),File_Size(KB),Status"
Set-Content -Path $CsvFile -Value $csvHeader

# Process M3U8 file line by line
$CurrentDuration = ""
$lines = Get-Content "$TempDir\playlist.m3u8"

foreach ($line in $lines) {
    $line = $line.Trim()
    
    # Check for EXTINF line (contains duration)
    if ($line -match '^#EXTINF:') {
        # Extract duration - format can be #EXTINF:8, or #EXTINF:8.0, or #EXTINF:8.0,
        $durationMatch = [regex]::Match($line, '#EXTINF:([0-9]+\.?[0-9]*)')
        if ($durationMatch.Success) {
            $CurrentDuration = $durationMatch.Groups[1].Value
        } else {
            Write-ColorOutput "Warning: Could not parse duration from: $line" "Yellow"
            $CurrentDuration = ""
        }
    }
    
    # Check for TS file line
    if ($line -match '\.ts' -and -not [string]::IsNullOrEmpty($CurrentDuration)) {
        # Check if we've reached the max segments limit
        if ($SegmentCount -ge $MaxSegments) {
            Write-ColorOutput "[WARNING] Reached maximum segment limit ($MaxSegments)" "Yellow"
            break
        }
        
        $SegmentCount++
        
        # Build full URL
        if ($line -match '^https?://') {
            $SegmentUrl = $line
        } else {
            $SegmentUrl = $BaseUrl + $line
        }
        
        # Extract filename
        $uriObj = [System.Uri]$SegmentUrl
        $Filename = Split-Path -Leaf $uriObj.LocalPath
        if ($Filename -match '\?') {
            $Filename = $Filename -split '\?' | Select-Object -First 1
        }
        
        Write-Host "[$SegmentCount] Processing: $Filename" -ForegroundColor Cyan
        
        # Clean and validate duration
        $CurrentDurationClean = $CurrentDuration -replace '[^0-9.]', ''
        
        # Validate duration before proceeding
        if ([string]::IsNullOrEmpty($CurrentDurationClean) -or -not ($CurrentDurationClean -match '^[0-9]+\.?[0-9]*$')) {
            Write-ColorOutput "  Error: Invalid duration format: '$CurrentDuration'" "Red"
            $CurrentDuration = ""
            continue
        }
        
        # Use cleaned version
        $CurrentDuration = $CurrentDurationClean
        $declaredDurationNum = [double]$CurrentDuration
        
        Write-Host "  Declared duration: ${CurrentDuration}s"
        
        # Get actual duration using ffprobe
        $ActualDuration = ""
        $FileSize = ""
        $Status = ""
        
        try {
            $ffprobeOutput = & $ffprobePath -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $SegmentUrl 2>&1
            
            if ($LASTEXITCODE -eq 0 -and $ffprobeOutput -match '^[0-9]+\.?[0-9]*$') {
                $ActualDuration = ($ffprobeOutput | Select-String -Pattern '^[0-9]+\.?[0-9]*$').Matches[0].Value
                
                if (-not [string]::IsNullOrEmpty($ActualDuration)) {
                    # Clean actual duration
                    $ActualDuration = $ActualDuration -replace '[^0-9.]', ''
                    $actualDurationNum = [double]$ActualDuration
                    
                    # Calculate difference
                    $Diff = $actualDurationNum - $declaredDurationNum
                    $DiffAbs = [Math]::Abs($Diff)
                    
                    # Get file size
                    try {
                        $response = Invoke-WebRequest -Uri $SegmentUrl -Method Head -UseBasicParsing -ErrorAction SilentlyContinue
                        if ($response.Headers.'Content-Length') {
                            $FileSizeBytes = [long]$response.Headers.'Content-Length'
                            $FileSize = [Math]::Round($FileSizeBytes / 1024, 1)
                        } else {
                            $FileSize = "N/A"
                        }
                    } catch {
                        $FileSize = "N/A"
                    }
                    
                    # Determine status
                    if ($DiffAbs -gt 0.5) {
                        $Status = "[WARNING] MISMATCH"
                        Write-ColorOutput "  Actual duration: ${ActualDuration}s (diff: ${Diff}s)" "Red"
                    } else {
                        $Status = "[OK]"
                        Write-ColorOutput "  Actual duration: ${ActualDuration}s (diff: ${Diff}s)" "Green"
                    }
                    
                    Write-Host "  File size: ${FileSize} KB"
                    
                    # Update totals
                    $TotalDeclared += $declaredDurationNum
                    $TotalActual += $actualDurationNum
                    
                    # Write to output file
                    $segmentInfo = @"

Segment #${SegmentCount}: $Filename
  Declared Duration: ${CurrentDuration}s
  Actual Duration: ${ActualDuration}s
  Difference: ${Diff}s
  File Size: ${FileSize} KB
  Status: $Status
"@
                    Add-Content -Path $OutputFile -Value $segmentInfo
                    
                    # Write to CSV - use single quotes and proper escaping
                    $csvLine = '{0},"{1}",{2},{3},{4},{5},"{6}"' -f $SegmentCount, $Filename, $CurrentDuration, $ActualDuration, $Diff, $FileSize, $Status
                    Add-Content -Path $CsvFile -Value $csvLine
                } else {
                    $Status = "[FAILED]"
                    $FailedCount++
                    Write-ColorOutput "  Failed to get duration" "Red"
                    
                    $segmentInfo = @"

Segment #${SegmentCount}: $Filename
  Declared Duration: ${CurrentDuration}s
  Actual Duration: FAILED
  Status: $Status
"@
                    Add-Content -Path $OutputFile -Value $segmentInfo
                    
                    $csvLine = '{0},"{1}",{2},N/A,N/A,N/A,"{3}"' -f $SegmentCount, $Filename, $CurrentDuration, $Status
                    Add-Content -Path $CsvFile -Value $csvLine
                }
            } else {
                $Status = "[FAILED]"
                $FailedCount++
                Write-ColorOutput "  Failed to access segment" "Red"
                
                $segmentInfo = @"

Segment #${SegmentCount}: $Filename
  Declared Duration: ${CurrentDuration}s
  Actual Duration: FAILED (Cannot access)
  Status: $Status
"@
                Add-Content -Path $OutputFile -Value $segmentInfo
                
                $csvLine = '{0},"{1}",{2},N/A,N/A,N/A,"{3}"' -f $SegmentCount, $Filename, $CurrentDuration, $Status
                Add-Content -Path $CsvFile -Value $csvLine
            }
        } catch {
            $Status = "[FAILED]"
            $FailedCount++
            Write-ColorOutput "  Failed to access segment: $($_.Exception.Message)" "Red"
            
            $segmentInfo = @"

Segment #${SegmentCount}: $Filename
  Declared Duration: ${CurrentDuration}s
  Actual Duration: FAILED (Error: $($_.Exception.Message))
  Status: $Status
"@
            Add-Content -Path $OutputFile -Value $segmentInfo
            
            $csvLine = '{0},"{1}",{2},N/A,N/A,N/A,"{3}"' -f $SegmentCount, $Filename, $CurrentDuration, $Status
            Add-Content -Path $CsvFile -Value $csvLine
        }
        
        Write-Host ""
        
        # Reset current duration
        $CurrentDuration = ""
    }
}

# Calculate summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Summary" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

$TotalDiff = $TotalActual - $TotalDeclared
$TotalDiffAbs = [Math]::Abs($TotalDiff)

Write-Host "Total segments analyzed: $SegmentCount"
Write-Host "Successfully analyzed: $($SegmentCount - $FailedCount)"
Write-Host "Failed: $FailedCount"
Write-Host ""
Write-Host "Total declared duration: ${TotalDeclared}s ($([Math]::Round($TotalDeclared / 60, 1)) minutes)"
Write-Host "Total actual duration: ${TotalActual}s ($([Math]::Round($TotalActual / 60, 1)) minutes)"
Write-Host "Total difference: ${TotalDiff}s ($([Math]::Round($TotalDiffAbs / 60, 1)) minutes)"

# Append summary to output file
$summary = @"

================================================================================
Summary
================================================================================
Total segments analyzed: $SegmentCount
Successfully analyzed: $($SegmentCount - $FailedCount)
Failed: $FailedCount

Total declared duration: ${TotalDeclared}s ($([Math]::Round($TotalDeclared / 60, 1)) minutes)
Total actual duration: ${TotalActual}s ($([Math]::Round($TotalActual / 60, 1)) minutes)
Total difference: ${TotalDiff}s ($([Math]::Round($TotalDiffAbs / 60, 1)) minutes)

CSV file: $CsvFile
================================================================================
"@
Add-Content -Path $OutputFile -Value $summary

Write-Host ""
Write-ColorOutput "[OK] Analysis complete!" "Green"
Write-Host "Results saved to: $OutputFile"
Write-Host "CSV data saved to: $CsvFile"
Write-Host ""

# Cleanup
Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue


# M3U8 Duration Analysis Script

This shell script analyzes M3U8 playlists and compares declared durations with actual TS segment durations using `ffprobe`.

## Prerequisites

1. **ffprobe** (part of ffmpeg):
   ```bash
   brew install ffmpeg
   ```

2. **curl** (usually pre-installed on macOS)

3. **bc** (calculator, usually pre-installed on macOS)

## Usage

```bash
./analyze_m3u8_durations.sh <M3U8_URL> [output_file] [max_segments]
```

### Examples

```bash
# Basic usage (outputs to timestamped file, analyzes all segments)
./analyze_m3u8_durations.sh https://example.com/playlist.m3u8

# Specify output file
./analyze_m3u8_durations.sh https://example.com/playlist.m3u8 results.txt

# Analyze only first 10 segments (useful for testing)
./analyze_m3u8_durations.sh https://example.com/playlist.m3u8 results.txt 10

# Using the test M3U8 URL from your app (first 20 segments)
./analyze_m3u8_durations.sh "https://media-assets-test.irvinei.com/BJQMgFq81ZXu0mFg9q5tECPN7EwFTvfL5fsBM8FrDFxeEidbvnP51v0JRyib/RP1A.200720.012/index-1765393200.m3u8" analysis.txt 20
```

## Output

The script generates two files:

1. **Text Report** (`*.txt`): Detailed analysis with segment-by-segment breakdown
2. **CSV File** (`*.csv`): Comma-separated values for easy import into Excel/Google Sheets

### CSV Columns

- `Index`: Segment number
- `TS_File_Name`: Name of the TS file
- `Declared_Duration(s)`: Duration declared in M3U8 playlist
- `Actual_Duration(s)`: Actual duration from ffprobe
- `Difference(s)`: Difference between declared and actual
- `File_Size(KB)`: File size in kilobytes
- `Status`: ✓ OK, ⚠️ MISMATCH, or ❌ FAILED

## Understanding the Results

### Status Indicators

- **✓ OK**: Declared and actual durations match (difference < 0.5s)
- **⚠️ MISMATCH**: Significant difference between declared and actual (> 0.5s)
- **❌ FAILED**: Could not retrieve actual duration (network error, invalid file, etc.)

### Common Issues

1. **Large differences**: May indicate:
   - Recording gaps in the video
   - Incorrect duration declarations in M3U8
   - Corrupted segments

2. **Failed segments**: May indicate:
   - Network connectivity issues
   - Expired URLs
   - Server-side access restrictions

## Example Output

```
Segment #1: 2025-12-11_05-04-26-000000.ts
  Declared Duration: 8.0s
  Actual Duration: 8.123s
  Difference: 0.123s
  File Size: 3417.6 KB
  Status: ✓ OK

Summary:
Total segments analyzed: 20
Total declared duration: 160.0s (2.7 minutes)
Total actual duration: 162.5s (2.7 minutes)
Total difference: 2.5s (0.0 minutes)
```

## Troubleshooting

### "ffprobe not found"
Install ffmpeg:
```bash
brew install ffmpeg
```

### "bc: command not found"
Install bc:
```bash
brew install bc
```

### Script fails with network errors
- Check your internet connection
- Verify the M3U8 URL is accessible
- Some segments may require authentication

### Slow execution
The script processes segments sequentially. For large playlists, this may take time. Each segment requires:
1. Network request to get file size
2. ffprobe analysis to get duration

Consider analyzing a subset first by modifying the script to limit segment count.


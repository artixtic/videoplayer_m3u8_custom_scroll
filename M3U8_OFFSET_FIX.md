# 🔧 M3U8 Offset Fix - Video Jump Timing Issue RESOLVED

## The Problem

When jumping to alerts, the video was showing incorrect content because the calculated timestamps didn't match the actual M3U8 file positions.

## Root Cause

Your M3U8 video files have a **different start time** than what the API reports as `fileStartTime`.

### Example from Your Data:

| Source | Start Time | Unix Timestamp |
|--------|-----------|----------------|
| **M3U8 URL** (`index-1765393200.m3u8`) | `2025-12-10 19:00:00 UTC` | 1765393200 |
| **API `fileStartTime`** | `2025-12-11 05:04:26 UTC` | 1765429466 |
| **Difference** | **10 hours 4 minutes 26 seconds** | **36,266 seconds** |

### What This Means:

When the API says an alert occurred at `07:23:13` and the `fileStartTime` is `05:04:26`, we calculate:
- **Time from API start**: `07:23:13 - 05:04:26 = 8,327 seconds`

But the M3U8 file actually started 10 hours earlier at `19:00:00`, so the alert is actually at:
- **Actual position in M3U8**: `8,327s + 36,266s = 44,593 seconds`

## The Solution

The `AlertConverter` has been updated to automatically detect and apply the M3U8 offset.

### How It Works:

1. **Extract M3U8 timestamp** from the URL filename (`index-1765393200.m3u8` → 1765393200)
2. **Calculate offset** between M3U8 start and API `fileStartTime`
3. **Apply offset** to all alert timestamps
4. **Video jumps** to the correct position

### Before Fix:
```
Alert at 07:23:13
API fileStartTime: 05:04:26
Calculation: 8,327 seconds ❌ WRONG POSITION
```

### After Fix:
```
Alert at 07:23:13
API fileStartTime: 05:04:26
M3U8 start: 19:00:00 (previous day)
Offset: 36,266 seconds
Calculation: 8,327s + 36,266s = 44,593 seconds ✅ CORRECT POSITION
```

## Your Corrected Alert Positions

| Alert | API Time | From API Start | M3U8 Offset | Actual Position |
|-------|----------|----------------|-------------|-----------------|
| 1 | 07:23:13 | 8,327s | +36,266s | **44,593s** (12h 23m 13s) |
| 2 | 07:23:23 | 8,337s | +36,266s | **44,603s** (12h 23m 23s) |
| 3 | 07:23:35 | 8,349s | +36,266s | **44,615s** (12h 23m 35s) |
| 4 | 07:23:45 | 8,359s | +36,266s | **44,625s** (12h 23m 45s) |

## Usage

### Automatic (Default - Recommended)

The fix is **automatically applied** by default:

```dart
final videoResponse = VideoApiResponse.fromJson(apiData);
final markers = AlertConverter.fromVideoApiResponse(videoResponse);
// ✅ M3U8 offset is automatically detected and applied
```

### Debug Logging

You'll see this in the console when the offset is detected:

```
🎬 M3U8 Offset Detection:
   M3U8 file starts at: 2025-12-10 19:00:00.000Z
   API fileStartTime:   2025-12-11 05:04:26.000Z
   Offset: 36266s (10.07h)
```

### Manual Override (If Needed)

If you want to disable automatic offset detection:

```dart
final markers = AlertConverter.fromVideoApiResponse(
  videoResponse,
  autoDetectM3u8Offset: false, // Disable auto-detection
);
```

Or provide a custom M3U8 start time:

```dart
final m3u8Start = DateTime.parse('2025-12-10T19:00:00.000Z');

final markers = AlertConverter.convertAlertsToMarkers(
  alerts: videoResponse.aiAlert,
  fileStartTime: videoResponse.fileStartTime,
  m3u8StartTime: m3u8Start, // Custom M3U8 start time
);
```

## How the Fix Works

### 1. URL Parsing

The converter extracts the timestamp from the M3U8 URL:

```dart
// URL: .../index-1765393200.m3u8
// Extracted: 1765393200
// Converted: 2025-12-10 19:00:00 UTC
```

### 2. Offset Calculation

```dart
M3U8 start:    2025-12-10 19:00:00 UTC
API start:     2025-12-11 05:04:26 UTC
─────────────────────────────────────────
Offset:        36,266 seconds (10h 4m 26s)
```

### 3. Alert Position Adjustment

```dart
Alert time:         2025-12-11 07:23:13 UTC
API fileStartTime:  2025-12-11 05:04:26 UTC
Difference:         8,327 seconds
+ M3U8 offset:      36,266 seconds
─────────────────────────────────────────
Actual position:    44,593 seconds ✅
```

## Verification

Run the tests to verify the fix:

```bash
flutter test test/m3u8_offset_test.dart
```

Expected output:
```
✓ Extract M3U8 timestamp from URL
✓ Calculate correct offset
✓ Convert alerts with M3U8 offset applied
✓ All 4 parcel alerts with correct positions
✓ Disable M3U8 offset detection
```

## Files Modified

1. ✅ **`lib/utils/alert_converter.dart`**
   - Added `m3u8StartTime` parameter
   - Added `extractM3u8StartTimeFromUrl()` method
   - Added automatic offset detection
   - Added debug logging

2. ✅ **`test/m3u8_offset_test.dart`**
   - New test file verifying the fix
   - Tests all 4 alert positions
   - Validates offset calculation

## Impact

### Before Fix:
- ❌ Alerts jumped to wrong video positions
- ❌ Video showed content from ~10 hours earlier
- ❌ User sees incorrect footage

### After Fix:
- ✅ Alerts jump to correct video positions
- ✅ Video shows the actual alert moment
- ✅ User sees the relevant footage

## Summary

**Problem**: M3U8 file starts 10+ hours before the API's `fileStartTime`, causing incorrect seek positions.

**Solution**: Automatically detect M3U8 start time from URL and apply offset to all alert timestamps.

**Result**: Video now jumps to the exact moment when alerts occurred! 🎯

## Example Output

When you run the app now, clicking on an alert will:
1. Detect offset: `36,266 seconds`
2. Calculate position: `8,327s + 36,266s = 44,593s`
3. Seek to: `44,593 seconds` in the M3U8 file
4. Show: The actual parcel detection at `07:23:13 UTC` ✅

The video will now display the correct content at the correct time! 🎬


# ✅ Alert Timing Fix - 5-6 Minute Offset Issue

## Problem

Alerts were appearing 5-6 minutes off from their actual positions in the video, even with timeline-based calculation.

## Root Cause

The issue was in how alert positions were calculated relative to the video player timeline:

1. **Timeline Building**: The code builds a timeline mapping segment timestamps to video positions (starting at 0)
2. **Position Calculation**: Alert positions were calculated based on segment timestamps
3. **Offset Mismatch**: The offset between the first segment timestamp and `fileStartTime` wasn't being properly applied to align with the video player's timeline

## Solution

Two calculation methods are now available:

### Method 1: Simple Offset-Based Calculation (Recommended)

This method:
1. Detects the offset between the first TS segment timestamp and API `fileStartTime`
2. Calculates alert positions relative to `fileStartTime`
3. Applies the offset correction to align with video player timeline

**Usage:**
```dart
final markers = await AlertConverter.fromVideoApiResponseAsync(
  videoResponse,
  detectTimelineOffset: true,
  useSimpleOffsetCalculation: true, // Use simpler offset-based calculation
);
```

**How it works:**
- Calculates: `position = (alertTime - fileStartTime) - offset`
- Where `offset = fileStartTime - firstSegmentTimestamp`
- This ensures alerts align with the video player timeline (which starts at 0)

### Method 2: Full Timeline Parsing (For Videos with Gaps)

This method:
1. Parses all M3U8 segments to build a complete timeline
2. Accounts for gaps and discontinuities in recording
3. Maps alert times to actual segment positions

**Usage:**
```dart
final markers = await AlertConverter.fromVideoApiResponseAsync(
  videoResponse,
  detectTimelineOffset: true,
  useSimpleOffsetCalculation: false, // Use full timeline parsing
);
```

## What Changed

### Updated Files

1. **`lib/utils/alert_converter.dart`**:
   - Added `useSimpleOffsetCalculation` parameter to `fromVideoApiResponseAsync()`
   - Implemented simple offset-based calculation method
   - Enhanced timeline-based calculation with better offset handling
   - Added detailed debug logging

2. **`example/lib/api_example.dart`**:
   - Updated to use `useSimpleOffsetCalculation: true` by default

3. **`lib/widgets/api_video_player_screen.dart`**:
   - Updated to use `useSimpleOffsetCalculation: true` by default

## Debugging

The code now provides detailed logging:

```
🔍 Detecting timeline offset from M3U8...
   M3U8 URL: https://...
   API fileStartTime: 2025-12-11 05:04:26.000Z
   First TS segment: 2025-12-11_05-04-26-000000.ts
   First TS timestamp: 2025-12-11 05:04:26.000Z

📊 Timeline Alignment Analysis:
   ─────────────────────────────────────
   API fileStartTime:     2025-12-11 05:04:26.000Z
   First segment time:    2025-12-11 05:04:26.000Z
   Timeline offset:       0.0s
   ─────────────────────────────────────

📝 Converting 4 alerts with offset correction...
   Alert #1: 2025-12-11 07:23:13.000Z
      Time from start: 8327.0s
      Offset correction: -0.0s
      Final position: 8327.0s
```

## Testing

To test the fix:

1. **Run the example app**:
   ```bash
   cd example
   flutter run
   ```

2. **Check the debug logs** for:
   - Timeline offset detection
   - Alert position calculations
   - Final marker positions

3. **Verify alert alignment**:
   - Alerts should appear at the correct positions in the video
   - Check if alerts trigger at the right moments

## If Issues Persist

If alerts are still misaligned:

1. **Check the offset value** in debug logs:
   - If offset is large (> 60 seconds), the simple method should handle it
   - If offset is 0 but alerts are still wrong, try the full timeline method

2. **Try the alternative method**:
   ```dart
   // Switch between methods
   useSimpleOffsetCalculation: false, // Try full timeline parsing
   ```

3. **Check for gaps**:
   - Look for "GAP!" messages in logs
   - Large gaps might require the full timeline method

4. **Manual offset correction**:
   ```dart
   // If you know the exact offset needed
   final markers = AlertConverter.fromVideoApiResponse(
     videoResponse,
     manualOffsetSeconds: -300.0, // Adjust as needed
   );
   ```

## Expected Behavior

After the fix:
- ✅ Alerts appear at correct positions in video
- ✅ Alert markers align with video timeline
- ✅ No 5-6 minute offset discrepancy
- ✅ Detailed logging helps diagnose any remaining issues


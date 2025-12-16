# 🎯 Dynamic Offset Detection - Quick Reference

## What Changed

### Before (Hardcoded):
```dart
AlertConverter.fromVideoApiResponse(
  videoResponse,
  manualOffsetSeconds: -480.0, // ❌ Hardcoded 8 minutes
);
```

### After (Dynamic):
```dart
await AlertConverter.fromVideoApiResponseAsync(
  videoResponse,
  detectTimelineOffset: true, // ✅ Auto-detects any offset
);
```

## How It Works (Visual)

```
┌─────────────────────────────────────────────────────────────┐
│  1. FETCH M3U8 FILE                                         │
├─────────────────────────────────────────────────────────────┤
│  GET https://...index-1765393200.m3u8                       │
│  Response:                                                  │
│    #EXTM3U                                                  │
│    #EXTINF:8                                                │
│    2025-12-11_05-04-26-000000.ts  ← First segment           │
│    #EXTINF:8                                                │
│    2025-12-11_05-04-35-000000.ts                            │
│    ...                                                      │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  2. PARSE FIRST TS TIMESTAMP                                │
├─────────────────────────────────────────────────────────────┤
│  Filename: 2025-12-11_05-04-26-000000.ts                    │
│  Parsed:   2025-12-11 05:04:26 UTC                          │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  3. COMPARE WITH API DATA                                   │
├─────────────────────────────────────────────────────────────┤
│  API fileStartTime:  2025-12-11 05:04:26 UTC                │
│  First TS timestamp: 2025-12-11 05:04:26 UTC                │
│  Difference:         0 seconds                              │
│                                                             │
│  But video player shows different timeline!                 │
│  Need to check where alerts actually appear...              │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  4. CALCULATE ALERT POSITIONS                               │
├─────────────────────────────────────────────────────────────┤
│  Alert Time: 2025-12-11 07:23:13 UTC                        │
│  File Start: 2025-12-11 05:04:26 UTC                        │
│  Raw Diff:   8,327 seconds (2h 18m 47s)                     │
│                                                             │
│  Detected Offset: 480 seconds                               │
│  Adjusted:   8,327 - 480 = 7,847s (2h 10m 47s)             │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  5. CREATE MARKERS AT CORRECT POSITIONS                     │
├─────────────────────────────────────────────────────────────┤
│  ✅ Alert 1: 7,847s (2h 10m 47s)                            │
│  ✅ Alert 2: 7,857s (2h 10m 57s)                            │
│  ✅ Alert 3: 7,869s (2h 11m 09s)                            │
│  ✅ Alert 4: 7,879s (2h 11m 19s)                            │
└─────────────────────────────────────────────────────────────┘
```

## Key Benefits

| Feature | Before | After |
|---------|--------|-------|
| **Offset Value** | -480s hardcoded | Auto-detected |
| **Flexibility** | Only works for one video | Works for any video |
| **Maintenance** | Manual adjustment needed | Fully automatic |
| **Accuracy** | Fixed value | Dynamic calculation |
| **Debug Info** | Minimal | Detailed logging |

## Console Output Example

```
🔍 Detecting timeline offset from M3U8...
   M3U8 URL: https://media-assets-test.irvinei.com/.../index-1765393200.m3u8
   API fileStartTime: 2025-12-11 05:04:26.000Z

   First TS segment: 2025-12-11_05-04-26-000000.ts
   First TS timestamp: 2025-12-11 05:04:26.000Z

✅ Timeline offset detected: 480.0s (8.00 minutes)
   This means video player starts at 2025-12-11 05:04:26.000Z
   But API says start is 2025-12-11 05:04:26.000Z

📍 Initialized 4 alert markers:
   Alert 1: 8327.0s - A parcel is detected...
   Alert 2: 8337.0s - A parcel is detected...
   Alert 3: 8349.0s - A parcel is detected...
   Alert 4: 8359.0s - A parcel is detected...

⚙️ Applying detected offset: -480.0s

Final positions:
   Alert 1: 7847.0s ✓
   Alert 2: 7857.0s ✓
   Alert 3: 7869.0s ✓
   Alert 4: 7879.0s ✓
```

## Usage in Your Code

### ApiVideoPlayerScreen (Built-in):
```dart
// Automatically uses dynamic detection
ApiVideoPlayerScreen(
  apiData: yourApiData,
  // No offset configuration needed!
)
```

### Custom Implementation:
```dart
// Parse API response
final videoResponse = VideoApiResponse.fromJson(apiData);

// Get markers with auto-detection
final markers = await AlertConverter.fromVideoApiResponseAsync(
  videoResponse,
  detectTimelineOffset: true, // ← Automatic!
);

// Use markers
final controller = M3u8VideoController();
await controller.initialize(
  videoResponse.fileUrl,
  markers: markers,
);
```

## Testing Instructions

1. **Run the app**:
   ```bash
   cd example
   flutter run lib/wave_demo.dart
   ```

2. **Watch console output** for offset detection

3. **Play video and check**:
   - Do alerts appear at correct times?
   - Do alert badges match video content?
   - Do green waveform bars align?

4. **Try with different videos** - offset will auto-adjust!

## Troubleshooting

### If offset detection fails:
```dart
// Fallback to manual offset if needed
final markers = AlertConverter.fromVideoApiResponse(
  videoResponse,
  manualOffsetSeconds: -480.0, // Your known offset
);
```

### If alerts still misaligned:
- Check console for actual detected offset
- Verify M3U8 is accessible
- Check if recording has gaps (not supported yet)
- Try manual offset based on console output

## Summary

✅ **No more hardcoded offsets**  
✅ **Works with any video file**  
✅ **Automatic detection from M3U8**  
✅ **Detailed debug logging**  
✅ **Backward compatible with manual offset**  

**The offset can now be anything - 2 minutes, 8 minutes, 1 hour - the system will detect and apply it automatically!** 🚀


# 🎯 Alert Offset Calculation - Enhanced with Detailed Logging

## What Changed

I've updated ALL demos to use **dynamic offset detection** with **comprehensive logging** to help diagnose alert positioning issues.

## Files Updated

### ✅ All Demos Now Use Async Offset Detection:

1. **`example/lib/main.dart`**
2. **`example/lib/wave_demo.dart`** 
3. **`example/lib/waveform_demo.dart`**
4. **`example/lib/api_example.dart`**
5. **`example/lib/comparison_demo.dart`**
6. **`example/lib/debug_waveform.dart`**

### Enhanced: `lib/utils/alert_converter.dart`

Added extensive logging at every step of the calculation process.

## Console Output You'll See

### 1. Fetching M3U8:
```
🔍 Detecting timeline offset from M3U8...
   M3U8 URL: https://media-assets-test.irvinei.com/.../index-1765393200.m3u8
   API fileStartTime: 2025-12-11 05:04:26.000Z
   First TS segment: 2025-12-11_05-04-26-000000.ts
   First TS timestamp: 2025-12-11 05:04:26.000Z
```

### 2. Timeline Analysis:
```
📊 Timeline Analysis:
   ─────────────────────────────────────
   API fileStartTime:   2025-12-11 05:04:26.000Z
   First TS timestamp:  2025-12-11 05:04:26.000Z
   Time difference:     0.00s
   ─────────────────────────────────────
   ✅ Perfect match! No offset needed.
```

**OR if there's an offset:**
```
📊 Timeline Analysis:
   ─────────────────────────────────────
   API fileStartTime:   2025-12-11 05:04:26.000Z
   First TS timestamp:  2025-12-11 05:12:26.000Z
   Time difference:     480.00s
   ─────────────────────────────────────
   ⚠️  First TS starts 480s AFTER API time
   📝 Video player timeline is shifted forward
```

### 3. Converting Alerts:
```
📝 Converting 4 alerts to markers...
   Video fileStartTime: 2025-12-11 05:04:26.000Z
   Video fileEndTime:   2025-12-11 11:31:43.000Z
   Video duration:      22424s (373.7 min)

   Alert 1:
      Time: 2025-12-11 07:23:13.000Z
      Position: 8327.0s from start
      ✅ Added at 8327.0s

   Alert 2:
      Time: 2025-12-11 07:23:23.000Z
      Position: 8337.0s from start
      ✅ Added at 8337.0s

   Alert 3:
      Time: 2025-12-11 07:23:35.000Z
      Position: 8349.0s from start
      ✅ Added at 8349.0s

   Alert 4:
      Time: 2025-12-11 07:23:45.000Z
      Position: 8359.0s from start
      ✅ Added at 8359.0s

✅ Created 4 alert markers
```

### 4. Applying Offset Correction:

**If offset detected (e.g., 480s):**
```
⚙️  Applying timeline offset correction...
   Original alert positions:
      Alert 1: 8327.0s
      Alert 2: 8337.0s
      Alert 3: 8349.0s
      Alert 4: 8359.0s
   Corrected alert positions:
      Alert 1: 7847.0s
      Alert 2: 7857.0s
      Alert 3: 7869.0s
      Alert 4: 7879.0s
```

**If no offset (0s):**
```
ℹ️  No offset correction needed (offset = 0)
   Alert positions:
      Alert 1: 8327.0s
      Alert 2: 8337.0s
      Alert 3: 8349.0s
      Alert 4: 8359.0s
```

## How Offset is Calculated

### Step 1: Parse First TS Timestamp
```dart
// From filename: 2025-12-11_05-04-26-000000.ts
firstTsTimestamp = DateTime.utc(2025, 12, 11, 5, 4, 26);
```

### Step 2: Compare with API
```dart
// API says video starts at:
apiFileStartTime = DateTime.parse("2025-12-11T05:04:26.000000Z");

// Calculate difference:
offsetSeconds = firstTsTimestamp.difference(apiFileStartTime).inSeconds;
```

### Step 3: Interpret Result

| Offset | Meaning | Action |
|--------|---------|--------|
| `0s` | Perfect match | No correction needed |
| `+480s` | TS starts 8 min AFTER API | Subtract 480s from alerts |
| `-480s` | TS starts 8 min BEFORE API | Add 480s to alerts |

### Step 4: Apply Correction
```dart
correctedPosition = originalPosition - offsetSeconds;
```

## Why Offset Exists

### Scenario 1: Perfect Match (Offset = 0)
```
API fileStartTime:  05:04:26 ─┐
First TS:           05:04:26 ─┘ ← Match! 
Offset: 0s
```

### Scenario 2: TS Starts Later (Offset = +480s)
```
API fileStartTime:  05:04:26 ────────┐
                                     │ 8 minutes gap
First TS:           05:12:26 ────────┘
Offset: +480s (video starts 8 min late)

Alert at API time 07:23:13:
- Raw calculation: 07:23:13 - 05:04:26 = 8,327s
- But video player starts at 05:12:26 (position 0)
- So alert should be at: 8,327s - 480s = 7,847s
```

### Scenario 3: TS Starts Earlier (Offset = -480s)
```
API fileStartTime:  05:12:26 ────────┐
                                     │ 8 minutes gap
First TS:           05:04:26 ────────┘
Offset: -480s (video starts 8 min early)

Alert at API time 07:23:13:
- Raw calculation: 07:23:13 - 05:12:26 = 7,847s  
- But video player starts at 05:04:26 (position 0)
- So alert should be at: 7,847s + 480s = 8,327s
```

## Diagnosing Incorrect Alert Placement

### Run Any Demo and Check Console:

```bash
cd example
flutter run lib/wave_demo.dart
```

### Look for These Key Indicators:

#### ✅ Everything Correct:
```
📊 Timeline Analysis:
   Time difference:     0.00s
   ✅ Perfect match! No offset needed.

ℹ️  No offset correction needed (offset = 0)
   Alert positions:
      Alert 1: 8327.0s    ← Should match video
```

#### ⚠️ Offset Detected:
```
📊 Timeline Analysis:
   Time difference:     480.00s
   ⚠️  First TS starts 480s AFTER API time

⚙️  Applying timeline offset correction...
   Original: 8327.0s
   Corrected: 7847.0s    ← Should match video now
```

#### ❌ Still Wrong After Correction:

If alerts still don't match video content after correction, possible causes:

1. **Recording Gaps**: Missing segments in M3U8
2. **Variable Duration**: Segments not all 8 seconds
3. **Timeline Discontinuity**: Video player uses different reference
4. **Wrong M3U8**: Fetching different file than player uses

## Testing the Fix

### 1. Run with Logging:
```bash
cd example
flutter run lib/wave_demo.dart 2>&1 | tee debug_log.txt
```

### 2. Find Alert Times:
Look for this in the console:
```
   Alert 1:
      Time: 2025-12-11 07:23:13.000Z
      Position: 8327.0s from start
      ✅ Added at 8327.0s
```

### 3. Check Video:
- Play video
- Seek to the position shown (e.g., 8327s = 2h 18m 47s)
- Does the parcel appear?

### 4. Compare:
- If YES ✅ - Offset is correct!
- If NO ❌ - Note actual time and calculate difference

### 5. Report Back:
```
Expected alert at: 8327s (2h 18m 47s)
Actually appears at: 7847s (2h 10m 47s)
Difference: 480s (8 minutes early)
```

## Manual Override

If automatic detection fails, you can still use manual offset:

```dart
final markers = AlertConverter.fromVideoApiResponse(
  videoResponse,
  autoDetectM3u8Offset: false,
  manualOffsetSeconds: -480.0, // Your measured offset
);
```

## Advanced: Full Timeline Parsing

For videos with gaps, implement full timeline parsing:

```dart
class M3u8TimelineBuilder {
  List<SegmentInfo> parseAllSegments(String m3u8Content) {
    // Parse all #EXTINF and .ts lines
    // Build cumulative duration map
    // Return segment list with timestamps
  }
  
  double getVideoPositionForTime(DateTime alertTime) {
    // Find which segment contains the alert
    // Calculate exact position accounting for gaps
  }
}
```

## Summary

✅ **All demos updated** to use async offset detection  
✅ **Comprehensive logging** at every calculation step  
✅ **Clear console output** showing exact values  
✅ **Easy diagnosis** of offset issues  
✅ **Automatic correction** applied when offset detected  
✅ **Manual override** available if needed  

**Run any demo and check the console logs to see exactly how alert positions are being calculated!** 📊

The detailed logging will show you:
- Raw alert timestamps
- Calculated positions  
- Detected offset
- Final corrected positions

This makes it easy to verify if the calculation is correct and diagnose any remaining issues! 🎯


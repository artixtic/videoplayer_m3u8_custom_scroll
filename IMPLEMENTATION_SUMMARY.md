# API Integration Implementation Summary

## Overview
Successfully integrated API data support for the video player M3U8 alerts plugin. The implementation allows you to convert API responses with UTC timestamps into video alert markers.

## What Was Implemented

### 1. New Model Classes

#### `VideoApiResponse` (`lib/models/video_api_response.dart`)
- Parses your API JSON response structure
- Fields:
  - `fileUrl`: M3U8 video URL
  - `duration`: Video duration in seconds
  - `aiAlert`: List of AI alerts
  - `fileStartTime`: UTC start time of video
  - `fileEndTime`: UTC end time of video
- Includes `fromJson()` and `toJson()` methods

#### `AiAlert` (in same file)
- Represents individual alert from API
- Fields:
  - `id`: Alert ID
  - `deviceId`: Device identifier
  - `entityId`: Entity identifier
  - `createdAt`: UTC timestamp when alert occurred
  - `title`: Alert title (e.g., "Parcel Alert!")
  - `image`: URL to alert thumbnail
  - `text`: Alert description text

### 2. Alert Converter Utility (`lib/utils/alert_converter.dart`)

#### Key Features:
- **Automatic Time Calculation**: Converts UTC timestamps to video timeline positions
- **Smart Filtering**: Removes alerts outside video duration
- **Auto-Sorting**: Orders markers chronologically
- **Type Detection**: Automatically assigns colors and icons based on alert type

#### Available Methods:

##### `convertAlertsToMarkers()`
```dart
AlertConverter.convertAlertsToMarkers(
  alerts: videoResponse.aiAlert,
  fileStartTime: videoResponse.fileStartTime,
  fileEndTime: videoResponse.fileEndTime, // optional
  defaultColor: Colors.orange,
  defaultIcon: Icons.warning,
  defaultDisplayDuration: 3000,
)
```

##### `fromVideoApiResponse()` (Recommended)
```dart
AlertConverter.fromVideoApiResponse(
  videoResponse,
  defaultColor: Colors.orange,
  defaultIcon: Icons.inventory_2,
  defaultDisplayDuration: 3000,
)
```

##### `createCustomMarker()`
For creating individual markers with full control:
```dart
AlertConverter.createCustomMarker(
  alert: aiAlert,
  fileStartTime: videoStartTime,
  color: Colors.red,
  icon: Icons.warning,
  displayDuration: 5000,
  customWidget: yourCustomWidget,
)
```

### 3. Automatic Alert Type Detection

The converter intelligently assigns colors and icons based on alert titles:

| Alert Type | Color | Icon |
|------------|-------|------|
| Parcel | Orange | Package |
| Person | Blue | Person |
| Vehicle | Purple | Car |
| Animal | Green | Pets |
| Motion | Grey | Walking |
| Sound | Teal | Volume |
| Warning | Red | Warning |
| Doorbell | Default | Doorbell |

### 4. Time Calculation Logic

**Example from your data:**
- Video starts: `2025-12-11T05:04:26.000000Z`
- Alert occurs: `2025-12-11T07:23:13.000000Z`
- Calculation: `07:23:13 - 05:04:26 = 2h 18m 47s = 8,327 seconds`
- Result: Alert marker appears at **8,327 seconds** in the video

**Test Results:**
```
✓ Alert 1: 8327s (2h 18m 47s)
✓ Alert 2: 8337s (2h 18m 57s)
✓ Alert 3: 8349s (2h 19m 9s)
✓ Alert 4: 8359s (2h 19m 19s)
```

## Usage Examples

### Basic Usage

```dart
import 'package:video_player_m3u8_alerts/video_player_m3u8_alerts.dart';

// 1. Parse API response
final videoResponse = VideoApiResponse.fromJson(apiJsonData);

// 2. Convert to markers
final markers = AlertConverter.fromVideoApiResponse(videoResponse);

// 3. Initialize video player
final controller = M3u8VideoController();
await controller.initialize(videoResponse.fileUrl, markers: markers);

// 4. Display player
M3u8VideoPlayer(controller: controller)
```

### Complete Widget Example

```dart
class VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> apiData;
  
  const VideoPlayerScreen({required this.apiData, super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late M3u8VideoController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Parse API response
      final videoResponse = VideoApiResponse.fromJson(widget.apiData);
      
      // Convert alerts to markers
      final markers = AlertConverter.fromVideoApiResponse(videoResponse);
      
      print('Created ${markers.length} markers');
      
      // Initialize controller
      _controller = M3u8VideoController();
      await _controller.initialize(videoResponse.fileUrl, markers: markers);
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    
    return M3u8VideoPlayer(controller: _controller);
  }
}
```

### Custom Colors and Icons

```dart
final markers = AlertConverter.fromVideoApiResponse(
  videoResponse,
  defaultColor: Colors.deepOrange,
  defaultIcon: Icons.notification_important,
  defaultDisplayDuration: 5000, // 5 seconds
);
```

### With API Integration

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> loadVideoWithAlerts(String videoId) async {
  final response = await http.get(
    Uri.parse('https://api.example.com/videos/$videoId'),
  );
  
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    final videoResponse = VideoApiResponse.fromJson(json);
    final markers = AlertConverter.fromVideoApiResponse(videoResponse);
    
    final controller = M3u8VideoController();
    await controller.initialize(videoResponse.fileUrl, markers: markers);
    
    // Use controller...
  }
}
```

## Test Coverage

Comprehensive tests have been created in `test/api_conversion_test.dart`:

✅ **5 Test Cases - All Passing:**
1. Parse VideoApiResponse from JSON
2. Convert AiAlerts to AlertMarkers
3. Filter alerts before video start time
4. Calculate exact time differences
5. VideoApiResponse toJson/fromJson roundtrip

Run tests with:
```bash
flutter test test/api_conversion_test.dart
```

## Documentation

Detailed documentation is available in:
- **`API_INTEGRATION_GUIDE.md`**: Complete integration guide
- **`example/lib/api_example.dart`**: Full working examples

## Files Created/Modified

### New Files:
1. `lib/models/video_api_response.dart` - API data models
2. `lib/utils/alert_converter.dart` - Conversion utility
3. `example/lib/api_example.dart` - Usage examples
4. `test/api_conversion_test.dart` - Test suite
5. `API_INTEGRATION_GUIDE.md` - Documentation

### Modified Files:
1. `lib/video_player_m3u8_alerts.dart` - Added exports for new classes

## API Data Format

Your API should return data in this format:

```json
{
  "fileUrl": "https://example.com/video/index.m3u8",
  "duration": 18440,
  "aiAlert": [
    {
      "id": 41652,
      "device_id": "bf27eac9cc2ede8c",
      "entity_id": "",
      "created_at": "2025-12-11T07:23:13.000000Z",
      "title": "Parcel Alert!",
      "image": "https://example.com/alert.jpg",
      "text": "A parcel is detected at the porch."
    }
  ],
  "fileStartTime": "2025-12-11T05:04:26.000000Z",
  "fileEndTime": "2025-12-11T10:20:14.000000Z"
}
```

**Important:** All timestamps must be in UTC format (ISO 8601).

## Key Features

✅ Automatic UTC timestamp conversion  
✅ Smart alert filtering (removes out-of-bounds alerts)  
✅ Automatic color/icon assignment by alert type  
✅ Sorted markers by timeline position  
✅ Full type safety with Dart models  
✅ Comprehensive test coverage  
✅ Easy-to-use API  
✅ Custom widget support  

## What Happens When Video Plays

1. Video player loads M3U8 stream from `fileUrl`
2. As video plays, markers appear as colored bars on the timeline
3. When playback reaches a marker time, an alert popup appears
4. Alert displays for configured duration (default 3 seconds)
5. User can click markers to jump to alert positions
6. Alerts auto-dismiss after display duration

## Performance Notes

- Markers are calculated once during initialization
- No ongoing API calls needed during playback
- Lightweight marker rendering
- Efficient timestamp calculations using DateTime

## Next Steps

You can now:
1. ✅ Parse your API responses
2. ✅ Convert alerts to timeline markers
3. ✅ Display videos with synchronized alerts
4. ✅ Customize colors, icons, and durations
5. ✅ Add custom alert widgets with images

## Support

For issues or questions:
- Check `API_INTEGRATION_GUIDE.md` for detailed examples
- Review `example/lib/api_example.dart` for working code
- Run tests to verify functionality: `flutter test test/api_conversion_test.dart`


# Using Video Player with API Data

This guide explains how to integrate video player with alert markers from your API response.

## API Data Structure

Your API returns video data with alerts in this format:

```json
{
  "fileUrl": "https://example.com/video.m3u8",
  "duration": 18440,
  "aiAlert": [
    {
      "id": 41652,
      "device_id": "bf27eac9cc2ede8c",
      "entity_id": "",
      "created_at": "2025-12-11T07:23:13.000000Z",
      "title": "Parcel Alert!",
      "image": "https://example.com/alert.jpg",
      "text": "A parcel is detected at the porch in doorbell: Front Door."
    }
  ],
  "fileStartTime": "2025-12-11T05:04:26.000000Z",
  "fileEndTime": "2025-12-11T10:20:14.000000Z"
}
```

**Important:** All timestamps (`created_at`, `fileStartTime`, `fileEndTime`) are in UTC format.

## Quick Start

### 1. Parse the API Response

```dart
import 'package:video_player_m3u8_alerts/video_player_m3u8_alerts.dart';

// Parse your API JSON response
final videoResponse = VideoApiResponse.fromJson(apiJsonData);
```

### 2. Convert Alerts to Markers

```dart
// Automatically convert all alerts to markers
final markers = AlertConverter.fromVideoApiResponse(videoResponse);

// Or with custom options
final markers = AlertConverter.fromVideoApiResponse(
  videoResponse,
  defaultColor: Colors.orange,
  defaultIcon: Icons.warning,
  defaultDisplayDuration: 4000, // milliseconds
);
```

### 3. Initialize Video Player

```dart
final controller = M3u8VideoController();
await controller.initialize(
  videoResponse.fileUrl,
  markers: markers,
);
```

### 4. Display the Player

```dart
M3u8VideoPlayer(controller: controller)
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:video_player_m3u8_alerts/video_player_m3u8_alerts.dart';

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

## How Alert Time Calculation Works

The `AlertConverter` calculates the exact position of each alert in the video timeline:

1. **File Start Time**: `2025-12-11T05:04:26.000000Z` (video begins)
2. **Alert Created At**: `2025-12-11T07:23:13.000000Z` (alert triggered)
3. **Time Difference**: `07:23:13 - 05:04:26 = 2:18:47 = 8,327 seconds`
4. **Result**: Alert marker appears at `8,327 seconds` in the video

### Example Calculation

```dart
// Video starts at 05:04:26 UTC
// Alert occurs at 07:23:13 UTC
// Difference = 2 hours, 18 minutes, 47 seconds = 8,327 seconds

AlertMarker(
  timeInSeconds: 8327.0,
  message: "A parcel is detected at the porch in doorbell: Front Door.",
  color: Colors.orange,
  icon: Icons.inventory_2,
)
```

## Advanced Usage

### Custom Alert Colors and Icons

The `AlertConverter` automatically assigns colors and icons based on alert titles:

- **Parcel** → Orange with package icon
- **Person** → Blue with person icon
- **Vehicle** → Purple with car icon
- **Animal** → Green with pet icon
- **Motion** → Grey with walk icon
- **Sound** → Teal with volume icon

You can override these defaults:

```dart
final markers = AlertConverter.convertAlertsToMarkers(
  alerts: videoResponse.aiAlert,
  fileStartTime: videoResponse.fileStartTime,
  defaultColor: Colors.red,
  defaultIcon: Icons.notification_important,
  defaultDisplayDuration: 5000,
);
```

### Custom Marker Creation

For full control over individual markers:

```dart
final customMarkers = <AlertMarker>[];

for (final alert in videoResponse.aiAlert) {
  final marker = AlertConverter.createCustomMarker(
    alert: alert,
    fileStartTime: videoResponse.fileStartTime,
    color: _getCustomColor(alert),
    icon: _getCustomIcon(alert),
    displayDuration: 4000,
    customWidget: _buildAlertWidget(alert),
  );
  customMarkers.add(marker);
}
```

### With Custom Alert Widget

Display alert images and custom styling:

```dart
Widget _buildAlertWidget(AiAlert alert) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.orange, width: 2),
    ),
    child: Row(
      children: [
        // Show alert thumbnail
        Image.network(
          alert.image,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
        const SizedBox(width: 12),
        // Show alert text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.title,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                alert.text,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

## Validation and Error Handling

The converter automatically handles edge cases:

- ✅ Filters out alerts before video start time
- ✅ Filters out alerts after video end time (if provided)
- ✅ Sorts markers chronologically
- ✅ Converts UTC timestamps correctly

```dart
try {
  final markers = AlertConverter.fromVideoApiResponse(videoResponse);
  print('Created ${markers.length} valid markers');
} catch (e) {
  print('Error converting alerts: $e');
}
```

## API Integration Example

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<AlertMarker>> fetchVideoMarkers(String videoId) async {
  final response = await http.get(
    Uri.parse('https://api.example.com/videos/$videoId'),
  );
  
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    final videoResponse = VideoApiResponse.fromJson(json);
    return AlertConverter.fromVideoApiResponse(videoResponse);
  } else {
    throw Exception('Failed to load video data');
  }
}
```

## Debugging

Enable logging to see marker calculations:

```dart
final markers = AlertConverter.fromVideoApiResponse(videoResponse);

print('Video: ${videoResponse.fileUrl}');
print('Duration: ${videoResponse.duration} seconds');
print('Start: ${videoResponse.fileStartTime}');
print('End: ${videoResponse.fileEndTime}');
print('\nMarkers created: ${markers.length}');

for (final marker in markers) {
  print('  ${marker.timeInSeconds}s: ${marker.message}');
}
```

## Notes

- All time calculations use UTC timestamps from your API
- The plugin handles timezone conversions automatically
- Markers are displayed as colored bars on the video timeline
- Alerts popup automatically when the video reaches marker positions
- Each alert displays for the configured duration (default 3 seconds)


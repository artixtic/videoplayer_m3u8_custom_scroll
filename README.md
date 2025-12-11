# Video Player M3U8 Alerts

A Flutter plugin for playing M3U8 (HLS) video streams with custom alert markers on a timeline slider. This plugin allows you to display messages, notifications, or any custom widgets at specific timestamps in your video.

## Features

- ✅ **M3U8/HLS Support**: Play HTTP Live Streaming (HLS) videos with .m3u8 playlists
- ✅ **Custom Slider**: Interactive video timeline with visual marker indicators
- ✅ **Alert Markers**: Display messages or widgets at specific timestamps
- ✅ **Full Playback Controls**: Play, pause, seek, skip forward/backward
- ✅ **Playback Speed Control**: Adjust speed from 0.5x to 2.0x
- ✅ **Customizable UI**: Custom colors, icons, and alert widgets
- ✅ **Touch Gestures**: Tap to play/pause, drag to seek
- ✅ **Auto-dismiss Alerts**: Configurable display duration for alerts

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  video_player_m3u8_alerts: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### iOS

Add the following to your `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

### Android

Add the following to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Ensure your `minSdkVersion` is at least 21 in `android/app/build.gradle`:

```gradle
minSdkVersion 21
```

## Usage

### Basic Example

```dart
import 'package:flutter/material.dart';
import 'package:video_player_m3u8_alerts/video_player_m3u8_alerts.dart';

class VideoPlayerPage extends StatefulWidget {
  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late M3u8VideoController _controller;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = M3u8VideoController();

    // Define markers with alerts
    final markers = [
      AlertMarker(
        timeInSeconds: 10,
        message: 'Important moment at 10 seconds!',
        color: Colors.orange,
        icon: Icons.warning,
      ),
      AlertMarker(
        timeInSeconds: 30,
        message: 'Another alert at 30 seconds',
        color: Colors.blue,
        icon: Icons.info,
      ),
    ];

    await _controller.initialize(
      'https://your-video-url.com/video.m3u8',
      markers: markers,
    );
    
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller.isInitialized
          ? M3u8VideoPlayer(controller: _controller)
          : Center(child: CircularProgressIndicator()),
    );
  }
}
```

### Advanced Usage

#### Creating Alert Markers

```dart
// Simple marker
AlertMarker(
  timeInSeconds: 15,
  message: 'Simple alert',
);

// Marker with custom styling
AlertMarker(
  timeInSeconds: 45,
  message: 'Custom styled alert',
  color: Colors.purple,
  icon: Icons.star,
  displayDuration: 5000, // 5 seconds
);
```

#### Controller Methods

```dart
// Playback control
await controller.play();
await controller.pause();
await controller.togglePlayPause();

// Seeking
await controller.seekTo(Duration(seconds: 30));

// Speed control
await controller.setPlaybackSpeed(1.5); // 1.5x speed

// Volume control
await controller.setVolume(0.8); // 80% volume

// Marker management
controller.addMarker(AlertMarker(...));
controller.removeMarker(marker);
controller.clearMarkers();
controller.updateMarkers([...]);

// Get current state
Duration position = controller.position;
Duration duration = controller.duration;
bool isPlaying = controller.isPlaying;
AlertMarker? currentAlert = controller.currentAlert;
```

#### Custom Alert Widget

```dart
M3u8VideoPlayer(
  controller: controller,
  alertBuilder: (AlertMarker marker) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(marker.icon, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              marker.message,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  },
);
```

#### Custom Slider Markers

```dart
CustomVideoSlider(
  controller: controller,
  activeColor: Colors.red,
  inactiveColor: Colors.grey,
  markerColor: Colors.amber,
  height: 50,
  markerBuilder: (AlertMarker marker) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: marker.color ?? Colors.amber,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  },
  onSeek: (Duration position) {
    print('Seeked to: $position');
  },
);
```

#### Dynamic Marker Management

```dart
// Add marker at current position
final currentTime = controller.position.inSeconds.toDouble();
controller.addMarker(
  AlertMarker(
    timeInSeconds: currentTime,
    message: 'Marker at current position',
    color: Colors.green,
  ),
);

// Listen to controller changes
controller.addListener(() {
  if (controller.currentAlert != null) {
    print('Alert triggered: ${controller.currentAlert!.message}');
  }
});

// Dismiss current alert manually
controller.dismissCurrentAlert();
```

## API Reference

### M3u8VideoController

Main controller for managing video playback.

| Method | Description |
|--------|-------------|
| `initialize(String url, {List<AlertMarker>? markers})` | Initialize player with M3U8 URL |
| `play()` | Start video playback |
| `pause()` | Pause video playback |
| `togglePlayPause()` | Toggle between play and pause |
| `seekTo(Duration position)` | Seek to specific position |
| `setPlaybackSpeed(double speed)` | Set playback speed |
| `setVolume(double volume)` | Set volume (0.0 - 1.0) |
| `addMarker(AlertMarker marker)` | Add new marker |
| `removeMarker(AlertMarker marker)` | Remove marker |
| `clearMarkers()` | Remove all markers |
| `updateMarkers(List<AlertMarker> markers)` | Replace all markers |
| `dismissCurrentAlert()` | Dismiss current alert |

### AlertMarker

Model for timeline markers.

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `timeInSeconds` | `double` | Yes | Time in video (seconds) |
| `message` | `String` | Yes | Alert message text |
| `color` | `Color?` | No | Marker/alert color |
| `icon` | `IconData?` | No | Icon to display |
| `customWidget` | `Widget?` | No | Custom widget |
| `displayDuration` | `int` | No | Display duration (ms) |

### M3u8VideoPlayer

Main video player widget.

| Property | Type | Description |
|----------|------|-------------|
| `controller` | `M3u8VideoController` | Video controller |
| `showControls` | `bool` | Show/hide controls |
| `controlsColor` | `Color?` | Controls color theme |
| `backgroundColor` | `Color?` | Background color |
| `alertBuilder` | `Widget Function(AlertMarker)?` | Custom alert builder |
| `placeholder` | `Widget?` | Loading placeholder |
| `fit` | `BoxFit` | Video fit mode |

## Example App

Check out the [example](example/) directory for a complete implementation showing:

- M3U8 video playback
- Multiple alert markers
- Custom marker styling
- Dynamic marker addition
- Playback controls
- Speed adjustment

To run the example:

```bash
cd example
flutter run
```

## Supported Formats

- M3U8 (HLS)
- HTTP/HTTPS streaming
- Adaptive bitrate streaming
- Multiple TS segment files

## Troubleshooting

### Video not playing

1. Ensure your M3U8 URL is valid and accessible
2. Check platform-specific permissions (Internet, network security)
3. Verify the video format is supported

### Markers not showing

1. Ensure markers are added before or after initialization
2. Check that marker times are within video duration
3. Verify marker colors contrast with the slider

### Performance issues

1. Limit the number of markers (recommended < 100)
2. Use appropriate video quality/bitrate
3. Test on physical devices, not just emulators

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or suggestions, please file an issue on the [GitHub repository](https://github.com/yourusername/video_player_m3u8_alerts).

## Roadmap

- [ ] Fullscreen support
- [ ] Picture-in-Picture mode
- [ ] Subtitle support
- [ ] Chromecast support
- [ ] Download/offline playback
- [ ] Multi-quality selection UI

## Credits

Built with:
- [video_player](https://pub.dev/packages/video_player) - Flutter video player
- [chewie](https://pub.dev/packages/chewie) - Video player controls

---

Made with ❤️ by the Flutter community


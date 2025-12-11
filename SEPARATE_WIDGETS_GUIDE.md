# 🎬 Separate Video Player and Waveform Slider Integration Guide

## Overview

The video player and slider are **completely separate widgets** that you can place anywhere in your app. They communicate through the shared `M3u8VideoController`.

## Visual Design (Matching Image)

```
┌────────────────────────────────────┐
│                                    │
│         VIDEO PLAYER               │  ← Separate widget
│       (Place anywhere)             │
│                                    │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│  [PARCEL ALERT!] [PARCEL ALERT!]   │  ← Alert badges (separate widget)
└────────────────────────────────────┘

┌────────────────────────────────────┐
│  ||||||||||||   [Today]    [LIVE]  │  ← Waveform slider (separate widget)
│  ||||||||||||||||||||||||          │
│  16:30:37                          │
└────────────────────────────────────┘
```

## Quick Start

### 1. Initialize Controller (Once)

```dart
late M3u8VideoController _videoController;

@override
void initState() {
  super.initState();
  _initializeVideo();
}

Future<void> _initializeVideo() async {
  // Parse your API data
  final videoResponse = VideoApiResponse.fromJson(apiData);
  final markers = AlertConverter.fromVideoApiResponse(videoResponse);
  
  // Initialize controller
  _videoController = M3u8VideoController();
  await _videoController.initialize(videoResponse.fileUrl, markers: markers);
}

@override
void dispose() {
  _videoController.dispose();
  super.dispose();
}
```

### 2. Use Widgets Separately

```dart
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      // WIDGET 1: Video Player (place anywhere)
      M3u8VideoPlayerNoSlider(
        controller: _videoController,
        backgroundColor: Colors.black,
      ),
      
      // WIDGET 2: Alert Badges (place anywhere)
      AlertTimeline(
        alerts: _videoController.markers,
        onAlertTap: (alert) {
          _videoController.seekTo(Duration(seconds: alert.timeInSeconds.toInt()));
        },
      ),
      
      // WIDGET 3: Waveform Slider (place anywhere)
      WaveformSlider(
        controller: _videoController,
        activeColor: Color(0xFF00BCD4),
        inactiveColor: Color(0xFFE0E0E0),
        alertColor: Color(0xFF8BC34A),
        height: 100,
      ),
    ],
  );
}
```

## Widget Details

### 1. Video Player Widget

```dart
M3u8VideoPlayerNoSlider(
  controller: _videoController,
  backgroundColor: Colors.black,
  showPlayPauseButton: true,
)
```

**Features:**
- Just video display
- No built-in controls
- Alert overlays (optional)
- Play/pause on tap

**Can be placed:**
- In a column
- In a stack
- Inside a PageView
- Anywhere in your widget tree

---

### 2. Waveform Slider Widget

```dart
WaveformSlider(
  controller: _videoController,
  
  // Colors
  activeColor: Color(0xFF00BCD4),      // Cyan/blue for played bars
  inactiveColor: Color(0xFFE0E0E0),    // Light grey for unplayed bars
  alertColor: Color(0xFF8BC34A),       // Green for alert bars
  
  // Layout
  height: 100,                          // Slider height
  barsCount: 120,                       // Number of vertical bars
  
  // Buttons
  showTodayButton: true,                // Show "Today" button
  showLiveIndicator: true,              // Show "LIVE" badge
  
  // Callbacks
  onTodayPressed: () {
    _videoController.seekTo(_videoController.duration);
  },
  onSeek: (position) {
    print('Seeked to: $position');
  },
)
```

**Features:**
- Vertical bars (waveform style)
- 15% taller bars at alert positions
- "Today" button (center)
- "LIVE" indicator (right)
- Tap to seek
- Drag to scrub

**Can be placed:**
- At bottom of screen
- In a drawer
- In a separate panel
- Floating over content

---

### 3. Alert Widgets

#### Alert Timeline (Horizontal badges)
```dart
AlertTimeline(
  alerts: _videoController.markers,
  height: 40,
  onAlertTap: (alert) {
    // Jump to alert position
    _videoController.seekTo(Duration(seconds: alert.timeInSeconds.toInt()));
  },
)
```

#### Single Alert Badge
```dart
AlertBadge(
  alert: alertMarker,
  backgroundColor: Color(0xFF8BC34A),
  textColor: Colors.white,
  showIcon: true,
  onTap: () {
    // Handle tap
  },
)
```

#### Alert Overlay (for video)
```dart
AlertOverlay(
  currentAlert: _videoController.currentAlert,
  onDismiss: _videoController.dismissCurrentAlert,
)
```

---

## Integration Patterns

### Pattern 1: Traditional Layout

```dart
Column(
  children: [
    // Video at top
    AspectRatio(
      aspectRatio: 16/9,
      child: M3u8VideoPlayerNoSlider(controller: _videoController),
    ),
    
    // Alerts below video
    AlertTimeline(alerts: _videoController.markers),
    
    // Slider at bottom
    WaveformSlider(controller: _videoController, height: 100),
  ],
)
```

### Pattern 2: Fullscreen Video + Bottom Sheet Slider

```dart
Stack(
  children: [
    // Fullscreen video
    M3u8VideoPlayerNoSlider(controller: _videoController),
    
    // Bottom sheet with slider
    Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: WaveformSlider(controller: _videoController, height: 100),
    ),
  ],
)
```

### Pattern 3: Side-by-Side (Tablet/Desktop)

```dart
Row(
  children: [
    // Video on left
    Expanded(
      flex: 2,
      child: M3u8VideoPlayerNoSlider(controller: _videoController),
    ),
    
    // Slider and controls on right
    Expanded(
      child: Column(
        children: [
          WaveformSlider(controller: _videoController, height: 120),
          AlertTimeline(alerts: _videoController.markers),
          // More controls...
        ],
      ),
    ),
  ],
)
```

### Pattern 4: Separate Screens

```dart
// Screen 1: Video Player
class VideoScreen extends StatelessWidget {
  final M3u8VideoController controller;
  
  @override
  Widget build(BuildContext context) {
    return M3u8VideoPlayerNoSlider(controller: controller);
  }
}

// Screen 2: Timeline/Slider
class TimelineScreen extends StatelessWidget {
  final M3u8VideoController controller;
  
  @override
  Widget build(BuildContext context) {
    return WaveformSlider(controller: controller, height: 150);
  }
}
```

---

## Customization Examples

### Matching the Image Colors

```dart
WaveformSlider(
  controller: _videoController,
  activeColor: Color(0xFF00BCD4),      // Cyan blue
  inactiveColor: Color(0xFFE0E0E0),    // Light grey
  alertColor: Color(0xFF8BC34A),       // Light green
  height: 100,
  showTodayButton: true,
  showLiveIndicator: true,
)
```

### More Bars (Denser Waveform)

```dart
WaveformSlider(
  controller: _videoController,
  barsCount: 200,  // More bars = denser visualization
  height: 120,
)
```

### Custom Today Button Action

```dart
WaveformSlider(
  controller: _videoController,
  onTodayPressed: () {
    // Custom action
    final now = DateTime.now();
    // Calculate position based on current time
    // _videoController.seekTo(...);
  },
)
```

### Without Today/Live Buttons

```dart
WaveformSlider(
  controller: _videoController,
  showTodayButton: false,
  showLiveIndicator: false,
  height: 80,
)
```

---

## Complete Example: Separate Integration

```dart
class MyVideoPage extends StatefulWidget {
  @override
  State<MyVideoPage> createState() => _MyVideoPageState();
}

class _MyVideoPageState extends State<MyVideoPage> {
  late M3u8VideoController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final videoResponse = VideoApiResponse.fromJson(apiData);
    final markers = AlertConverter.fromVideoApiResponse(videoResponse);
    
    _controller = M3u8VideoController();
    await _controller.initialize(videoResponse.fileUrl, markers: markers);
    
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          // SECTION 1: Video Player
          _buildVideoPlayer(),
          
          // SECTION 2: Alert Badges
          _buildAlertBadges(),
          
          // SECTION 3: Waveform Slider
          _buildWaveformSlider(),
          
          // SECTION 4: Controls (optional)
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          M3u8VideoPlayerNoSlider(
            controller: _controller,
            backgroundColor: Colors.black,
          ),
          
          // Time overlay
          Positioned(
            bottom: 8,
            left: 8,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  padding: EdgeInsets.all(4),
                  color: Colors.black54,
                  child: Text(
                    _formatTime(_controller.position),
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBadges() {
    return Container(
      height: 40,
      color: Colors.white,
      child: AlertTimeline(
        alerts: _controller.markers,
        onAlertTap: (alert) {
          _controller.seekTo(Duration(seconds: alert.timeInSeconds.toInt()));
        },
      ),
    );
  }

  Widget _buildWaveformSlider() {
    return WaveformSlider(
      controller: _controller,
      activeColor: Color(0xFF00BCD4),
      inactiveColor: Color(0xFFE0E0E0),
      alertColor: Color(0xFF8BC34A),
      height: 100,
      showTodayButton: true,
      showLiveIndicator: true,
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.replay_10),
            onPressed: () {
              final pos = _controller.position - Duration(seconds: 10);
              _controller.seekTo(pos < Duration.zero ? Duration.zero : pos);
            },
          ),
          
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return IconButton(
                icon: Icon(
                  _controller.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: _controller.togglePlayPause,
              );
            },
          ),
          
          IconButton(
            icon: Icon(Icons.forward_10),
            onPressed: () {
              final pos = _controller.position + Duration(seconds: 10);
              _controller.seekTo(
                pos > _controller.duration ? _controller.duration : pos,
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }
}
```

---

## Key Benefits

✅ **Flexible Layout** - Place widgets anywhere  
✅ **Separate Integration** - Video and slider are independent  
✅ **Shared Controller** - Single source of truth  
✅ **Multiple Screens** - Use same controller across screens  
✅ **Custom UI** - Build your own layout  
✅ **Reusable** - Mix and match widgets  

---

## Files Created

1. ✅ `lib/widgets/waveform_slider.dart` - Waveform slider widget
2. ✅ `lib/widgets/alert_widgets.dart` - Alert badges and overlays
3. ✅ `example/lib/waveform_demo.dart` - Complete example

---

## Summary

- **Video Player**: `M3u8VideoPlayerNoSlider` - Place anywhere
- **Waveform Slider**: `WaveformSlider` - Place anywhere
- **Alert Badges**: `AlertTimeline` / `AlertBadge` - Place anywhere
- **Controller**: `M3u8VideoController` - Shared between all widgets

All widgets work independently and communicate through the shared controller! 🎬


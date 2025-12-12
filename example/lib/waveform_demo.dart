import 'package:flutter/material.dart';
import 'package:video_player_m3u8_alerts/video_player_m3u8_alerts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waveform Slider Demo',
      theme: ThemeData.light(),
      home: const WaveformSliderDemo(),
    );
  }
}

/// Example showing video player and slider as completely separate widgets
/// You can place them anywhere in your layout
class WaveformSliderDemo extends StatefulWidget {
  const WaveformSliderDemo({super.key});

  @override
  State<WaveformSliderDemo> createState() => _WaveformSliderDemoState();
}

class _WaveformSliderDemoState extends State<WaveformSliderDemo> {
  late M3u8VideoController _videoController;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayerWithApiData();
  }

  Future<void> _initializePlayerWithApiData() async {
    try {
      // Your API data
      final apiData = {
        "fileUrl":
            "https://media-assets-test.irvinei.com/BJQMgFq81ZXu0mFg9q5tECPN7EwFTvfL5fsBM8FrDFxeEidbvnP51v0JRyib/RP1A.200720.012/index-1765393200.m3u8",
        "duration": 18440,
        "aiAlert": [
          {
            "id": 41652,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:13.000000Z",
            "title": "Parcel Alert!",
            "image":
                "https://media-assets-test.irvinei.com/alert/5/1765437791.6300094_c11fce4b.jpg",
            "text":
                "A parcel is detected at the porch in doorbell: Front Door.",
          },
          {
            "id": 41653,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:23.000000Z",
            "title": "Parcel Alert!",
            "image":
                "https://media-assets-test.irvinei.com/alert/5/1765437801.892106_580208d8.jpg",
            "text":
                "A parcel is detected at the porch in doorbell: Front Door.",
          },
          {
            "id": 41654,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:35.000000Z",
            "title": "Parcel Alert!",
            "image":
                "https://media-assets-test.irvinei.com/alert/5/1765437813.0441897_b6b42fec.jpg",
            "text":
                "A parcel is detected at the porch in doorbell: Front Door.",
          },
          {
            "id": 41655,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:45.000000Z",
            "title": "Parcel Alert!",
            "image":
                "https://media-assets-test.irvinei.com/alert/5/1765437823.9853985_9c1980b6.jpg",
            "text":
                "A parcel is detected at the porch in doorbell: Front Door.",
          },
        ],
        "fileStartTime": "2025-12-11T05:04:26.000000Z",
        "fileEndTime": "2025-12-11T10:20:14.000000Z",
      };

      final videoResponse = VideoApiResponse.fromJson(apiData);

      // Use automatic timeline offset detection by parsing M3U8
      final markers = await AlertConverter.fromVideoApiResponseAsync(
        videoResponse,
        detectTimelineOffset: true,
      );

      debugPrint('📍 Initialized ${markers.length} alert markers:');
      for (var i = 0; i < markers.length; i++) {
        debugPrint(
          '   Alert ${i + 1}: ${markers[i].timeInSeconds}s - ${markers[i].message}',
        );
      }
      debugPrint('   Video duration: ${videoResponse.duration}s');

      _videoController = M3u8VideoController();
      await _videoController.initialize(
        videoResponse.fileUrl,
        markers: markers,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load video: $e';
      });
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Waveform Slider'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : _buildSeparateWidgetsLayout(),
    );
  }

  /// Layout showing video player and slider as completely separate widgets
  Widget _buildSeparateWidgetsLayout() {
    return Column(
      children: [
        // SECTION 1: VIDEO PLAYER (can be anywhere in your app)
        Container(
          color: Colors.black,
          child: Stack(
            children: [
              // Video Player Widget
              AspectRatio(
                aspectRatio: 16 / 9,
                child: M3u8VideoPlayerNoSlider(
                  controller: _videoController,
                  backgroundColor: Colors.black,
                ),
              ),

              // Alert Overlay (optional, can be shown/hidden)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: AnimatedBuilder(
                  animation: _videoController,
                  builder: (context, child) {
                    return AlertOverlay(
                      currentAlert: _videoController.currentAlert,
                      onDismiss: _videoController.dismissCurrentAlert,
                    );
                  },
                ),
              ),

              // Time Display
              Positioned(
                bottom: 8,
                left: 8,
                child: AnimatedBuilder(
                  animation: _videoController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(_videoController.position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // SECTION 2: ALERT BADGES (can be anywhere in your app)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AlertTimeline(
            alerts: _videoController.markers,
            onAlertTap: (alert) {
              // Jump to alert position
              _videoController.seekTo(
                Duration(seconds: alert.timeInSeconds.toInt()),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // SECTION 3: WAVEFORM SLIDER (can be anywhere in your app)
        Container(
          color: Colors.white,
          child: WaveformSlider(
            controller: _videoController,
            activeColor: const Color(0xFF00BCD4),
            inactiveColor: const Color(0xFFE0E0E0),
            alertColor: const Color(0xFF8BC34A),
            height: 100,
            showTodayButton: false,
            showLiveIndicator: false,
            barsCount: 120,
          ),
        ),

        const Spacer(),

        // SECTION 4: CONTROL BUTTONS (can be anywhere in your app)
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                iconSize: 32,
                onPressed: () {
                  final newPos =
                      _videoController.position - const Duration(seconds: 10);
                  _videoController.seekTo(
                    newPos < Duration.zero ? Duration.zero : newPos,
                  );
                },
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4),
                  shape: BoxShape.circle,
                ),
                child: AnimatedBuilder(
                  animation: _videoController,
                  builder: (context, child) {
                    return IconButton(
                      icon: Icon(
                        _videoController.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      iconSize: 32,
                      onPressed: _videoController.togglePlayPause,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10),
                iconSize: 32,
                onPressed: () {
                  final newPos =
                      _videoController.position + const Duration(seconds: 10);
                  _videoController.seekTo(
                    newPos > _videoController.duration
                        ? _videoController.duration
                        : newPos,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}

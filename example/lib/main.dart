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
      title: 'M3U8 Video Player with API Data',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ApiVideoPlayerDemo(),
    );
  }
}

class ApiVideoPlayerDemo extends StatefulWidget {
  const ApiVideoPlayerDemo({super.key});

  @override
  State<ApiVideoPlayerDemo> createState() => _ApiVideoPlayerDemoState();
}

class _ApiVideoPlayerDemoState extends State<ApiVideoPlayerDemo> {
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
      // This is your API data structure
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

      // Parse the API response
      final videoResponse = VideoApiResponse.fromJson(apiData);

      // Convert AI alerts to AlertMarkers
      final markers = AlertConverter.fromVideoApiResponse(
        videoResponse,
        defaultDisplayDuration: 4000,
      );

      // Initialize the video controller
      _videoController = M3u8VideoController();
      await _videoController.initialize(
        videoResponse.fileUrl,
        markers: markers,
      );

      setState(() {
        _isLoading = false;
      });

      // Log the markers for debugging
      debugPrint('Video initialized with ${markers.length} alert markers:');
      for (final marker in markers) {
        debugPrint('  - ${marker.timeInSeconds}s: ${marker.message}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load video: $e';
      });
      debugPrint('Error: $e');
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('API Video with Custom Slider'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading video...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = '';
                          _isLoading = true;
                        });
                        _initializePlayerWithApiData();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Video Player (without slider)
                Expanded(
                  child: M3u8VideoPlayerNoSlider(
                    controller: _videoController,
                    backgroundColor: Colors.black,
                  ),
                ),

                // Custom Slider Below Video
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      // Play/Pause and Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Skip backward
                          IconButton(
                            icon: const Icon(
                              Icons.replay_10,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              final newPosition =
                                  _videoController.position -
                                  const Duration(seconds: 10);
                              _videoController.seekTo(
                                newPosition < Duration.zero
                                    ? Duration.zero
                                    : newPosition,
                              );
                            },
                          ),

                          const SizedBox(width: 16),

                          // Play/Pause button (larger)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                _videoController.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                              onPressed: _videoController.togglePlayPause,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Skip forward
                          IconButton(
                            icon: const Icon(
                              Icons.forward_10,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              final newPosition =
                                  _videoController.position +
                                  const Duration(seconds: 10);
                              _videoController.seekTo(
                                newPosition > _videoController.duration
                                    ? _videoController.duration
                                    : newPosition,
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Wave Video Slider with alert width increase
                      WaveVideoSlider(
                        controller: _videoController,
                        activeColor: Colors.orange,
                        inactiveColor: Colors.grey,
                        markerColor: Colors.amber,
                        height: 80,
                        waveAmplitude: 10.0,
                        waveFrequency: 0.015,
                      ),

                      const SizedBox(height: 8),

                      // Video Info
                      AnimatedBuilder(
                        animation: _videoController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_videoController.markers.length} Alerts',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Parcel Detection',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

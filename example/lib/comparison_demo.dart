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
      title: 'Slider Comparison',
      theme: ThemeData.dark(),
      home: const SliderComparisonDemo(),
    );
  }
}

class SliderComparisonDemo extends StatefulWidget {
  const SliderComparisonDemo({super.key});

  @override
  State<SliderComparisonDemo> createState() => _SliderComparisonDemoState();
}

class _SliderComparisonDemoState extends State<SliderComparisonDemo> {
  late M3u8VideoController _videoController;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _useWaveSlider = true; // Toggle between sliders

  @override
  void initState() {
    super.initState();
    _initializePlayerWithApiData();
  }

  Future<void> _initializePlayerWithApiData() async {
    try {
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
      final markers = AlertConverter.fromVideoApiResponse(videoResponse);

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_useWaveSlider ? '🌊 Wave Slider' : '━ Flat Slider'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Toggle button
          IconButton(
            icon: Icon(_useWaveSlider ? Icons.waves : Icons.linear_scale),
            tooltip: 'Toggle Slider Style',
            onPressed: () {
              setState(() {
                _useWaveSlider = !_useWaveSlider;
              });
            },
          ),
        ],
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
                // Video Player
                Expanded(
                  child: M3u8VideoPlayerNoSlider(
                    controller: _videoController,
                    backgroundColor: Colors.black,
                  ),
                ),

                // Controls and Slider Section
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Info banner
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _useWaveSlider ? Icons.waves : Icons.linear_scale,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _useWaveSlider
                                  ? 'Wave Slider - Alerts are 15% wider'
                                  : 'Flat Slider - Standard view',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.replay_10,
                              color: Colors.white,
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
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: AnimatedBuilder(
                                animation: _videoController,
                                builder: (context, child) => Icon(
                                  _videoController.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              onPressed: _videoController.togglePlayPause,
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(
                              Icons.forward_10,
                              color: Colors.white,
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

                      // Slider (toggles between wave and flat)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _useWaveSlider
                            ? WaveVideoSlider(
                                key: const ValueKey('wave'),
                                controller: _videoController,
                                activeColor: Colors.orange,
                                inactiveColor: Colors.grey,
                                markerColor: Colors.amber,
                                height: 80,
                                waveAmplitude: 10.0,
                                waveFrequency: 0.015,
                              )
                            : CustomVideoSlider(
                                key: const ValueKey('flat'),
                                controller: _videoController,
                                activeColor: Colors.orange,
                                inactiveColor: Colors.grey,
                                markerColor: Colors.amber,
                                height: 60,
                              ),
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
                              const Text(
                                'Tap the wave icon to toggle',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
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

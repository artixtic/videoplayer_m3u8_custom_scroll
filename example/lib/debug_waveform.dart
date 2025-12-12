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
      title: 'Debug Waveform',
      theme: ThemeData.light(),
      home: const DebugWaveform(),
    );
  }
}

class DebugWaveform extends StatefulWidget {
  const DebugWaveform({super.key});

  @override
  State<DebugWaveform> createState() => _DebugWaveformState();
}

class _DebugWaveformState extends State<DebugWaveform> {
  late M3u8VideoController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final apiData = {
        "fileUrl":
            "https://media-assets-test.irvinei.com/BJQMgFq81ZXu0mFg9q5tECPN7EwFTvfL5fsBM8FrDFxeEidbvnP51v0JRyib/RP1A.200720.012/index-1765393200.m3u8",
        "duration": 22424,
        "aiAlert": [
          {
            "id": 41652,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:13.000000Z",
            "title": "Parcel Alert!",
            "image":
                "https://media-assets-test.irvinei.com/alert/5/1765437791.6300094_c11fce4b.jpg",
            "text": "A parcel is detected at the porch.",
          },
          {
            "id": 41653,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:23.000000Z",
            "title": "Parcel Alert!",
            "image":
                "https://media-assets-test.irvinei.com/alert/5/1765437801.892106_580208d8.jpg",
            "text": "A parcel is detected at the porch.",
          },
          {
            "id": 41654,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:35.000000Z",
            "title": "Parcel Alert!",
            "image":
                "https://media-assets-test.irvinei.com/alert/5/1765437813.0441897_b6b42fec.jpg",
            "text": "A parcel is detected at the porch.",
          },
          {
            "id": 41655,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:45.000000Z",
            "title": "Parcel Alert!",
            "image":
                "https://media-assets-test.irvinei.com/alert/5/1765437823.9853985_9c1980b6.jpg",
            "text": "A parcel is detected at the porch.",
          },
        ],
        "fileStartTime": "2025-12-11T05:04:26.000000Z",
        "fileEndTime": "2025-12-11T11:31:43.000000Z",
      };

      final videoResponse = VideoApiResponse.fromJson(apiData);
      final markers = await AlertConverter.fromVideoApiResponseAsync(
        videoResponse,
        detectTimelineOffset: true,
      );

      print('\n' + '=' * 50);
      print('DEBUG: Alert Markers Created');
      print('=' * 50);
      print('Total markers: ${markers.length}');
      for (var i = 0; i < markers.length; i++) {
        print(
          'Marker $i: ${markers[i].timeInSeconds}s - ${markers[i].message}',
        );
      }
      print('Video duration: ${videoResponse.duration}s');
      print('=' * 50 + '\n');

      _controller = M3u8VideoController();
      await _controller.initialize(videoResponse.fileUrl, markers: markers);

      print(
        '\nController initialized with ${_controller.markers.length} markers\n',
      );

      setState(() => _isLoading = false);
    } catch (e) {
      print('ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Waveform Alerts'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video Duration: ${_controller.duration.inSeconds}s',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Alert Markers: ${_controller.markers.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_controller.markers.length, (i) {
                        final marker = _controller.markers[i];
                        return Text(
                          'Alert ${i + 1}: ${marker.timeInSeconds.toStringAsFixed(0)}s',
                          style: TextStyle(color: marker.color),
                        );
                      }),
                    ],
                  ),
                ),
                const Divider(),
                const Text(
                  'Look for GREEN bars below:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  color: Colors.white,
                  child: WaveformSlider(
                    controller: _controller,
                    activeColor: const Color(0xFF00BCD4), // Cyan
                    inactiveColor: const Color(0xFFE0E0E0), // Grey
                    alertColor: const Color(0xFF8BC34A), // GREEN
                    height: 150,
                    showTodayButton: false,
                    showLiveIndicator: false,
                    barsCount: 150, // More bars for better visibility
                  ),
                ),
              ],
            ),
    );
  }
}

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
      title: 'Wave Slider Demo',
      theme: ThemeData.dark(),
      home: const WaveSliderDemo(),
    );
  }
}

class WaveSliderDemo extends StatefulWidget {
  const WaveSliderDemo({super.key});

  @override
  State<WaveSliderDemo> createState() => _WaveSliderDemoState();
}

class _WaveSliderDemoState extends State<WaveSliderDemo> {
  Map<String, dynamic>? _apiData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStreamData();
  }

  Future<void> _fetchStreamData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      debugPrint('📊 Loading stream data...');

      // Use static fallback data (no API calls)
      final jsonData = {
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
        "fileEndTime": "2025-12-11T11:31:43.000000Z",
      };

      debugPrint('✅ Stream data loaded');
      debugPrint('📊 Data: ${jsonData.toString().substring(0, 200)}...');

      // Verify M3U8 file using ffprobe (if available) - do this BEFORE setState
      final fileUrl = jsonData['fileUrl'] as String?;
      if (fileUrl != null) {
        debugPrint('');
        debugPrint('🔍 Verifying M3U8 file with ffprobe...');
        try {
          // Verify segments (check more segments for better analysis)
          final verifyResult = await M3u8Verifier.verifyM3u8File(
            m3u8Url: fileUrl,
            maxSegmentsToCheck:
                20, // Check first 20 segments for detailed analysis
          );

          if (verifyResult['success'] == true) {
            debugPrint('✅ M3U8 verification complete');
            debugPrint(
              '   Segments checked: ${verifyResult['segmentsChecked']}',
            );
            debugPrint(
              '   Total declared duration: ${verifyResult['totalDuration']}s',
            );

            // Log each segment's duration
            final segments =
                verifyResult['segments'] as List<Map<String, dynamic>>;
            debugPrint('');
            debugPrint('📋 TS File Durations Summary:');
            debugPrint(
              '   ┌─────┬──────────────┬──────────────┬──────────────┬─────────────────────────────┐',
            );
            debugPrint(
              '   │ #   │ Declared (s)  │ Actual (s)   │ Difference   │ TS File Name                │',
            );
            debugPrint(
              '   ├─────┼──────────────┼──────────────┼──────────────┼─────────────────────────────┤',
            );

            int mismatchCount = 0;
            double totalDeclared = 0.0;
            double totalActual = 0.0;

            for (final segment in segments) {
              final index = segment['index'] as int;
              final declaredDuration = segment['declaredDuration'] as double;
              final actualDuration = segment['actualDuration'] as double?;
              final difference = segment['difference'] as double?;
              final url = segment['url'] as String;
              final fileName = url.split('/').last;

              totalDeclared += declaredDuration;
              if (actualDuration != null) {
                totalActual += actualDuration;
              }

              if (actualDuration != null && difference != null) {
                final diffStr = difference.abs().toStringAsFixed(3);
                final status = difference.abs() > 0.5 ? '⚠️' : '✓';
                final fileNameDisplay = fileName.length > 28
                    ? '${fileName.substring(0, 25)}...'
                    : fileName;
                debugPrint(
                  '   │ ${index.toString().padLeft(3)} │ ${declaredDuration.toStringAsFixed(3).padLeft(12)} │ ${actualDuration.toStringAsFixed(3).padLeft(12)} │ ${diffStr.padLeft(12)} $status │ ${fileNameDisplay.padRight(27)} │',
                );

                if (difference.abs() > 0.5) {
                  mismatchCount++;
                }
              } else {
                final fileNameDisplay = fileName.length > 28
                    ? '${fileName.substring(0, 25)}...'
                    : fileName;
                debugPrint(
                  '   │ ${index.toString().padLeft(3)} │ ${declaredDuration.toStringAsFixed(3).padLeft(12)} │ ${'N/A'.padLeft(12)} │ ${'N/A'.padLeft(12)}   │ ${fileNameDisplay.padRight(27)} │',
                );
              }
            }
            debugPrint(
              '   ├─────┼──────────────┼──────────────┼──────────────┼─────────────────────────────┤',
            );
            debugPrint(
              '   │ SUM │ ${totalDeclared.toStringAsFixed(3).padLeft(12)} │ ${totalActual > 0 ? totalActual.toStringAsFixed(3).padLeft(12) : 'N/A'.padLeft(12)} │ ${totalActual > 0 ? (totalActual - totalDeclared).abs().toStringAsFixed(3).padLeft(12) : 'N/A'.padLeft(12)}   │                             │',
            );
            debugPrint(
              '   └─────┴──────────────┴──────────────┴──────────────┴─────────────────────────────┘',
            );

            debugPrint('');
            if (mismatchCount > 0) {
              debugPrint(
                '   ⚠️  Found $mismatchCount segments with duration mismatches (>0.5s)',
              );
            } else {
              debugPrint('   ✅ All checked segments match declared durations');
            }

            if (totalActual > 0) {
              final totalDiff = (totalActual - totalDeclared).abs();
              debugPrint(
                '   📊 Total declared duration: ${totalDeclared.toStringAsFixed(3)}s',
              );
              debugPrint(
                '   📊 Total actual duration: ${totalActual.toStringAsFixed(3)}s',
              );
              debugPrint(
                '   📊 Total difference: ${totalDiff.toStringAsFixed(3)}s',
              );
            }
          }

          // Get total M3U8 duration
          final totalDuration = await M3u8Verifier.getM3u8Duration(fileUrl);
          if (totalDuration != null) {
            final expectedDuration = jsonData['duration'] as num?;
            if (expectedDuration != null) {
              final expectedSeconds = expectedDuration.toDouble();
              final difference = (totalDuration - expectedSeconds).abs();
              debugPrint('');
              debugPrint('📏 Duration Comparison:');
              debugPrint(
                '   API duration: ${expectedSeconds.toStringAsFixed(1)}s',
              );
              debugPrint(
                '   Actual duration (ffprobe): ${totalDuration.toStringAsFixed(1)}s',
              );
              debugPrint(
                '   Difference: ${difference.toStringAsFixed(1)}s (${(difference / 60).toStringAsFixed(1)} min)',
              );
              if (difference > 60) {
                debugPrint('   ⚠️  Significant duration difference detected!');
              }
            }
          }
          debugPrint('');
        } catch (e) {
          debugPrint(
            '⚠️  M3U8 verification failed (ffprobe may not be installed): $e',
          );
          debugPrint(
            '   Install ffmpeg to enable verification: brew install ffmpeg',
          );
        }
      }

      // Now update state synchronously after all async work is done
      setState(() {
        _apiData = jsonData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Loading stream data...',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state with retry option
    if (_apiData == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Failed to load stream data',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchStreamData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Display video player with waveform slider using API data
    // Uses full timeline parsing to account for gaps in recording (fixes 2-4 min offset issue)
    return ApiVideoPlayerScreen(
      apiData: _apiData!,
      title:
          'Stream Player - ${_errorMessage != null ? "Using Fallback Data" : "Live Data"}',
      sliderActiveColor:
          Colors.black87, // Black for played segments (matching design)
      sliderInactiveColor: Colors.black26, // Light gray for unplayed segments
      sliderMarkerColor: const Color(0xFF8BC34A), // Green for alert markers
      backgroundColor: Colors.black,
      useWaveSlider: true, // Waveform slider enabled with tick marks design
    );
  }
}

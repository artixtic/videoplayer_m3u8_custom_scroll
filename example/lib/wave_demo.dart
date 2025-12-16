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
            "https://media-assets-dev.irvinei.com/GZzGp4YGcUz9mSJVpryFP7g4OsA74X98wym4q1u3g8nvGAi6yFMC7MrUAeux/RP1A.200720.012/index-1765738800.m3u8",
        "duration": 2661.55,
        "aiAlert": [
          {
            "id": 5340,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-15T09:59:02.000000Z",
            "title": "Visitor Alert!",
            "image":
                "https://media-assets-dev.irvinei.com/images/image_visitor_3015863.png",
            "text": "Someone is at the door (devpixels) whose face is unclear.",
          },
          {
            "id": 5343,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-15T10:35:34.000000Z",
            "title": "Weapon Alert!",
            "image":
                "https://media-assets-dev.irvinei.com/alert/8/1765794928.7054508_247686.jpg",
            "text": "Weapon detected in doorbell: devpixels.",
          },
          {
            "id": 5344,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-15T11:07:04.000000Z",
            "title": "Weapon Alert!",
            "image":
                "https://media-assets-dev.irvinei.com/alert/8/1765796817.3332248_768497.jpg",
            "text": "Weapon detected in doorbell: devpixels.",
          },
          {
            "id": 5345,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-15T11:26:57.000000Z",
            "title": "Parcel Alert!",
            "image":
                "https://media-assets-dev.irvinei.com/alert/8/1765798010.3231838_607388.jpg",
            "text": "A parcel is detected at the porch in doorbell: devpixels.",
          },
          {
            "id": 5346,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-15T11:27:18.000000Z",
            "title": "Parcel Alert!",
            "image":
                "https://media-assets-dev.irvinei.com/alert/8/1765798031.6473496_324868.jpg",
            "text": "A parcel is detected at the porch in doorbell: devpixels.",
          },
        ],
        "fileStartTime": "2025-12-15T10:27:29.000000Z",
        "fileEndTime": "2025-12-15T11:27:40.000000Z",
      };

      // Filter alerts to only include those within file time range
      final fileStartTime = jsonData['fileStartTime'] as String?;
      final fileEndTime = jsonData['fileEndTime'] as String?;
      final aiAlerts = jsonData['aiAlert'] as List<dynamic>?;

      if (fileStartTime != null && fileEndTime != null && aiAlerts != null) {
        try {
          final startDateTime = DateTime.parse(fileStartTime);
          final endDateTime = DateTime.parse(fileEndTime);

          final filteredAlerts = aiAlerts.where((alert) {
            final createdAt = alert['created_at'] as String?;
            if (createdAt == null) return false;

            try {
              final alertDateTime = DateTime.parse(createdAt);
              return alertDateTime.isAfter(
                    startDateTime.subtract(const Duration(milliseconds: 1)),
                  ) &&
                  alertDateTime.isBefore(
                    endDateTime.add(const Duration(milliseconds: 1)),
                  );
            } catch (e) {
              debugPrint('⚠️  Failed to parse alert created_at: $createdAt');
              return false;
            }
          }).toList();

          jsonData['aiAlert'] = filteredAlerts;
          debugPrint(
            '📊 Filtered alerts: ${aiAlerts.length} -> ${filteredAlerts.length}',
          );
        } catch (e) {
          debugPrint('⚠️  Failed to parse file time range: $e');
        }
      }

      debugPrint('✅ Stream data loaded');
      debugPrint('📊 Data: ${jsonData.toString().substring(0, 200)}...');

      // Adjust alert times by subtracting M3U8 gaps
      final fileUrl = jsonData['fileUrl'] as String?;
      final adjustedAlerts = jsonData['aiAlert'] as List<dynamic>?;

      if (fileUrl != null &&
          adjustedAlerts != null &&
          adjustedAlerts.isNotEmpty) {
        try {
          debugPrint('');
          debugPrint(
            '🔍 Calculating gaps in M3U8 and adjusting alert times...',
          );

          // Build timeline to identify gaps
          final timeline = await AlertConverter.buildSegmentTimeline(
            m3u8Url: fileUrl,
          );

          if (timeline.isNotEmpty) {
            // Sort segments by timestamp
            final sortedSegments = timeline.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));

            // Calculate gaps between segments
            final List<Map<String, dynamic>> gaps = [];
            for (int i = 1; i < sortedSegments.length; i++) {
              final prevSegment = sortedSegments[i - 1];
              final currSegment = sortedSegments[i];

              // Calculate expected next timestamp (previous timestamp + segment duration)
              final expectedNextTimestamp = prevSegment.key.add(
                Duration(
                  milliseconds: (prevSegment.value.duration * 1000).round(),
                ),
              );

              // Calculate actual time difference in seconds
              final actualTimeDiffSeconds = currSegment.key
                  .difference(prevSegment.key)
                  .inSeconds
                  .toDouble();

              // If there's a gap (actual time diff > segment duration + small threshold)
              if (actualTimeDiffSeconds > prevSegment.value.duration + 1) {
                // Gap = actual time difference - segment duration
                final gapDuration =
                    actualTimeDiffSeconds - prevSegment.value.duration;
                gaps.add({
                  'start': prevSegment.key,
                  'end': currSegment.key,
                  'gapSeconds': gapDuration,
                });
              }
            }

            debugPrint('   Found ${gaps.length} gap(s) in M3U8 file');
            for (int i = 0; i < gaps.length; i++) {
              final gap = gaps[i];
              debugPrint(
                '   Gap ${i + 1}: ${gap['gapSeconds']}s between ${gap['start']} and ${gap['end']}',
              );
            }

            // Adjust alert times by subtracting cumulative gaps
            // Calculate cumulative gaps correctly by summing all gaps that occur before each alert
            final fileStartTimeStr = jsonData['fileStartTime'] as String?;
            if (fileStartTimeStr != null) {
              final fileStartTime = DateTime.parse(fileStartTimeStr);

              // Build cumulative gap map: for each segment, what's the total gap before it
              final Map<DateTime, double> cumulativeGapAtSegment = {};
              double runningGapTotal = 0.0;

              // Initialize first segment with 0 gap
              cumulativeGapAtSegment[sortedSegments.first.key] = 0.0;

              // For each gap, add it to the running total at the segment where it ends
              for (final gap in gaps) {
                final gapEnd = gap['end'] as DateTime;
                runningGapTotal += gap['gapSeconds'] as double;
                cumulativeGapAtSegment[gapEnd] = runningGapTotal;
              }

              for (int i = 0; i < adjustedAlerts.length; i++) {
                final alert = adjustedAlerts[i] as Map<String, dynamic>;
                final createdAtStr = alert['created_at'] as String?;

                if (createdAtStr != null) {
                  try {
                    final originalCreatedAt = DateTime.parse(createdAtStr);

                    // Find the latest segment that is <= alert time
                    DateTime? latestSegmentBeforeAlert;
                    double cumulativeGap = 0.0;

                    for (final segment in sortedSegments) {
                      if (segment.key.isBefore(originalCreatedAt) ||
                          segment.key.isAtSameMomentAs(originalCreatedAt)) {
                        latestSegmentBeforeAlert = segment.key;
                        // Get cumulative gap at this segment (or 0 if not in map)
                        cumulativeGap =
                            cumulativeGapAtSegment[segment.key] ?? 0.0;
                      } else {
                        break;
                      }
                    }

                    // Check if alert is within a gap
                    for (final gap in gaps) {
                      final gapStart = gap['start'] as DateTime;
                      final gapEnd = gap['end'] as DateTime;
                      final gapSeconds = gap['gapSeconds'] as double;

                      // Find segment at gapStart to get its duration
                      final startSegment = sortedSegments.firstWhere(
                        (e) => e.key == gapStart,
                        orElse: () => sortedSegments.first,
                      );
                      final gapActualStart = gapStart.add(
                        Duration(
                          milliseconds: (startSegment.value.duration * 1000)
                              .round(),
                        ),
                      );

                      // If alert is within this gap
                      if (gapActualStart.isBefore(originalCreatedAt) &&
                          gapEnd.isAfter(originalCreatedAt)) {
                        // Add the partial gap
                        final partialGap = originalCreatedAt
                            .difference(gapActualStart)
                            .inSeconds
                            .toDouble();
                        cumulativeGap += partialGap.clamp(0.0, gapSeconds);
                      }
                    }

                    if (cumulativeGap > 0.1) {
                      // Adjust alert time by subtracting cumulative gap
                      final adjustedCreatedAt = originalCreatedAt.subtract(
                        Duration(milliseconds: (cumulativeGap * 1000).round()),
                      );

                      alert['created_at'] = adjustedCreatedAt
                          .toUtc()
                          .toIso8601String();

                      debugPrint(
                        '   Alert ${i + 1}: Adjusted by -${cumulativeGap.toStringAsFixed(1)}s',
                      );
                      debugPrint(
                        '      Original: ${originalCreatedAt.toUtc()}',
                      );
                      debugPrint(
                        '      Cumulative gap: ${cumulativeGap.toStringAsFixed(1)}s',
                      );
                      debugPrint(
                        '      Adjusted: ${adjustedCreatedAt.toUtc()}',
                      );
                    } else {
                      debugPrint('   Alert ${i + 1}: No adjustment needed');
                    }
                  } catch (e) {
                    debugPrint('⚠️  Failed to adjust alert ${i + 1}: $e');
                  }
                }
              }

              jsonData['aiAlert'] = adjustedAlerts;
              debugPrint('');
              debugPrint('✅ Alert times adjusted for M3U8 gaps');
            }
          }
        } catch (e) {
          debugPrint('⚠️  Failed to adjust alert times for gaps: $e');
        }
      }

      // Verify M3U8 file using ffprobe (if available) - do this BEFORE setState
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

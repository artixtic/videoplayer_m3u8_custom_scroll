import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/alert_marker.dart';
import '../models/video_api_response.dart';
import 'm3u8_verifier.dart';

/// Segment information with position and duration
class SegmentInfo {
  final double position;
  final double duration;
  
  SegmentInfo({required this.position, required this.duration});
}

/// Utility class for converting API alerts to AlertMarkers with M3U8 offset support
class AlertConverter {
  /// Parse TS filename to extract timestamp
  /// Format: 2025-12-11_05-04-26-000000.ts
  static DateTime? parseTimestampFromFilename(String tsUrl) {
    final regex = RegExp(r'(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})');
    final match = regex.firstMatch(tsUrl);

    if (match != null) {
      try {
        return DateTime.utc(
          int.parse(match.group(1)!), // year
          int.parse(match.group(2)!), // month
          int.parse(match.group(3)!), // day
          int.parse(match.group(4)!), // hour
          int.parse(match.group(5)!), // minute
          int.parse(match.group(6)!), // second
        );
      } catch (e) {
        debugPrint('⚠️ Error parsing timestamp from $tsUrl: $e');
      }
    }
    return null;
  }

  /// Build complete timeline by parsing all M3U8 segments
  /// Returns map of timestamp -> segment info (position and duration)
  static Future<Map<DateTime, SegmentInfo>> buildSegmentTimeline({
    required String m3u8Url,
  }) async {
    final Map<DateTime, SegmentInfo> timeline = {};

    try {
      debugPrint('🗺️  Building complete segment timeline...');

      final response = await http.get(Uri.parse(m3u8Url));
      if (response.statusCode != 200) {
        debugPrint('⚠️ Failed to fetch M3U8: ${response.statusCode}');
        return timeline;
      }

      final lines = response.body.split('\n');
      double cumulativePosition = 0.0;
      double? currentDuration;
      int segmentCount = 0;
      DateTime? previousTimestamp;
      final List<String> segmentLogs = [];

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        // Parse duration from #EXTINF tag
        if (line.startsWith('#EXTINF:')) {
          final match = RegExp(r'#EXTINF:([\d.]+)').firstMatch(line);
          if (match != null) {
            final parsed = double.tryParse(match.group(1)!);
            currentDuration = parsed ?? 0.0;
          }
        }

        // Parse TS segment
        if (line.contains('.ts') && currentDuration != null) {
          final timestamp = parseTimestampFromFilename(line);

          if (timestamp != null) {
            timeline[timestamp] = SegmentInfo(
              position: cumulativePosition,
              duration: currentDuration,
            );
            segmentCount++;

            // Check for gaps (if timestamp jumps more than 15 seconds from previous)
            if (previousTimestamp != null) {
              final timeDiff = timestamp
                  .difference(previousTimestamp)
                  .inSeconds;
              if (timeDiff > 15) {
                segmentLogs.add(
                  '   ⚠️  GAP! Segment $segmentCount: \u001b[33m${timestamp.toUtc()}\u001b[0m -> ${cumulativePosition.toStringAsFixed(1)}s (${timeDiff}s time gap)',
                );
              }
            }

            // Log every segment for full accuracy
            segmentLogs.add(
              '   Segment $segmentCount: \u001b[36m${timestamp.toUtc()}\u001b[0m -> ${cumulativePosition.toStringAsFixed(1)}s (dur: ${currentDuration}s)',
            );

            previousTimestamp = timestamp;
            cumulativePosition += currentDuration;
          }

          currentDuration = null;
        }
      }

      // Print all collected logs
      for (final log in segmentLogs) {
        debugPrint(log);
      }

      // Log last 5 segments
      if (segmentCount > 10) {
        debugPrint('   ...');
        final sortedEntries = timeline.entries.toList()
          ..sort((a, b) => a.value.position.compareTo(b.value.position));
        final lastSegments = sortedEntries.skip(
          sortedEntries.length > 5 ? sortedEntries.length - 5 : 0,
        );

        int segNum = segmentCount - lastSegments.length + 1;
        for (final entry in lastSegments) {
          debugPrint(
            '   Segment $segNum: ${entry.key.toUtc()} -> ${entry.value.position.toStringAsFixed(1)}s',
          );
          segNum++;
        }
      }

      debugPrint('');
      debugPrint(
        '   ✅ Built timeline: $segmentCount segments, ${cumulativePosition.toStringAsFixed(1)}s total',
      );
      debugPrint('');

      // Optional: Verify with ffprobe if available (for debugging)
      // Uncomment to enable:
      // try {
      //   await M3u8Verifier.compareTimelineWithActual(
      //     m3u8Url: m3u8Url,
      //     calculatedDuration: cumulativePosition,
      //     expectedDuration: cumulativePosition, // You can pass expected duration here
      //   );
      // } catch (e) {
      //   // ffprobe not available or error, continue without verification
      // }

      return timeline;
    } catch (e) {
      debugPrint('❌ Error building timeline: $e');
      return timeline;
    }
  }

  /// Find actual video position for a timestamp using segment timeline
  static double? findVideoPositionForTime({
    required DateTime alertTime,
    required Map<DateTime, SegmentInfo> timeline,
    bool debug = false,
  }) {
    if (timeline.isEmpty) return null;

    // Find the segment at or before the alert time
    DateTime? segmentBefore;
    SegmentInfo? segmentInfo;

    for (var entry in timeline.entries) {
      if (entry.key.isBefore(alertTime) ||
          entry.key.isAtSameMomentAs(alertTime)) {
        if (segmentBefore == null || entry.key.isAfter(segmentBefore)) {
          segmentBefore = entry.key;
          segmentInfo = entry.value;
        }
      }
    }

    if (segmentBefore != null && segmentInfo != null) {
      // Find the next segment to determine if there's a gap
      final sortedKeys = timeline.keys.toList()..sort();
      final segmentIndex = sortedKeys.indexOf(segmentBefore);
      DateTime? nextSegmentTimestamp;
      SegmentInfo? nextSegmentInfo;
      
      if (segmentIndex >= 0 && segmentIndex < sortedKeys.length - 1) {
        nextSegmentTimestamp = sortedKeys[segmentIndex + 1];
        nextSegmentInfo = timeline[nextSegmentTimestamp];
      }
      
      // Calculate time difference between alert and segment
      final timeDiff = alertTime.difference(segmentBefore).inMilliseconds / 1000.0;
      
      // If there's a next segment, check if alert is closer to it
      double offsetWithinSegment = 0.0;
      if (nextSegmentTimestamp != null && nextSegmentInfo != null) {
        final timeToNext = nextSegmentTimestamp.difference(alertTime).inMilliseconds / 1000.0;
        
        // If alert is closer to next segment or between segments
        if (timeToNext >= 0 && timeToNext < timeDiff) {
          // Alert is closer to next segment, use that segment's position
          // But we need to calculate backwards from next segment
          final timeFromNext = nextSegmentTimestamp.difference(alertTime).inMilliseconds / 1000.0;
          offsetWithinSegment = nextSegmentInfo.duration - timeFromNext.clamp(0.0, nextSegmentInfo.duration);
          final finalPosition = nextSegmentInfo.position - offsetWithinSegment;
          
          if (debug) {
            debugPrint(
              '      [Mapping] Alert: $alertTime, Using NEXT segment: $nextSegmentTimestamp, SegmentPos: ${nextSegmentInfo.position.toStringAsFixed(1)}s, TimeFromNext: ${timeFromNext.toStringAsFixed(1)}s, Offset: ${offsetWithinSegment.toStringAsFixed(1)}s, FinalPos: ${finalPosition.toStringAsFixed(1)}s',
            );
          }
          return finalPosition;
        }
      }
      
      // Alert is within or before the current segment
      // Use the time difference, but clamp to segment duration
      offsetWithinSegment = timeDiff.clamp(0.0, segmentInfo.duration);
      final finalPosition = segmentInfo.position + offsetWithinSegment;
      
      if (debug) {
        debugPrint(
          '      [Mapping] Alert: $alertTime, Segment: $segmentBefore, SegmentPos: ${segmentInfo.position.toStringAsFixed(1)}s, TimeDiff: ${timeDiff.toStringAsFixed(1)}s, SegmentDur: ${segmentInfo.duration.toStringAsFixed(1)}s, Offset: ${offsetWithinSegment.toStringAsFixed(1)}s, FinalPos: ${finalPosition.toStringAsFixed(1)}s',
        );
      }
      return finalPosition;
    }
    if (debug) {
      debugPrint(
        '      [Mapping] Alert: $alertTime, No matching segment found',
      );
    }
    return null;
  }

  /// Fetch M3U8 and detect timeline offset by comparing first TS timestamp
  /// with API fileStartTime
  static Future<double> detectTimelineOffset({
    required String m3u8Url,
    required DateTime apiFileStartTime,
  }) async {
    try {
      debugPrint('🔍 Detecting timeline offset from M3U8...');
      debugPrint('   M3U8 URL: $m3u8Url');
      debugPrint('   API fileStartTime: $apiFileStartTime');

      // Fetch M3U8 content
      final response = await http.get(Uri.parse(m3u8Url));
      if (response.statusCode != 200) {
        debugPrint('⚠️ Failed to fetch M3U8: ${response.statusCode}');
        return 0.0;
      }

      final lines = response.body.split('\n');
      DateTime? firstTsTimestamp;

      // Parse M3U8 to find first TS segment
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        // Check for TS segment URL
        if (line.contains('.ts')) {
          final timestamp = parseTimestampFromFilename(line);

          if (firstTsTimestamp == null && timestamp != null) {
            firstTsTimestamp = timestamp;
            debugPrint('   First TS segment: $line');
            debugPrint('   First TS timestamp: $firstTsTimestamp');
            break;
          }
        }
      }

      if (firstTsTimestamp == null) {
        debugPrint('⚠️ Could not find first TS timestamp in M3U8');
        return 0.0;
      }

      // Calculate offset: difference between first TS and API start
      // If they match, offset = 0 (video starts at correct time)
      // If first TS is LATER than API start, offset is positive (video starts later)
      final offsetSeconds =
          firstTsTimestamp.difference(apiFileStartTime).inMilliseconds / 1000.0;

      debugPrint('');
      debugPrint('📊 Timeline Analysis:');
      debugPrint('   ─────────────────────────────────────');
      debugPrint('   API fileStartTime:   ${apiFileStartTime.toUtc()}');
      debugPrint('   First TS timestamp:  ${firstTsTimestamp.toUtc()}');
      debugPrint(
        '   Time difference:     ${offsetSeconds.toStringAsFixed(2)}s',
      );
      debugPrint('   ─────────────────────────────────────');

      if (offsetSeconds == 0) {
        debugPrint('   ✅ Perfect match! No offset needed.');
      } else if (offsetSeconds > 0) {
        debugPrint('   ⚠️  First TS starts ${offsetSeconds}s AFTER API time');
        debugPrint('   📝 Video player timeline is shifted forward');
      } else {
        debugPrint(
          '   ⚠️  First TS starts ${offsetSeconds.abs()}s BEFORE API time',
        );
        debugPrint('   📝 Video player timeline is shifted backward');
      }
      debugPrint('');

      return offsetSeconds;
    } catch (e) {
      debugPrint('❌ Error detecting offset: $e');
      return 0.0;
    }
  }

  /// Convert list of AiAlerts to AlertMarkers based on video timeline
  ///
  /// Parameters:
  /// - [alerts]: List of AI alerts from the API
  /// - [fileStartTime]: UTC start time of the video file (from API)
  /// - [fileEndTime]: UTC end time of the video file (optional, for validation)
  /// - [m3u8StartTime]: Actual M3U8 file start time (extracted from URL or provided separately)
  ///
  /// Returns a list of AlertMarkers with calculated timeInSeconds
  static List<AlertMarker> convertAlertsToMarkers({
    required List<AiAlert> alerts,
    required DateTime fileStartTime,
    DateTime? fileEndTime,
    DateTime? m3u8StartTime,
    Color? defaultColor,
    IconData? defaultIcon,
    int defaultDisplayDuration = 3000,
  }) {
    final List<AlertMarker> markers = [];

    debugPrint('📝 Converting ${alerts.length} alerts to markers...');
    debugPrint('   Video fileStartTime: ${fileStartTime.toUtc()}');
    if (fileEndTime != null) {
      debugPrint('   Video fileEndTime:   ${fileEndTime.toUtc()}');
      final duration = fileEndTime.difference(fileStartTime).inSeconds;
      debugPrint(
        '   Video duration:      ${duration}s (${(duration / 60).toStringAsFixed(1)} min)',
      );
    }
    debugPrint('');

    // Calculate offset between M3U8 actual start and API fileStartTime
    final double m3u8Offset = m3u8StartTime != null
        ? fileStartTime.difference(m3u8StartTime).inMilliseconds / 1000.0
        : 0.0;

    for (int i = 0; i < alerts.length; i++) {
      final alert = alerts[i];

      // Calculate the time difference in seconds from the start of the video
      final Duration timeDifference = alert.createdAt.difference(fileStartTime);
      final double timeInSeconds = timeDifference.inMilliseconds / 1000.0;

      debugPrint('   Alert ${i + 1}:');
      debugPrint('      Time: ${alert.createdAt.toUtc()}');
      debugPrint(
        '      Position: ${timeInSeconds.toStringAsFixed(1)}s from start',
      );

      // Only add markers that are within the video duration
      // Skip alerts that occurred before the video started
      if (timeInSeconds >= 0) {
        // If fileEndTime is provided, validate the alert is within video bounds
        if (fileEndTime != null) {
          final Duration videoDuration = fileEndTime.difference(fileStartTime);
          if (timeInSeconds > videoDuration.inSeconds) {
            debugPrint('      ⚠️  Skipped (after video ends)');
            continue; // Skip alerts after video ends
          }
        }

        // Add M3U8 offset to get the actual position in the video file
        final double actualTimeInVideo = timeInSeconds + m3u8Offset;

        debugPrint('      ✅ Added at ${actualTimeInVideo.toStringAsFixed(1)}s');

        markers.add(
          AlertMarker(
            timeInSeconds: actualTimeInVideo,
            message: alert.text,
            color: defaultColor ?? _getColorForAlertType(alert.title),
            icon: defaultIcon ?? _getIconForAlertType(alert.title),
            displayDuration: defaultDisplayDuration,
          ),
        );
      } else {
        debugPrint('      ⚠️  Skipped (before video starts)');
      }
    }

    debugPrint('');
    debugPrint('✅ Created ${markers.length} alert markers');
    debugPrint('');

    // Sort markers by time
    markers.sort((a, b) => a.timeInSeconds.compareTo(b.timeInSeconds));

    return markers;
  }

  /// Extract M3U8 start time from URL if available
  /// Example: index-1765393200.m3u8 -> timestamp 1765393200
  static DateTime? extractM3u8StartTimeFromUrl(String fileUrl) {
    final regex = RegExp(r'index-(\d+)\.m3u8');
    final match = regex.firstMatch(fileUrl);

    if (match != null && match.groupCount >= 1) {
      final timestamp = int.tryParse(match.group(1)!);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          timestamp * 1000,
          isUtc: true,
        );
      }
    }

    return null;
  }

  /// Convert VideoApiResponse directly to AlertMarkers
  /// Automatically extracts M3U8 start time from URL
  static List<AlertMarker> fromVideoApiResponse(
    VideoApiResponse response, {
    Color? defaultColor,
    IconData? defaultIcon,
    int defaultDisplayDuration = 3000,
    bool autoDetectM3u8Offset = true,
    double manualOffsetSeconds =
        0.0, // Manual correction for timeline discrepancies
  }) {
    DateTime? m3u8StartTime;

    if (autoDetectM3u8Offset) {
      m3u8StartTime = extractM3u8StartTimeFromUrl(response.fileUrl);

      if (m3u8StartTime != null) {
        final offset = response.fileStartTime
            .difference(m3u8StartTime)
            .inSeconds;
        debugPrint('🎬 M3U8 Offset Detection:');
        debugPrint('   M3U8 file starts at: $m3u8StartTime');
        debugPrint('   API fileStartTime:   ${response.fileStartTime}');
        debugPrint(
          '   Offset: ${offset}s (${(offset / 3600).toStringAsFixed(2)}h)',
        );
      }
    }

    final markers = convertAlertsToMarkers(
      alerts: response.aiAlert,
      fileStartTime: response.fileStartTime,
      fileEndTime: response.fileEndTime,
      m3u8StartTime: m3u8StartTime,
      defaultColor: defaultColor,
      defaultIcon: defaultIcon,
      defaultDisplayDuration: defaultDisplayDuration,
    );

    // Apply manual offset correction if needed
    if (manualOffsetSeconds != 0.0) {
      debugPrint('⚙️ Applying manual offset: ${manualOffsetSeconds}s');
      return markers.map((marker) {
        return AlertMarker(
          timeInSeconds: marker.timeInSeconds + manualOffsetSeconds,
          message: marker.message,
          color: marker.color,
          icon: marker.icon,
          displayDuration: marker.displayDuration,
        );
      }).toList();
    }

    return markers;
  }

  /// Convert VideoApiResponse with timeline-based position calculation
  /// Parses entire M3U8 to account for gaps and discontinuities
  /// 
  /// [useSimpleOffsetCalculation]: If true, uses a simpler offset-based approach
  ///   that may be more accurate for videos with consistent timing. If false,
  ///   uses full timeline parsing which accounts for gaps.
  /// [manualOffsetSeconds]: Manual correction offset in seconds. Positive values
  ///   move alerts later, negative values move them earlier. Use this to fine-tune
  ///   if automatic calculation is still off.
  static Future<List<AlertMarker>> fromVideoApiResponseAsync(
    VideoApiResponse response, {
    Color? defaultColor,
    IconData? defaultIcon,
    int defaultDisplayDuration = 3000,
    bool detectTimelineOffset = true,
    bool useSimpleOffsetCalculation = false,
    double manualOffsetSeconds = 0.0,
  }) async {
    if (!detectTimelineOffset) {
      // Fall back to simple conversion
      return convertAlertsToMarkers(
        alerts: response.aiAlert,
        fileStartTime: response.fileStartTime,
        fileEndTime: response.fileEndTime,
        m3u8StartTime: null,
        defaultColor: defaultColor,
        defaultIcon: defaultIcon,
        defaultDisplayDuration: defaultDisplayDuration,
      );
    }

    // Option 1: Simple offset-based calculation (may be more accurate)
    if (useSimpleOffsetCalculation) {
      debugPrint('🎯 Using simple offset-based calculation...');
      final offset = await AlertConverter.detectTimelineOffset(
        m3u8Url: response.fileUrl,
        apiFileStartTime: response.fileStartTime,
      );
      
      debugPrint('');
      debugPrint('📝 Converting ${response.aiAlert.length} alerts with offset correction...');
      debugPrint('   Detected offset: ${offset.toStringAsFixed(1)}s (${(offset / 60).toStringAsFixed(1)} min)');
      if (manualOffsetSeconds != 0.0) {
        debugPrint('   Manual offset: ${manualOffsetSeconds.toStringAsFixed(1)}s');
      }
      debugPrint('');
      
      final List<AlertMarker> markers = [];
      for (int i = 0; i < response.aiAlert.length; i++) {
        final alert = response.aiAlert[i];
        // Calculate position relative to fileStartTime
        final double timeFromStart = alert.createdAt
            .difference(response.fileStartTime)
            .inMilliseconds / 1000.0;
        
        // Apply offset correction: if offset is positive (fileStartTime is after first segment),
        // we need to subtract it to align with video player timeline
        double correctedPosition = timeFromStart - offset;
        
        // Apply manual offset if provided
        if (manualOffsetSeconds != 0.0) {
          correctedPosition = correctedPosition + manualOffsetSeconds;
        }
        
        debugPrint('   Alert #${i + 1}: ${alert.createdAt.toUtc()}');
        debugPrint('      Time from start: ${timeFromStart.toStringAsFixed(1)}s');
        debugPrint('      Offset correction: -${offset.toStringAsFixed(1)}s');
        if (manualOffsetSeconds != 0.0) {
          debugPrint('      Manual offset: ${manualOffsetSeconds.toStringAsFixed(1)}s');
        }
        debugPrint('      Final position: ${correctedPosition.toStringAsFixed(1)}s');
        debugPrint('');
        
        if (correctedPosition >= 0) {
          markers.add(
            AlertMarker(
              timeInSeconds: correctedPosition,
              message: alert.text,
              color: defaultColor ?? _getColorForAlertType(alert.title),
              icon: defaultIcon ?? _getIconForAlertType(alert.title),
              displayDuration: defaultDisplayDuration,
            ),
          );
        }
      }
      
      markers.sort((a, b) => a.timeInSeconds.compareTo(b.timeInSeconds));
      return markers;
    }

    // Option 2: Full timeline-based calculation (accounts for gaps)
    // Build complete timeline from M3U8
    debugPrint('🎯 Using full timeline-based position calculation...');
    final timeline = await buildSegmentTimeline(m3u8Url: response.fileUrl);

    if (timeline.isEmpty) {
      debugPrint('⚠️  Timeline parsing failed, using simple time calculation');
      return convertAlertsToMarkers(
        alerts: response.aiAlert,
        fileStartTime: response.fileStartTime,
        fileEndTime: response.fileEndTime,
        m3u8StartTime: null,
        defaultColor: defaultColor,
        defaultIcon: defaultIcon,
        defaultDisplayDuration: defaultDisplayDuration,
      );
    }

    // Find the first segment timestamp and calculate offset
    final sortedTimelineEntries = timeline.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    if (sortedTimelineEntries.isEmpty) {
      debugPrint('⚠️  No segments found in timeline');
      return convertAlertsToMarkers(
        alerts: response.aiAlert,
        fileStartTime: response.fileStartTime,
        fileEndTime: response.fileEndTime,
        m3u8StartTime: null,
        defaultColor: defaultColor,
        defaultIcon: defaultIcon,
        defaultDisplayDuration: defaultDisplayDuration,
      );
    }

    final firstSegmentTimestamp = sortedTimelineEntries.first.key;
    final firstSegmentInfo = sortedTimelineEntries.first.value;
    final firstSegmentPosition = firstSegmentInfo.position;
    
    // Calculate offset: difference between first segment timestamp and API fileStartTime
    // This tells us how much earlier/later the video actually starts compared to fileStartTime
    final double timelineOffset = response.fileStartTime
        .difference(firstSegmentTimestamp)
        .inMilliseconds / 1000.0;

    debugPrint('');
    debugPrint('📊 Timeline Alignment Analysis:');
    debugPrint('   ─────────────────────────────────────');
    debugPrint('   API fileStartTime:     ${response.fileStartTime.toUtc()}');
    debugPrint('   First segment time:    ${firstSegmentTimestamp.toUtc()}');
    debugPrint('   First segment position: ${firstSegmentPosition.toStringAsFixed(1)}s');
    debugPrint('   Timeline offset:       ${timelineOffset.toStringAsFixed(1)}s');
    if (timelineOffset.abs() > 60) {
      debugPrint('   ⚠️  Significant offset detected: ${(timelineOffset / 60).toStringAsFixed(1)} minutes');
    }
    debugPrint('   ─────────────────────────────────────');
    debugPrint('');

    // --- Timeline drift check ---
    double timelineDuration = 0.0;
    if (sortedTimelineEntries.length > 1) {
      final lastEntry = sortedTimelineEntries.last;
      timelineDuration = lastEntry.value.position - firstSegmentPosition;
    }
    double expectedDuration = response.fileEndTime
        .difference(response.fileStartTime)
        .inSeconds
        .toDouble();
    double drift = (timelineDuration - expectedDuration).abs();
    debugPrint('🕒 Timeline drift analysis:');
    debugPrint('   Timeline duration: ${timelineDuration.toStringAsFixed(1)}s');
    debugPrint('   Expected duration: ${expectedDuration.toStringAsFixed(1)}s');
    debugPrint('   Drift: ${drift.toStringAsFixed(1)}s');
    if (drift > 2.0) {
      debugPrint(
        '⚠️  Timeline drift detected! Will apply proportional correction to alert markers.',
      );
    }
    debugPrint('');

    // Convert alerts using timeline-based positions
    final List<AlertMarker> markers = [];
    debugPrint(
      '📝 Converting ${response.aiAlert.length} alerts using timeline...',
    );
    debugPrint('');
    for (int i = 0; i < response.aiAlert.length; i++) {
      final alert = response.aiAlert[i];
      debugPrint('   Alert  #${i + 1}: ${alert.createdAt.toUtc()}');
      
      // Find position using timeline (this gives us position relative to first segment)
      final position = findVideoPositionForTime(
        alertTime: alert.createdAt,
        timeline: timeline,
        debug: true,
      );
      
      if (position != null) {
        // The position from findVideoPositionForTime is calculated based on segment timestamps
        // It finds the segment containing the alert and calculates position based on cumulative durations
        // However, we need to account for the offset between fileStartTime and first segment timestamp
        
        // Calculate what the position SHOULD be based on simple time difference
        final double expectedPositionFromFileStart = alert.createdAt
            .difference(response.fileStartTime)
            .inMilliseconds / 1000.0;
        
        // The timeline position is based on segment timestamps, not fileStartTime
        // If there's an offset between first segment and fileStartTime, we need to adjust
        // timelineOffset = fileStartTime - firstSegmentTimestamp
        // If positive: fileStartTime is AFTER first segment (video starts earlier)
        // If negative: fileStartTime is BEFORE first segment (video starts later)
        
        double finalPosition = position;
        
        // Apply timeline offset correction
        // The direction depends on how the video player interprets the timeline
        // Try both directions and see which aligns better with actual video playback
        // If alerts appear too early: try subtracting offset (position - timelineOffset)
        // If alerts appear too late: try adding offset (position + timelineOffset)
        
        // Current approach: add offset
        // If this doesn't work, try: finalPosition = position - timelineOffset;
        finalPosition = position - timelineOffset;
        
        debugPrint(
          '      ⚠️  Using REVERSED offset direction (subtracting instead of adding)',
        );
        debugPrint(
          '      If alerts are still wrong, try changing line 668 to: finalPosition = position + timelineOffset;',
        );
        
        debugPrint(
          '      Expected (from fileStart): ${expectedPositionFromFileStart.toStringAsFixed(1)}s',
        );
        debugPrint(
          '      Position (from timeline): ${position.toStringAsFixed(1)}s',
        );
        debugPrint(
          '      Timeline offset: ${timelineOffset.toStringAsFixed(1)}s',
        );
        debugPrint(
          '      Adjusted position: ${finalPosition.toStringAsFixed(1)}s',
        );
        
        // Apply proportional correction if drift is significant
        if (drift > 2.0 && timelineDuration > 0 && expectedDuration > 0) {
          // Scale the position proportionally to match expected duration
          final double scaledPosition = (finalPosition / timelineDuration) * expectedDuration;
          debugPrint(
            '      Timeline duration: ${timelineDuration.toStringAsFixed(1)}s',
          );
          debugPrint(
            '      Expected duration: ${expectedDuration.toStringAsFixed(1)}s',
          );
          debugPrint(
            '      Drift correction: ${scaledPosition.toStringAsFixed(1)}s',
          );
          finalPosition = scaledPosition;
        }
        
        // Apply manual offset correction if provided
        if (manualOffsetSeconds != 0.0) {
          finalPosition = finalPosition + manualOffsetSeconds;
          debugPrint(
            '      Manual offset applied: ${manualOffsetSeconds.toStringAsFixed(1)}s',
          );
          debugPrint(
            '      Position after manual offset: ${finalPosition.toStringAsFixed(1)}s',
          );
        }
        
        // Ensure position is non-negative
        if (finalPosition < 0) {
          finalPosition = 0;
        }
        
        // Calculate difference from expected position for debugging
        final difference = finalPosition - expectedPositionFromFileStart;
        debugPrint(
          '      ✔️ Final position: ${finalPosition.toStringAsFixed(1)}s',
        );
        debugPrint(
          '      Difference from expected: ${difference.toStringAsFixed(1)}s (${(difference / 60).toStringAsFixed(1)} min)',
        );
        if (difference.abs() > 60) {
          debugPrint(
            '      ⚠️  Large difference detected! Consider using manualOffsetSeconds: ${(-difference).toStringAsFixed(1)}',
          );
        }
        debugPrint('');
        
        markers.add(
          AlertMarker(
            timeInSeconds: finalPosition,
            message: alert.text,
            color: defaultColor ?? _getColorForAlertType(alert.title),
            icon: defaultIcon ?? _getIconForAlertType(alert.title),
            displayDuration: defaultDisplayDuration,
          ),
        );
      } else {
        debugPrint('      ⚠️  Could not find position in timeline');
        debugPrint('');
        // Fallback: use simple time calculation
        final double fallbackPosition = alert.createdAt
            .difference(response.fileStartTime)
            .inMilliseconds / 1000.0;
        if (fallbackPosition >= 0) {
          debugPrint('      Using fallback position: ${fallbackPosition.toStringAsFixed(1)}s');
          debugPrint('');
          markers.add(
            AlertMarker(
              timeInSeconds: fallbackPosition,
              message: alert.text,
              color: defaultColor ?? _getColorForAlertType(alert.title),
              icon: defaultIcon ?? _getIconForAlertType(alert.title),
              displayDuration: defaultDisplayDuration,
            ),
          );
        }
      }
      debugPrint('');
    }
    debugPrint('✅ Created ${markers.length} alert markers using timeline');
    debugPrint('   Final positions:');
    for (var i = 0; i < markers.length; i++) {
      debugPrint(
        '      Alert ${i + 1}: ${markers[i].timeInSeconds.toStringAsFixed(1)}s',
      );
    }
    debugPrint('');

    markers.sort((a, b) => a.timeInSeconds.compareTo(b.timeInSeconds));
    return markers;
  }

  /// Create a custom marker with explicit time
  static AlertMarker createCustomMarker({
    required AiAlert alert,
    required DateTime fileStartTime,
    DateTime? m3u8StartTime,
    Color? color,
    IconData? icon,
    int displayDuration = 3000,
    Widget? customWidget,
  }) {
    final Duration timeDifference = alert.createdAt.difference(fileStartTime);
    double timeInSeconds = timeDifference.inMilliseconds / 1000.0;

    // Add M3U8 offset if provided
    if (m3u8StartTime != null) {
      final double offset =
          fileStartTime.difference(m3u8StartTime).inMilliseconds / 1000.0;
      timeInSeconds += offset;
    }

    return AlertMarker(
      timeInSeconds: timeInSeconds,
      message: alert.text,
      color: color ?? _getColorForAlertType(alert.title),
      icon: icon ?? _getIconForAlertType(alert.title),
      displayDuration: displayDuration,
      customWidget: customWidget,
    );
  }

  /// Get color based on alert type/title
  static Color _getColorForAlertType(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('parcel')) {
      return Colors.orange;
    } else if (lowerTitle.contains('person')) {
      return Colors.blue;
    } else if (lowerTitle.contains('vehicle') || lowerTitle.contains('car')) {
      return Colors.purple;
    } else if (lowerTitle.contains('animal') || lowerTitle.contains('pet')) {
      return Colors.green;
    } else if (lowerTitle.contains('motion')) {
      return Colors.grey;
    } else if (lowerTitle.contains('sound') || lowerTitle.contains('audio')) {
      return Colors.teal;
    } else if (lowerTitle.contains('alert') || lowerTitle.contains('warning')) {
      return Colors.red;
    }

    return Colors.blue; // default color
  }

  /// Get icon based on alert type/title
  static IconData _getIconForAlertType(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('parcel') || lowerTitle.contains('package')) {
      return Icons.inventory_2;
    } else if (lowerTitle.contains('person') || lowerTitle.contains('human')) {
      return Icons.person;
    } else if (lowerTitle.contains('vehicle') || lowerTitle.contains('car')) {
      return Icons.directions_car;
    } else if (lowerTitle.contains('animal') || lowerTitle.contains('pet')) {
      return Icons.pets;
    } else if (lowerTitle.contains('motion')) {
      return Icons.directions_walk;
    } else if (lowerTitle.contains('sound') || lowerTitle.contains('audio')) {
      return Icons.volume_up;
    } else if (lowerTitle.contains('doorbell') || lowerTitle.contains('door')) {
      return Icons.doorbell;
    }

    return Icons.warning; // default icon
  }
}

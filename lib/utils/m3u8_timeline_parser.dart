/// Enhanced M3U8 Timeline Parser
///
/// Problem: Video player's timeline doesn't match simple duration calculation
/// Solution: Parse actual TS segment timestamps from M3U8 file
///
/// Example M3U8 structure:
/// ```
/// #EXTINF:8
/// 2025-12-11_05-04-26-000000.ts  <- First segment at 05:04:26
/// #EXTINF:8
/// 2025-12-11_05-04-35-000000.ts  <- +9 seconds (not +8!)
/// ```
///
/// This shows there can be gaps in the recording, so we need to use
/// the actual timestamps from TS filenames, not just sum durations.

import 'package:flutter/material.dart';
rt '../models/alert_marker.dart';
import '../models/video_api_response.dart';

class M3u8TimelineParser {
  /// Parse TS filename to get actual timestamp
  /// Format: 2025-12-11_05-04-26-000000.ts
  static DateTime? parseTimestampFromFilename(String filename) {
    final regex = RegExp(r'(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})');
    final match = regex.firstMatch(filename);

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
        debugPrint('Error parsing timestamp from $filename: $e');
      }
    }
    return null;
  }

  /// Find the segment index and offset for a given UTC time
  /// This requires fetching the M3U8 and parsing all segment timestamps
  static Future<double?> calculateVideoPositionForTime({
    required DateTime targetTime,
    required String m3u8Url,
  }) async {
    // TODO: This would require fetching and parsing the M3U8
    // For now, we'll use a simpler approach
    return null;
  }

  /// Convert alerts using simple time difference (current approach)
  /// This assumes continuous recording without gaps
  static List<AlertMarker> convertAlertsSimple({
    required List<AiAlert> alerts,
    required DateTime fileStartTime,
    DateTime? fileEndTime,
  }) {
    final List<AlertMarker> markers = [];

    for (final alert in alerts) {
      final Duration timeDifference = alert.createdAt.difference(fileStartTime);
      final double timeInSeconds = timeDifference.inMilliseconds / 1000.0;

      if (timeInSeconds >= 0) {
        if (fileEndTime != null) {
          final Duration videoDuration = fileEndTime.difference(fileStartTime);
          if (timeInSeconds > videoDuration.inSeconds) {
            continue;
          }
        }

        markers.add(
          AlertMarker(
            timeInSeconds: timeInSeconds,
            message: alert.text,
            color: Colors.green,
            icon: Icons.notifications,
            displayDuration: 3000,
          ),
        );
      }
    }

    markers.sort((a, b) => a.timeInSeconds.compareTo(b.timeInSeconds));
    return markers;
  }
}


import 'package:flutter/material.dart';

import '../models/alert_marker.dart';
import '../models/video_api_response.dart';

/// Utility class for converting API alerts to AlertMarkers with M3U8 offset support
class AlertConverter {
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

    // Calculate offset between M3U8 actual start and API fileStartTime
    final double m3u8Offset = m3u8StartTime != null
        ? fileStartTime.difference(m3u8StartTime).inMilliseconds / 1000.0
        : 0.0;

    for (final alert in alerts) {
      // Calculate the time difference in seconds from the start of the video
      final Duration timeDifference = alert.createdAt.difference(fileStartTime);
      final double timeInSeconds = timeDifference.inMilliseconds / 1000.0;

      // Only add markers that are within the video duration
      // Skip alerts that occurred before the video started
      if (timeInSeconds >= 0) {
        // If fileEndTime is provided, validate the alert is within video bounds
        if (fileEndTime != null) {
          final Duration videoDuration = fileEndTime.difference(fileStartTime);
          if (timeInSeconds > videoDuration.inSeconds) {
            continue; // Skip alerts after video ends
          }
        }

        // Add M3U8 offset to get the actual position in the video file
        final double actualTimeInVideo = timeInSeconds + m3u8Offset;

        markers.add(
          AlertMarker(
            timeInSeconds: actualTimeInVideo,
            message: alert.text,
            color: defaultColor ?? _getColorForAlertType(alert.title),
            icon: defaultIcon ?? _getIconForAlertType(alert.title),
            displayDuration: defaultDisplayDuration,
          ),
        );
      }
    }

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

    return convertAlertsToMarkers(
      alerts: response.aiAlert,
      fileStartTime: response.fileStartTime,
      fileEndTime: response.fileEndTime,
      m3u8StartTime: m3u8StartTime,
      defaultColor: defaultColor,
      defaultIcon: defaultIcon,
      defaultDisplayDuration: defaultDisplayDuration,
    );
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

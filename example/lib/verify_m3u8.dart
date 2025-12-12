import 'package:flutter/material.dart';
import 'package:video_player_m3u8_alerts/video_player_m3u8_alerts.dart';

/// Example script to verify M3U8 file using ffprobe
/// Run this to check actual segment durations vs declared durations
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const m3u8Url =
      'https://media-assets-test.irvinei.com/BJQMgFq81ZXu0mFg9q5tECPN7EwFTvfL5fsBM8FrDFxeEidbvnP51v0JRyib/RP1A.200720.012/index-1765393200.m3u8';

  debugPrint('🔍 M3U8 Verification Tool');
  debugPrint('==================================================');
  debugPrint('');

  // Verify M3U8 file
  final result = await M3u8Verifier.verifyM3u8File(
    m3u8Url: m3u8Url,
    maxSegmentsToCheck: 20, // Check first 20 segments
  );

  if (result['success'] == true) {
    debugPrint('✅ Verification Results:');
    debugPrint('   Segments checked: ${result['segmentsChecked']}');
    debugPrint('   Total declared duration: ${result['totalDuration']}s');
    debugPrint('');

    // Show segment details
    final segments = result['segments'] as List<Map<String, dynamic>>;
    for (final segment in segments) {
      if (segment['actualDuration'] != null) {
        final diff = segment['difference'] as double;
        if (diff.abs() > 0.5) {
          debugPrint(
            '   Segment ${segment['index']}: Declared=${segment['declaredDuration']}s, '
            'Actual=${segment['actualDuration']}s, Diff=${diff.toStringAsFixed(2)}s',
          );
        }
      }
    }
  } else {
    debugPrint('❌ Verification failed:');
    final errors = result['errors'] as List<String>;
    for (final error in errors) {
      debugPrint('   $error');
    }
  }

  // Get total duration
  debugPrint('');
  debugPrint('📏 Getting total M3U8 duration...');
  final totalDuration = await M3u8Verifier.getM3u8Duration(m3u8Url);
  if (totalDuration != null) {
    debugPrint('   Total duration: ${totalDuration.toStringAsFixed(1)}s');
    debugPrint('   Total duration: ${(totalDuration / 60).toStringAsFixed(1)} minutes');
    debugPrint('   Total duration: ${(totalDuration / 3600).toStringAsFixed(2)} hours');
  }
}


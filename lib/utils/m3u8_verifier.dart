import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../video_player_m3u8_alerts_platform_interface.dart';

/// Utility class to verify M3U8 file and TS segment durations using ffprobe/ffmpeg
class M3u8Verifier {
  /// Verify M3U8 file structure and get actual segment durations
  /// Requires ffprobe to be installed on the system
  static Future<Map<String, dynamic>> verifyM3u8File({
    required String m3u8Url,
    int maxSegmentsToCheck = 10,
  }) async {
    final Map<String, dynamic> result = {
      'success': false,
      'm3u8Url': m3u8Url,
      'segments': <Map<String, dynamic>>[],
      'totalDuration': 0.0,
      'errors': <String>[],
    };

    try {
      debugPrint('🔍 Verifying M3U8 file: $m3u8Url');
      
      // Reset the log flags for this verification session
      _hasLoggedAvFoundationLimitation = false;
      _hasLoggedHttpFallback = false;
      
      // Check if ffprobe is available
      debugPrint('   🔍 Checking for ffprobe...');
      final ffprobeAvailable = await _checkFfprobeAvailable();
      final useVideoPlayerFallback = !ffprobeAvailable;
      
      if (useVideoPlayerFallback) {
        final platform = Platform.operatingSystem;
        final isIOS = platform == 'ios';
        final isAndroid = platform == 'android';
        
        if (isIOS || isAndroid) {
          debugPrint('   ℹ️  Using video_player plugin fallback (ffprobe not available on iOS/Android)');
        } else {
          debugPrint('   ℹ️  Using video_player plugin fallback (ffprobe not found)');
        }
      }

      // Fetch M3U8 content
      debugPrint('📥 Fetching M3U8 file...');
      final response = await http.get(Uri.parse(m3u8Url));
      if (response.statusCode != 200) {
        result['errors'].add('Failed to fetch M3U8: ${response.statusCode}');
        return result;
      }

      final lines = response.body.split('\n');
      final baseUrl = m3u8Url.substring(0, m3u8Url.lastIndexOf('/') + 1);
      
      double? currentDuration;
      int segmentIndex = 0;
      double totalDuration = 0.0;
      final List<Map<String, dynamic>> segments = [];

      debugPrint('📊 Parsing M3U8 segments...');
      
      for (int i = 0; i < lines.length && segmentIndex < maxSegmentsToCheck; i++) {
        final line = lines[i].trim();

        // Parse duration from #EXTINF tag
        if (line.startsWith('#EXTINF:')) {
          final match = RegExp(r'#EXTINF:([\d.]+)').firstMatch(line);
          if (match != null) {
            currentDuration = double.tryParse(match.group(1)!);
          }
        }

        // Parse TS segment
        if (line.contains('.ts') && currentDuration != null) {
          String segmentUrl = line;
          if (!segmentUrl.startsWith('http')) {
            segmentUrl = baseUrl + segmentUrl;
          }

          final segmentInfo = {
            'index': segmentIndex + 1,
            'url': segmentUrl,
            'declaredDuration': currentDuration,
            'actualDuration': null as double?,
            'difference': null as double?,
          };

          // Try to get actual duration using ffprobe, AVFoundation (iOS), or HTTP fallback
          try {
            debugPrint('   📹 Checking TS file #${segmentIndex + 1}: ${segmentUrl.split('/').last}');
            double? actualDuration;
            
            if (useVideoPlayerFallback) {
              // Try AVFoundation on iOS first (most accurate for simulators)
              if (Platform.isIOS) {
                actualDuration = await _getSegmentDurationViaAVFoundation(segmentUrl);
              }
              
              // Fallback to HTTP if AVFoundation didn't work
              actualDuration ??= await _getSegmentDurationViaHttp(segmentUrl);
            } else {
              // Use ffprobe (more accurate, but not available in simulators)
              actualDuration = await _getSegmentDuration(segmentUrl);
            }
            
            if (actualDuration != null) {
              segmentInfo['actualDuration'] = actualDuration;
              segmentInfo['difference'] = (actualDuration - currentDuration).abs();
              
              // Log each TS file's duration
              String method;
              if (!useVideoPlayerFallback) {
                method = 'ffprobe';
              } else if (Platform.isIOS) {
                method = 'AVFoundation';
              } else {
                method = 'HTTP';
              }
              debugPrint(
                '      ✅ TS #${segmentIndex + 1} duration ($method): ${actualDuration.toStringAsFixed(3)}s (declared: ${currentDuration.toStringAsFixed(3)}s, diff: ${(actualDuration - currentDuration).toStringAsFixed(3)}s)',
              );
              
              if ((actualDuration - currentDuration).abs() > 0.5) {
                debugPrint(
                  '      ⚠️  Segment ${segmentIndex + 1}: Significant mismatch detected!',
                );
              }
            } else {
              // Keep actualDuration as null - display code will show "N/A"
              // Only log per-segment if not on iOS (where we already logged the limitation once)
              if (useVideoPlayerFallback && !Platform.isIOS) {
                debugPrint(
                  '      ℹ️  TS #${segmentIndex + 1}: Declared duration ${currentDuration.toStringAsFixed(3)}s (actual verification requires ffprobe/desktop)',
                );
              } else if (!useVideoPlayerFallback) {
                debugPrint('      ⚠️  TS #${segmentIndex + 1}: Could not get duration from ffprobe');
              }
              // On iOS, we already logged the limitation once, so skip per-segment logging
            }
          } catch (e) {
            debugPrint('      ❌ TS #${segmentIndex + 1}: Error - $e');
            segmentInfo['error'] = e.toString();
          }

          segments.add(segmentInfo);
          totalDuration += currentDuration;
          segmentIndex++;
          currentDuration = null;
        }
      }

      result['success'] = true;
      result['segments'] = segments;
      result['totalDuration'] = totalDuration;
      result['segmentsChecked'] = segmentIndex;

      debugPrint('');
      debugPrint('✅ Verification complete:');
      debugPrint('   Segments checked: $segmentIndex');
      debugPrint('   Total declared duration: ${totalDuration.toStringAsFixed(1)}s');
      debugPrint('');

      return result;
    } catch (e) {
      result['errors'].add('Error verifying M3U8: $e');
      debugPrint('❌ Error: $e');
      return result;
    }
  }

  /// Get the path to ffprobe executable
  static Future<String?> _getFfprobePath() async {
    // First, try to find ffprobe using shell commands (works better in simulators)
    try {
      // Try 'which' command (works on macOS/Linux)
      final whichResult = await Process.run('/bin/sh', [
        '-c',
        'which ffprobe',
      ]);
      if (whichResult.exitCode == 0) {
        final path = whichResult.stdout.toString().trim();
        if (path.isNotEmpty) {
          debugPrint('   ✅ Found ffprobe at: $path (via which)');
          // Verify it works
          final verifyResult = await Process.run(path, ['-version']);
          if (verifyResult.exitCode == 0) {
            return path;
          }
        }
      }
    } catch (e) {
      debugPrint('   ⚠️  Could not use "which" to find ffprobe: $e');
    }

    // Fallback: Try common paths where ffprobe might be installed
    final possiblePaths = [
      'ffprobe', // Try PATH first
      '/opt/homebrew/bin/ffprobe', // Homebrew on Apple Silicon
      '/usr/local/bin/ffprobe', // Homebrew on Intel Mac / Linux
      '/usr/bin/ffprobe', // System installation
    ];

    for (final path in possiblePaths) {
      try {
        final result = await Process.run(path, ['-version']);
        if (result.exitCode == 0) {
          debugPrint('   ✅ Found ffprobe at: $path');
          return path;
        }
      } catch (e) {
        debugPrint('   ⚠️  Tried $path: $e');
        // Continue to next path
        continue;
      }
    }
    
    debugPrint('   ❌ Could not find ffprobe in any standard location');
    return null;
  }

  /// Check if ffprobe is available on the system
  static Future<bool> _checkFfprobeAvailable() async {
    final path = await _getFfprobePath();
    return path != null;
  }

  /// Get segment duration using AVFoundation on iOS
  /// 
  /// **Limitation**: AVFoundation on iOS cannot directly access individual TS segment files.
  /// TS (Transport Stream) files are designed to be accessed through M3U8 playlists, not directly.
  /// This method will typically fail with "Cannot Open" errors (code -11828).
  /// 
  /// For actual duration verification, use ffprobe on desktop platforms.
  /// On iOS simulators, we must rely on declared durations from the M3U8 playlist.
  static bool _hasLoggedAvFoundationLimitation = false;
  
  static Future<double?> _getSegmentDurationViaAVFoundation(String segmentUrl) async {
    try {
      final duration = await VideoPlayerM3u8AlertsPlatform.instance.getSegmentDuration(segmentUrl);
      
      if (duration != null && duration > 0) {
        debugPrint('         ✅ AVFoundation duration: ${duration.toStringAsFixed(3)}s');
        return duration;
      }
      // Silently return null - expected to fail for TS files
      return null;
    } on PlatformException catch (e) {
      // AVFoundation consistently fails on iOS for TS files (error -11828 "Cannot Open")
      // Log this limitation once at the start, not for every segment
      if (!_hasLoggedAvFoundationLimitation) {
        debugPrint('         ℹ️  AVFoundation cannot access TS files directly on iOS (expected)');
        debugPrint('         ℹ️  Using declared durations from M3U8 playlist');
        debugPrint('         ℹ️  For actual duration verification, use ffprobe on desktop');
        _hasLoggedAvFoundationLimitation = true;
      }
      return null;
    } catch (e) {
      // Silently handle - expected to fail on iOS
      return null;
    }
  }

  /// Get segment duration using HTTP requests (fallback for non-iOS or when AVFoundation fails)
  /// Gets file size and estimates duration, or returns null if unavailable
  static bool _hasLoggedHttpFallback = false;
  
  static Future<double?> _getSegmentDurationViaHttp(String segmentUrl) async {
    try {
      // Only log once that we're using HTTP fallback
      if (!_hasLoggedHttpFallback && Platform.isIOS) {
        debugPrint('         📡 Using HTTP to get file sizes (cannot get actual durations on iOS)');
        _hasLoggedHttpFallback = true;
      }
      
      // Remove query parameters from segment URL
      final uri = Uri.parse(segmentUrl);
      final cleanSegmentUrl = uri.resolveUri(Uri(path: uri.path, queryParameters: {})).toString();
      
      int? fileSize;
      
      // Try HEAD request first to get content-length
      try {
        final headResponse = await http.head(Uri.parse(cleanSegmentUrl)).timeout(
          const Duration(seconds: 5),
        );
        
        if (headResponse.statusCode == 200 || headResponse.statusCode == 206) {
          // Check Content-Length header
          final contentLengthHeader = headResponse.headers['content-length'];
          if (contentLengthHeader != null) {
            fileSize = int.tryParse(contentLengthHeader);
          }
          
          // Also check response.contentLength
          if (fileSize == null || fileSize == 0) {
            fileSize = headResponse.contentLength;
          }
        }
      } catch (e) {
        debugPrint('         ⚠️  HEAD request failed: $e');
      }
      
      // If HEAD didn't work, try GET with range request to get Content-Range
      if (fileSize == null || fileSize == 0) {
        try {
          final rangeResponse = await http.get(
            Uri.parse(cleanSegmentUrl),
            headers: {'Range': 'bytes=0-1023'}, // Get first 1KB
          ).timeout(const Duration(seconds: 5));
          
          if (rangeResponse.statusCode == 206) {
            // Parse Content-Range header: "bytes 0-1023/1234567"
            final contentRange = rangeResponse.headers['content-range'];
            if (contentRange != null) {
              final match = RegExp(r'bytes \d+-\d+/(\d+)').firstMatch(contentRange);
              if (match != null) {
                fileSize = int.tryParse(match.group(1)!);
              }
            }
          } else if (rangeResponse.statusCode == 200) {
            // Full response, check Content-Length
            final contentLengthHeader = rangeResponse.headers['content-length'];
            if (contentLengthHeader != null) {
              fileSize = int.tryParse(contentLengthHeader);
            }
            if (fileSize == null || fileSize == 0) {
              fileSize = rangeResponse.contentLength;
            }
          }
        } catch (e) {
          debugPrint('         ⚠️  Range request failed: $e');
        }
      }
      
      // If we got file size, we can't determine actual duration from file size alone
      // Don't log per-segment - we already logged the limitation once
      if (fileSize != null && fileSize > 0) {
        // File size retrieved but not logged per-segment to reduce verbosity
        return null;
      } else {
        // Only log if we couldn't get file size at all (unusual case)
        if (!_hasLoggedHttpFallback) {
          debugPrint('         ⚠️  Could not determine file size from HTTP headers');
        }
        return null;
      }
    } catch (e) {
      debugPrint('         ❌ Exception getting file info: $e');
      return null;
    }
  }

  /// Get actual duration of a TS segment using ffprobe
  static Future<double?> _getSegmentDuration(String segmentUrl) async {
    try {
      final ffprobePath = await _getFfprobePath();
      if (ffprobePath == null) {
        return null;
      }

      final result = await Process.run(
        ffprobePath,
        [
          '-v',
          'error',
          '-show_entries',
          'format=duration',
          '-of',
          'default=noprint_wrappers=1:nokey=1',
          segmentUrl,
        ],
      );

      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final durationString = result.stdout.toString().trim();
        final duration = double.tryParse(durationString);
        if (duration != null) {
          // Log the raw duration value from ffprobe
          debugPrint('         🔍 ffprobe output: $durationString seconds');
        }
        return duration;
      } else {
        debugPrint('         ⚠️  ffprobe returned exit code ${result.exitCode}');
        if (result.stderr.toString().trim().isNotEmpty) {
          debugPrint('         Error: ${result.stderr.toString().trim()}');
        }
      }
      return null;
    } catch (e) {
      debugPrint('         ❌ Exception getting duration: $e');
      return null;
    }
  }

  /// Get total duration of M3U8 playlist using ffprobe or video_player fallback
  static Future<double?> getM3u8Duration(String m3u8Url) async {
    try {
      final ffprobePath = await _getFfprobePath();
      
      if (ffprobePath == null) {
        // Use video_player plugin as fallback (works in iOS simulators)
        debugPrint('🔍 Getting M3U8 duration using video_player (ffprobe not available)...');
        
        VideoPlayerController? controller;
        try {
          controller = VideoPlayerController.networkUrl(Uri.parse(m3u8Url));
          
          // Initialize with timeout (30 seconds for full M3U8)
          await controller.initialize().timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Timeout initializing video player for M3U8');
            },
          );
          
          final duration = controller.value.duration;
          final durationSeconds = duration.inMilliseconds / 1000.0;
          
          debugPrint('   ✅ M3U8 duration (video_player): ${durationSeconds.toStringAsFixed(1)}s');
          return durationSeconds;
        } catch (e) {
          debugPrint('   ❌ Error getting M3U8 duration via video_player: $e');
          return null;
        } finally {
          try {
            await controller?.dispose();
          } catch (_) {
            // Ignore disposal errors
          }
        }
      } else {
        // Use ffprobe (more accurate)
        debugPrint('🔍 Getting M3U8 duration using ffprobe...');
        final result = await Process.run(
          ffprobePath,
          [
            '-v',
            'error',
            '-show_entries',
            'format=duration',
            '-of',
            'default=noprint_wrappers=1:nokey=1',
            m3u8Url,
          ],
        );

        if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
          final duration = double.tryParse(result.stdout.toString().trim());
          debugPrint('   ✅ M3U8 duration (ffprobe): ${duration?.toStringAsFixed(1)}s');
          return duration;
        }
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting M3U8 duration: $e');
      return null;
    }
  }

  /// Compare calculated timeline with actual video duration
  static Future<void> compareTimelineWithActual({
    required String m3u8Url,
    required double calculatedDuration,
    required double expectedDuration,
  }) async {
    debugPrint('');
    debugPrint('📊 Timeline Comparison:');
    debugPrint('   ─────────────────────────────────────');
    debugPrint('   Calculated duration: ${calculatedDuration.toStringAsFixed(1)}s');
    debugPrint('   Expected duration: ${expectedDuration.toStringAsFixed(1)}s');
    debugPrint('   Difference: ${(calculatedDuration - expectedDuration).abs().toStringAsFixed(1)}s');
    
    final actualDuration = await getM3u8Duration(m3u8Url);
    if (actualDuration != null) {
      debugPrint('   Actual duration (ffprobe): ${actualDuration.toStringAsFixed(1)}s');
      debugPrint('   Difference from actual: ${(calculatedDuration - actualDuration).abs().toStringAsFixed(1)}s');
    }
    debugPrint('   ─────────────────────────────────────');
    debugPrint('');
  }
}


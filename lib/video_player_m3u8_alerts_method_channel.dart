import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'video_player_m3u8_alerts_platform_interface.dart';

/// An implementation of [VideoPlayerM3u8AlertsPlatform] that uses method channels.
class MethodChannelVideoPlayerM3u8Alerts extends VideoPlayerM3u8AlertsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_player_m3u8_alerts');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

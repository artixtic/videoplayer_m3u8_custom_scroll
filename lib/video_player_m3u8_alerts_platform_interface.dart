import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'video_player_m3u8_alerts_method_channel.dart';

abstract class VideoPlayerM3u8AlertsPlatform extends PlatformInterface {
  /// Constructs a VideoPlayerM3u8AlertsPlatform.
  VideoPlayerM3u8AlertsPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoPlayerM3u8AlertsPlatform _instance = MethodChannelVideoPlayerM3u8Alerts();

  /// The default instance of [VideoPlayerM3u8AlertsPlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoPlayerM3u8Alerts].
  static VideoPlayerM3u8AlertsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoPlayerM3u8AlertsPlatform] when
  /// they register themselves.
  static set instance(VideoPlayerM3u8AlertsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

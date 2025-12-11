// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'video_player_m3u8_alerts_platform_interface.dart';

/// A web implementation of the VideoPlayerM3u8AlertsPlatform of the VideoPlayerM3u8Alerts plugin.
class VideoPlayerM3u8AlertsWeb extends VideoPlayerM3u8AlertsPlatform {
  /// Constructs a VideoPlayerM3u8AlertsWeb
  VideoPlayerM3u8AlertsWeb();

  static void registerWith(Registrar registrar) {
    VideoPlayerM3u8AlertsPlatform.instance = VideoPlayerM3u8AlertsWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_m3u8_alerts/video_player_m3u8_alerts.dart';
import 'package:video_player_m3u8_alerts/video_player_m3u8_alerts_platform_interface.dart';
import 'package:video_player_m3u8_alerts/video_player_m3u8_alerts_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVideoPlayerM3u8AlertsPlatform
    with MockPlatformInterfaceMixin
    implements VideoPlayerM3u8AlertsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final VideoPlayerM3u8AlertsPlatform initialPlatform = VideoPlayerM3u8AlertsPlatform.instance;

  test('$MethodChannelVideoPlayerM3u8Alerts is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVideoPlayerM3u8Alerts>());
  });

  test('getPlatformVersion', () async {
    VideoPlayerM3u8Alerts videoPlayerM3u8AlertsPlugin = VideoPlayerM3u8Alerts();
    MockVideoPlayerM3u8AlertsPlatform fakePlatform = MockVideoPlayerM3u8AlertsPlatform();
    VideoPlayerM3u8AlertsPlatform.instance = fakePlatform;

    expect(await videoPlayerM3u8AlertsPlugin.getPlatformVersion(), '42');
  });
}

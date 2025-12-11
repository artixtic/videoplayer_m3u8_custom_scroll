library video_player_m3u8_alerts;

import 'video_player_m3u8_alerts_platform_interface.dart';

// Export controllers
export 'controllers/m3u8_video_controller.dart';
// Export models
export 'models/alert_marker.dart';
export 'models/video_api_response.dart';
// Export utilities
export 'utils/alert_converter.dart';
// Export platform interface (for advanced usage)
export 'widgets/alert_widgets.dart';
export 'widgets/api_video_player_screen.dart';
export 'widgets/custom_video_slider.dart';
// Export widgets
export 'widgets/m3u8_video_player.dart';
export 'widgets/m3u8_video_player_no_slider.dart';
export 'widgets/wave_video_slider.dart';
export 'widgets/waveform_slider.dart';

class VideoPlayerM3u8Alerts {
  Future<String?> getPlatformVersion() {
    return VideoPlayerM3u8AlertsPlatform.instance.getPlatformVersion();
  }
}

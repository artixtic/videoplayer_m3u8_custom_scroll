#ifndef FLUTTER_PLUGIN_VIDEO_PLAYER_M3U8_ALERTS_PLUGIN_H_
#define FLUTTER_PLUGIN_VIDEO_PLAYER_M3U8_ALERTS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace video_player_m3u8_alerts {

class VideoPlayerM3u8AlertsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  VideoPlayerM3u8AlertsPlugin();

  virtual ~VideoPlayerM3u8AlertsPlugin();

  // Disallow copy and assign.
  VideoPlayerM3u8AlertsPlugin(const VideoPlayerM3u8AlertsPlugin&) = delete;
  VideoPlayerM3u8AlertsPlugin& operator=(const VideoPlayerM3u8AlertsPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace video_player_m3u8_alerts

#endif  // FLUTTER_PLUGIN_VIDEO_PLAYER_M3U8_ALERTS_PLUGIN_H_

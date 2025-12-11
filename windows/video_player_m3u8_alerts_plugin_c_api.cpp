#include "include/video_player_m3u8_alerts/video_player_m3u8_alerts_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "video_player_m3u8_alerts_plugin.h"

void VideoPlayerM3u8AlertsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  video_player_m3u8_alerts::VideoPlayerM3u8AlertsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

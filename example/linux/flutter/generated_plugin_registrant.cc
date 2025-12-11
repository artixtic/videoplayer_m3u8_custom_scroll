//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <video_player_m3u8_alerts/video_player_m3u8_alerts_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) video_player_m3u8_alerts_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "VideoPlayerM3u8AlertsPlugin");
  video_player_m3u8_alerts_plugin_register_with_registrar(video_player_m3u8_alerts_registrar);
}

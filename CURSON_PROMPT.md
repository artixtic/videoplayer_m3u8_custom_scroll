# Curson Prompt: Project Overview for video_player_m3u8_alerts

## Project Purpose
This project is a Flutter plugin and demo app for playing M3U8 video streams with alert markers (such as AI-detected events) overlaid on a custom video timeline. It is designed for use cases like security camera playback, where alerts (e.g., parcel or weapon detection) are shown as markers on the video timeline.

## Key Features
- **M3U8 Video Playback:** Uses a custom video player to play HLS (M3U8) streams.
- **Alert Markers:** Displays alert markers (e.g., "PARCEL ALERT!") on the video timeline, synchronized with the video.
- **Custom Timeline:** Implements a custom video slider with alert markers and time navigation (including "LIVE" and "Today" buttons).
- **API Integration:** Fetches video stream URLs and alert data from a backend API using Dio with a custom interceptor for authentication and error handling.
- **Offset Calculation:** Attempts to synchronize alert times with video playback, accounting for any offset between alert timestamps and video segment times.

## Main Components
- `lib/controllers/m3u8_video_controller.dart`: Handles video playback, timeline, and alert marker logic.
- `lib/models/alert_marker.dart`: Data model for alert markers.
- `lib/widgets/custom_video_slider.dart`: Custom timeline widget with alert markers.
- `lib/widgets/m3u8_video_player.dart`: Main video player widget.
- `lib/video_player_m3u8_alerts.dart`: Plugin entry point.
- `lib/video_player_m3u8_alerts_method_channel.dart`: Platform channel for native integration.
- `example/`: Demo app showing usage of the plugin.

## Alert Synchronization Logic
- Alerts are fetched from the API with timestamps (UTC).
- The video M3U8 playlist is parsed to build a segment timeline (each segment has a start time and duration).
- The code attempts to align the alert times with the video timeline by comparing the first segment timestamp and the video file start time.
- If there is a time offset (difference between video and alert times), it is calculated and applied to all alert markers.
- All segments are now verified for accuracy (not just the first 10), to ensure correct alignment over long (24h+) videos.

## Known Issues
- There may still be a 6-9 minute difference between alert markers and actual video events, even when the offset is calculated as zero. This may be due to:
  - Inaccurate segment timestamps in the M3U8 playlist.
  - API-provided fileStartTime not matching the actual video content start.
  - Clock drift or timezone issues between alert generation and video recording.
- The code now verifies all segments for accuracy, but further investigation may be needed if discrepancies persist.

## API Usage
- Uses Dio with a custom interceptor for authentication, error handling, and token refresh.
- Example API response includes video file URL, duration, file start/end times, and a list of alerts with timestamps and images.

## How to Debug Timeline Issues
1. Log all segment start times and durations from the M3U8 playlist.
2. Compare the first segment timestamp with the API's fileStartTime.
3. Log all alert times and their calculated positions on the timeline.
4. If there is a persistent offset, check for:
   - Segment duration mismatches.
   - Gaps or overlaps in the segment timeline.
   - Timezone or formatting issues in alert or segment timestamps.

## Demo Screens
- The UI shows the video, a custom timeline with alert markers, and navigation controls.
- Alert markers (e.g., green "PARCEL ALERT!" boxes) should appear at the correct positions on the timeline.

## Dummy Data
- The project can use dummy API responses for testing, including video file start/end times and a list of alerts with timestamps.

---
This prompt is designed to help Curson (or any developer) quickly understand the architecture, features, and current challenges in the `video_player_m3u8_alerts` project.

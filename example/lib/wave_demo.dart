import 'package:flutter/material.dart';
import 'package:video_player_m3u8_alerts/video_player_m3u8_alerts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wave Slider Demo',
      theme: ThemeData.dark(),
      home: const WaveSliderDemo(),
    );
  }
}

class WaveSliderDemo extends StatelessWidget {
  const WaveSliderDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // Your API data with parcel alerts
    final apiData = {
      "fileUrl":
          "https://media-assets-test.irvinei.com/BJQMgFq81ZXu0mFg9q5tECPN7EwFTvfL5fsBM8FrDFxeEidbvnP51v0JRyib/RP1A.200720.012/index-1765393200.m3u8",
      "duration": 18440,
      "aiAlert": [
        {
          "id": 41652,
          "device_id": "bf27eac9cc2ede8c",
          "entity_id": "",
          "created_at": "2025-12-11T07:23:13.000000Z",
          "title": "Parcel Alert!",
          "image":
              "https://media-assets-test.irvinei.com/alert/5/1765437791.6300094_c11fce4b.jpg",
          "text": "A parcel is detected at the porch in doorbell: Front Door.",
        },
        {
          "id": 41653,
          "device_id": "bf27eac9cc2ede8c",
          "entity_id": "",
          "created_at": "2025-12-11T07:23:23.000000Z",
          "title": "Parcel Alert!",
          "image":
              "https://media-assets-test.irvinei.com/alert/5/1765437801.892106_580208d8.jpg",
          "text": "A parcel is detected at the porch in doorbell: Front Door.",
        },
        {
          "id": 41654,
          "device_id": "bf27eac9cc2ede8c",
          "entity_id": "",
          "created_at": "2025-12-11T07:23:35.000000Z",
          "title": "Parcel Alert!",
          "image":
              "https://media-assets-test.irvinei.com/alert/5/1765437813.0441897_b6b42fec.jpg",
          "text": "A parcel is detected at the porch in doorbell: Front Door.",
        },
        {
          "id": 41655,
          "device_id": "bf27eac9cc2ede8c",
          "entity_id": "",
          "created_at": "2025-12-11T07:23:45.000000Z",
          "title": "Parcel Alert!",
          "image":
              "https://media-assets-test.irvinei.com/alert/5/1765437823.9853985_9c1980b6.jpg",
          "text": "A parcel is detected at the porch in doorbell: Front Door.",
        },
      ],
      "fileStartTime": "2025-12-11T05:04:26.000000Z",
      "fileEndTime": "2025-12-11T10:20:14.000000Z",
    };

    // Using the pre-built screen with waveform slider (no Today/LIVE buttons)
    return ApiVideoPlayerScreen(
      apiData: apiData,
      title: 'Waveform Slider - Parcel Detection',
      sliderActiveColor: Colors.orange,
      sliderMarkerColor: Colors.amber,
      useWaveSlider: true, // Waveform slider enabled
    );
  }
}

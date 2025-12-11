import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_m3u8_alerts/video_player_m3u8_alerts.dart';

void main() {
  group('M3U8 Offset Fix Tests', () {
    test('Extract M3U8 timestamp from URL', () {
      const url =
          'https://media-assets-test.irvinei.com/BJQMgFq81ZXu0mFg9q5tECPN7EwFTvfL5fsBM8FrDFxeEidbvnP51v0JRyib/RP1A.200720.012/index-1765393200.m3u8';

      final m3u8StartTime = AlertConverter.extractM3u8StartTimeFromUrl(url);

      expect(m3u8StartTime, isNotNull);
      expect(m3u8StartTime!.toUtc().toString(), '2025-12-10 19:00:00.000Z');
    });

    test('Calculate correct offset between M3U8 and API fileStartTime', () {
      final m3u8StartTime = DateTime.parse('2025-12-10T19:00:00.000Z');
      final apiFileStartTime = DateTime.parse('2025-12-11T05:04:26.000Z');

      final offset = apiFileStartTime.difference(m3u8StartTime).inSeconds;

      // Expected: 10h 4m 26s = 36266 seconds
      expect(offset, 36266);
    });

    test('Convert alerts with M3U8 offset applied', () {
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
            "image": "https://example.com/image.jpg",
            "text": "A parcel is detected at the porch.",
          },
        ],
        "fileStartTime": "2025-12-11T05:04:26.000000Z",
        "fileEndTime": "2025-12-11T10:20:14.000000Z",
      };

      final response = VideoApiResponse.fromJson(apiData);
      final markers = AlertConverter.fromVideoApiResponse(
        response,
        autoDetectM3u8Offset: true,
      );

      expect(markers.length, 1);

      // Without offset: 8327 seconds (from API fileStartTime)
      // With offset: 8327 + 36266 = 44593 seconds (actual position in M3U8)
      print('\n📍 Alert Position Calculation:');
      print('   Alert time: 2025-12-11 07:23:13 UTC');
      print('   API fileStartTime: 2025-12-11 05:04:26 UTC');
      print('   Time from API start: 8327s');
      print('   M3U8 file starts: 2025-12-10 19:00:00 UTC');
      print('   M3U8 offset: 36266s');
      print('   Actual position in M3U8: ${markers[0].timeInSeconds}s');

      expect(markers[0].timeInSeconds, closeTo(44593.0, 1.0));
    });

    test('All 4 parcel alerts with correct M3U8 positions', () {
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
            "image": "https://example.com/image.jpg",
            "text": "Parcel 1",
          },
          {
            "id": 41653,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:23.000000Z",
            "title": "Parcel Alert!",
            "image": "https://example.com/image.jpg",
            "text": "Parcel 2",
          },
          {
            "id": 41654,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:35.000000Z",
            "title": "Parcel Alert!",
            "image": "https://example.com/image.jpg",
            "text": "Parcel 3",
          },
          {
            "id": 41655,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:45.000000Z",
            "title": "Parcel Alert!",
            "image": "https://example.com/image.jpg",
            "text": "Parcel 4",
          },
        ],
        "fileStartTime": "2025-12-11T05:04:26.000000Z",
        "fileEndTime": "2025-12-11T10:20:14.000000Z",
      };

      final response = VideoApiResponse.fromJson(apiData);
      final markers = AlertConverter.fromVideoApiResponse(
        response,
        autoDetectM3u8Offset: true,
      );

      expect(markers.length, 4);

      print('\n📊 All Alerts with M3U8 Offset:');
      print('   M3U8 offset: 36266 seconds (10h 4m 26s)');
      print('   ─────────────────────────────────────────');

      // Alert 1: 8327 + 36266 = 44593
      print('   Alert 1: 8327s + 36266s = ${markers[0].timeInSeconds}s');
      expect(markers[0].timeInSeconds, closeTo(44593.0, 1.0));

      // Alert 2: 8337 + 36266 = 44603
      print('   Alert 2: 8337s + 36266s = ${markers[1].timeInSeconds}s');
      expect(markers[1].timeInSeconds, closeTo(44603.0, 1.0));

      // Alert 3: 8349 + 36266 = 44615
      print('   Alert 3: 8349s + 36266s = ${markers[2].timeInSeconds}s');
      expect(markers[2].timeInSeconds, closeTo(44615.0, 1.0));

      // Alert 4: 8359 + 36266 = 44625
      print('   Alert 4: 8359s + 36266s = ${markers[3].timeInSeconds}s');
      expect(markers[3].timeInSeconds, closeTo(44625.0, 1.0));
    });

    test('Disable M3U8 offset detection', () {
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
            "image": "https://example.com/image.jpg",
            "text": "A parcel is detected at the porch.",
          },
        ],
        "fileStartTime": "2025-12-11T05:04:26.000000Z",
        "fileEndTime": "2025-12-11T10:20:14.000000Z",
      };

      final response = VideoApiResponse.fromJson(apiData);
      final markers = AlertConverter.fromVideoApiResponse(
        response,
        autoDetectM3u8Offset: false, // Disable offset
      );

      expect(markers.length, 1);
      // Should be 8327 without offset
      expect(markers[0].timeInSeconds, closeTo(8327.0, 1.0));
    });
  });
}

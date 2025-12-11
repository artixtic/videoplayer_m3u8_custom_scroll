import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_m3u8_alerts/video_player_m3u8_alerts.dart';

void main() {
  group('API Data Conversion Tests', () {
    test('Parse VideoApiResponse from JSON', () {
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
            "text":
                "A parcel is detected at the porch in doorbell: Front Door.",
          },
          {
            "id": 41653,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:23.000000Z",
            "title": "Parcel Alert!",
            "image":
                "https://media-assets-test.irvinei.com/alert/5/1765437801.892106_580208d8.jpg",
            "text":
                "A parcel is detected at the porch in doorbell: Front Door.",
          },
          {
            "id": 41654,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:35.000000Z",
            "title": "Parcel Alert!",
            "image":
                "https://media-assets-test.irvinei.com/alert/5/1765437813.0441897_b6b42fec.jpg",
            "text":
                "A parcel is detected at the porch in doorbell: Front Door.",
          },
          {
            "id": 41655,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:45.000000Z",
            "title": "Parcel Alert!",
            "image":
                "https://media-assets-test.irvinei.com/alert/5/1765437823.9853985_9c1980b6.jpg",
            "text":
                "A parcel is detected at the porch in doorbell: Front Door.",
          },
        ],
        "fileStartTime": "2025-12-11T05:04:26.000000Z",
        "fileEndTime": "2025-12-11T10:20:14.000000Z",
      };

      final response = VideoApiResponse.fromJson(apiData);

      expect(response.fileUrl, contains('index-1765393200.m3u8'));
      expect(response.duration, 18440);
      expect(response.aiAlert.length, 4);
      expect(
        response.fileStartTime.toUtc().toString(),
        '2025-12-11 05:04:26.000Z',
      );
      expect(
        response.fileEndTime.toUtc().toString(),
        '2025-12-11 10:20:14.000Z',
      );
    });

    test('Convert AiAlerts to AlertMarkers', () {
      final apiData = {
        "fileUrl": "https://example.com/video.m3u8",
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
          {
            "id": 41653,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:23.000000Z",
            "title": "Parcel Alert!",
            "image": "https://example.com/image2.jpg",
            "text": "Another parcel detected.",
          },
        ],
        "fileStartTime": "2025-12-11T05:04:26.000000Z",
        "fileEndTime": "2025-12-11T10:20:14.000000Z",
      };

      final response = VideoApiResponse.fromJson(apiData);
      final markers = AlertConverter.fromVideoApiResponse(response);

      expect(markers.length, 2);

      // First alert: 07:23:13 - 05:04:26 = 2h 18m 47s = 8327 seconds
      expect(markers[0].timeInSeconds, closeTo(8327.0, 1.0));
      expect(markers[0].message, 'A parcel is detected at the porch.');

      // Second alert: 07:23:23 - 05:04:26 = 2h 18m 57s = 8337 seconds
      expect(markers[1].timeInSeconds, closeTo(8337.0, 1.0));
      expect(markers[1].message, 'Another parcel detected.');

      // Verify markers are sorted
      expect(markers[0].timeInSeconds < markers[1].timeInSeconds, true);
    });

    test('Filter alerts before video start time', () {
      final apiData = {
        "fileUrl": "https://example.com/video.m3u8",
        "duration": 3600,
        "aiAlert": [
          {
            "id": 1,
            "device_id": "test",
            "entity_id": "",
            "created_at": "2025-12-11T05:00:00.000000Z", // Before video start
            "title": "Early Alert",
            "image": "",
            "text": "This should be filtered out",
          },
          {
            "id": 2,
            "device_id": "test",
            "entity_id": "",
            "created_at": "2025-12-11T06:00:00.000000Z", // After video start
            "title": "Valid Alert",
            "image": "",
            "text": "This should be included",
          },
        ],
        "fileStartTime": "2025-12-11T05:30:00.000000Z",
        "fileEndTime": "2025-12-11T08:00:00.000000Z",
      };

      final response = VideoApiResponse.fromJson(apiData);
      final markers = AlertConverter.fromVideoApiResponse(response);

      // Only the second alert should be included
      expect(markers.length, 1);
      expect(markers[0].message, 'This should be included');
    });

    test('Calculate exact time differences', () {
      final fileStartTime = DateTime.parse("2025-12-11T05:04:26.000000Z");
      final alert1Time = DateTime.parse("2025-12-11T07:23:13.000000Z");
      final alert2Time = DateTime.parse("2025-12-11T07:23:23.000000Z");
      final alert3Time = DateTime.parse("2025-12-11T07:23:35.000000Z");
      final alert4Time = DateTime.parse("2025-12-11T07:23:45.000000Z");

      final diff1 = alert1Time.difference(fileStartTime).inSeconds;
      final diff2 = alert2Time.difference(fileStartTime).inSeconds;
      final diff3 = alert3Time.difference(fileStartTime).inSeconds;
      final diff4 = alert4Time.difference(fileStartTime).inSeconds;

      // Expected: 2h 18m 47s = 8327 seconds
      expect(diff1, 8327);
      // Expected: 2h 18m 57s = 8337 seconds
      expect(diff2, 8337);
      // Expected: 2h 19m 09s = 8349 seconds
      expect(diff3, 8349);
      // Expected: 2h 19m 19s = 8359 seconds
      expect(diff4, 8359);

      print('\nTime calculations:');
      print('Video starts: $fileStartTime');
      print('Alert 1 at: $alert1Time → ${diff1}s (${_formatDuration(diff1)})');
      print('Alert 2 at: $alert2Time → ${diff2}s (${_formatDuration(diff2)})');
      print('Alert 3 at: $alert3Time → ${diff3}s (${_formatDuration(diff3)})');
      print('Alert 4 at: $alert4Time → ${diff4}s (${_formatDuration(diff4)})');
    });

    test('VideoApiResponse toJson/fromJson roundtrip', () {
      final originalData = {
        "fileUrl": "https://example.com/video.m3u8",
        "duration": 18440,
        "aiAlert": [
          {
            "id": 41652,
            "device_id": "bf27eac9cc2ede8c",
            "entity_id": "",
            "created_at": "2025-12-11T07:23:13.000000Z",
            "title": "Parcel Alert!",
            "image": "https://example.com/image.jpg",
            "text": "A parcel is detected.",
          },
        ],
        "fileStartTime": "2025-12-11T05:04:26.000000Z",
        "fileEndTime": "2025-12-11T10:20:14.000000Z",
      };

      final response = VideoApiResponse.fromJson(originalData);
      final jsonOutput = response.toJson();

      expect(jsonOutput['fileUrl'], originalData['fileUrl']);
      expect(jsonOutput['duration'], originalData['duration']);
      expect(jsonOutput['aiAlert'].length, 1);
      // Compare DateTime objects directly instead of ISO strings
      expect(
        DateTime.parse(jsonOutput['fileStartTime'] as String),
        DateTime.parse(originalData['fileStartTime'] as String),
      );
      expect(
        DateTime.parse(jsonOutput['fileEndTime'] as String),
        DateTime.parse(originalData['fileEndTime'] as String),
      );
    });
  });
}

String _formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  return '${hours}h ${minutes}m ${secs}s';
}

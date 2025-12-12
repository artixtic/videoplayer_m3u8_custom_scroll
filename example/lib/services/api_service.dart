import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'dio_service.dart';

/// API Service for fetching stream data
class ApiService {
  /// Fetch stream data from API
  ///
  /// Parameters from API:
  /// - device_id: Device identifier
  /// - start_date: Start date in format "YYYY-MM-DD HH:mm:ss"
  /// - end_date: End date in format "YYYY-MM-DD HH:mm:ss"
  /// - uuid: Device UUID
  static Future<Map<String, dynamic>> fetchStreamData({
    required String deviceId,
    required String startDate,
    required String endDate,
    required String uuid,
    CancelToken? cancelToken,
  }) async {
    try {
      debugPrint('🌐 Fetching stream data...');
      debugPrint('   Device ID: $deviceId');
      debugPrint('   Date Range: $startDate to $endDate');
      debugPrint('   UUID: $uuid');

      final response = await dio.get(
        '/stream/fetch-streams',
        queryParameters: {
          'device_id': deviceId,
          'start_date': startDate,
          'end_date': endDate,
          'uuid': uuid,
        },
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Stream data fetched successfully');

        // Check if response has data
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else {
          throw CustomDioException(
            status: response.statusCode ?? 500,
            message: 'Invalid response format',
          );
        }
      } else {
        throw CustomDioException(
          status: response.statusCode ?? 500,
          message: response.statusMessage ?? 'Failed to fetch stream data',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio Error: ${e.message}');

      if (e.response != null) {
        throw CustomDioException(
          status: e.response!.statusCode ?? 500,
          message: e.response!.statusMessage ?? 'Unknown error',
        );
      } else {
        throw CustomDioException(
          status: 500,
          message: e.message ?? 'Network error',
        );
      }
    } catch (e) {
      debugPrint('❌ Unexpected Error: $e');
      throw CustomDioException(status: 500, message: e.toString());
    }
  }

  /// Fetch stream data with default parameters (last 24 hours)
  static Future<Map<String, dynamic>> fetchDefaultStreamData() async {
    const String deviceId =
        'BJQMgFq81ZXu0mFg9q5tECPN7EwFTvfL5fsBM8FrDFxeEidbvnP51v0JRyib';
    const String startDate = '2025-12-10 19:00:00';
    const String endDate = '2025-12-11 18:59:00';
    const String uuid = 'RP1A.200720.012';

    return fetchStreamData(
      deviceId: deviceId,
      startDate: startDate,
      endDate: endDate,
      uuid: uuid,
    );
  }

  /// Example: Fetch current date range stream data
  static Future<Map<String, dynamic>> fetchCurrentDayStreamData({
    required String deviceId,
    required String uuid,
  }) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Format: "YYYY-MM-DD HH:mm:ss"
    final startDate =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')} 19:00:00';
    final endDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 18:59:00';

    return fetchStreamData(
      deviceId: deviceId,
      startDate: startDate,
      endDate: endDate,
      uuid: uuid,
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// API Configuration
class ApiConfig {
  static const String apiUrl = 'http://api-test.irvinei.com/api/v2';
  static const String apiKey =
      '4013|QgKD2ITnA85nng88b9yKE5wG1PXNY2OomDrYHN2F3ff13d8d';
  static const String authToken =
      'RdG5bYnYWyG3itQ0hNN33cyjE1VCkcurGdatTdYAMFo8q6AgDlMAGJHsTsm7=';
}

/// Create Dio instance with interceptors
Dio _createDioInstance() {
  final headers = <String, dynamic>{};
  final options = BaseOptions(
    baseUrl: ApiConfig.apiUrl,
    headers: headers,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  );
  final dio = Dio(options);
  dio.interceptors.add(_CustomInterceptor());
  return dio;
}

class _CustomInterceptor extends Interceptor {
  _CustomInterceptor();

  final ignoreAuthForPaths = <String>[
    "auth/login",
    "auth/register",
    "otp/verify",
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add API authentication headers
    options.headers['Authorization'] = "Bearer ${ApiConfig.authToken}";
    options.headers['x-api-key'] = ApiConfig.apiKey;
    options.headers['Content-Type'] = "application/json";
    options.headers['Connection'] = 'keep-alive';
    options.headers['Accept'] = "application/json";

    if (kDebugMode) {
      debugPrint(
        '🌐 API Request: ${options.method} ${options.path} ${options.queryParameters}',
      );
    }

    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 500) {
      debugPrint('❌ Server Error (500): ${err.requestOptions.path}');
      handler.next(err);
      return;
    }

    // Handle connection errors and SSL handshake issues
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown) {
      debugPrint(
        '❌ Connection Error: ${err.requestOptions.path} - ${err.message}',
      );

      // Check if it's an SSL/TLS related error
      if (err.message?.contains('HandshakeException') == true ||
          err.message?.contains('CertificateException') == true ||
          err.message?.contains('TlsException') == true) {
        debugPrint(
          '❌ SSL/TLS Error: ${err.requestOptions.path} - ${err.message}',
        );
        handler.next(err);
        return;
      }

      handler.next(err);
      return;
    }

    // Handle Timeout Errors
    if (err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionTimeout) {
      debugPrint('⏱️ Timeout Error: ${err.requestOptions.path} - ${err.type}');
      handler.next(err);
      return;
    }

    // Handle 401 Unauthorized error
    if (err.response?.statusCode == 401) {
      debugPrint('🔐 Unauthorized (401): ${err.requestOptions.path}');
      handler.next(err);
      return;
    }

    // Handle 404 (Not Found)
    if (err.response?.statusCode == 404) {
      debugPrint('🔍 Not Found (404): ${err.requestOptions.path}');
      return handler.next(err);
    }

    debugPrint(
      '❌ API Error: ${err.requestOptions.method} ${err.requestOptions.path} || ERROR: ${err.message} || Code: ${err.response?.statusCode}',
    );

    return handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint(
          '⚠️ Non-OK Response: ${response.requestOptions.method} ${response.requestOptions.path} || Status: ${response.statusCode}',
        );
      } else if (kDebugMode) {
        debugPrint(
          '✅ API Success: ${response.requestOptions.method} ${response.requestOptions.path}',
        );
      }
    } catch (e) {
      debugPrint('❌ onResponse Error: $e');
    }

    if (!handler.isCompleted) {
      super.onResponse(response, handler);
    }
  }
}

/// Global Dio instance
final Dio dio = _createDioInstance();

/// Cancel a Dio request token
void cancelDioToken(CancelToken? token) {
  if (token == null) return;
  if (token.isCancelled) return;
  try {
    token.cancel();
  } catch (e) {
    debugPrint('❌ cancelDioToken Error: $e');
  }
}

/// Custom Dio Exception
class CustomDioException implements Exception {
  CustomDioException({required this.status, required this.message});

  final int status;
  final String message;

  @override
  String toString() => 'CustomDioException: $status - $message';
}

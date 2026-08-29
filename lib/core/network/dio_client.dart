/// Single Dio singleton for the whole app.
/// Honors `docs/MOBILE_API_INTEGRATION_GUIDE.md:5` header + error contract.
library;

import 'dart:io' show HttpClient;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../app/config/api_config.dart';
import '../../app/config/env.dart';
import '../security/token_manager.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';
import 'request_id_interceptor.dart';
import 'retry_interceptor.dart';

class DioClient {
  DioClient._(this.dio);
  final Dio dio;

  static DioClient? _instance;

  static DioClient get instance => _instance!;
  static bool get isInitialized => _instance != null;

  static Future<DioClient> init({required TokenManager tokens}) async {
    if (_instance != null) return _instance!;
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: ApiConfig.defaultHeaders,
        // Let interceptors surface ApiException instead of DioException for non-2xx JSON
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ),
    );

    dio.interceptors.addAll([
      RequestIdInterceptor(),
      AuthInterceptor(tokens),
      RetryInterceptor(),
      AppLoggingInterceptor(),
      if (kDebugMode)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          compact: true,
        ),
    ]);

    // Laragon dev cert is self-signed → allow for dev flavor on native only (web uses browser trust).
    if (!kIsWeb && currentEnv().isDev) {
      final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
      adapter.createHttpClient = () {
        final c = HttpClient();
        c.badCertificateCallback = (cert, host, port) =>
            host.contains('bisaas.test') || host.contains('10.0.2.2') || host == 'localhost';
        return c;
      };
    }

    // Propagate locale header reactively — caller can call `DioClient.setLocale('ne')`
    _instance = DioClient._(dio);
    return _instance!;
  }

  /// Update Accept-Language without recreating Dio.
  void setLocale(String locale) {
    dio.options.headers['Accept-Language'] = locale;
  }

  /// Update Idempotency-Key for the next mutating request (caller generates UUID).
  void setIdempotencyKey(String key) {
    dio.options.headers['Idempotency-Key'] = key;
  }

  void clearIdempotencyKey() {
    dio.options.headers.remove('Idempotency-Key');
  }
}

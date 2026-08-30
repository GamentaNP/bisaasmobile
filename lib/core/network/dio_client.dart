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
import 'certificate_pinning.dart';
import 'logging_interceptor.dart';
import 'refresh_interceptor.dart';
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
      // Order matters: onError runs in reverse, so a 401 reaches
      // RefreshInterceptor (refresh + replay) before RetryInterceptor sees it,
      // and AuthInterceptor maps the final error to ApiException last.
      RetryInterceptor(dio: dio),
      RefreshInterceptor(tokens, dio),
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

    // TLS policy — native only (web uses browser trust).
    if (!kIsWeb) {
      final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
      if (currentEnv().isDev) {
        // Laragon dev cert is self-signed → allow for dev flavor only.
        // Physical device needs LAN IP (192.168.x.x) via adb reverse / Wi-Fi.
        adapter.createHttpClient = () {
          final c = HttpClient();
          c.badCertificateCallback = (cert, host, port) => true;
          return c;
        };
      } else {
        // Prod/staging: pin when pins are configured; no pins → standard validation.
        CertificatePinning.apply(adapter, host: Uri.parse(ApiConfig.baseUrl).host);
      }
    }

    _instance = DioClient._(dio);
    return _instance!;
  }

  /// Update Accept-Language without recreating Dio.
  void setLocale(String locale) {
    dio.options.headers['Accept-Language'] = locale;
  }
}

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
import 'device_risk_interceptor.dart';
import 'install_identity_interceptor.dart';
import 'logging_interceptor.dart';
import '../connectivity/api_reachability.dart';
import 'refresh_interceptor.dart';
import 'request_coalescer.dart';
import 'request_id_interceptor.dart';
import 'response_cache_interceptor.dart';
import 'response_cache_store.dart';
import 'retry_interceptor.dart';

class DioClient {
  DioClient._(this.dio, this.reachability);
  final Dio dio;

  /// Learns whether `/api/v1` is genuinely reachable from real request
  /// outcomes. Owned here because the interceptors that feed it are built in
  /// this class, and the offline banner reads it through the provider graph.
  final ApiReachability reachability;

  static DioClient? _instance;

  static DioClient get instance => _instance!;
  static bool get isInitialized => _instance != null;

  static Future<DioClient> init({
    required TokenManager tokens,
    ResponseCacheStore? cache,
  }) async {
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

    final reachability = ApiReachability();

    dio.interceptors.addAll([
      // Serves a cached body first and revalidates behind the user.
      //
      // MUST be first: its cache lookup is asynchronous and it short-circuits
      // with handler.resolve(), so no earlier interceptor may have already
      // spent the handler with next(). See ResponseCacheInterceptor.
      if (cache != null)
        ResponseCacheInterceptor(
          store: cache,
          reachability: reachability,
          // Deliberately a separate, interceptor-free client so a background
          // refresh cannot re-enter this one and recurse.
          revalidator: Dio(BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
            sendTimeout: ApiConfig.sendTimeout,
            headers: ApiConfig.defaultHeaders,
            validateStatus: (s) => s != null && s >= 200 && s < 300,
          )),
        ),
      RequestIdInterceptor(),
      InstallIdentityInterceptor(),
      DeviceRiskInterceptor(),
      RequestCoalescer(),
      AuthInterceptor(tokens, reachability),
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
      // Debug mode is required as well as the dev flavor: a release build that
      // forgets `--dart-define=ENV=prod` must never relax certificate checks.
      if (kDebugMode && currentEnv().isDev) {
        // Laragon dev cert is self-signed → allow for the dev hosts only.
        // Physical device needs LAN IP (192.168.x.x) via adb reverse / Wi-Fi.
        final allowedHosts = _devCertificateHosts();
        adapter.createHttpClient = () {
          final c = HttpClient();
          c.badCertificateCallback =
              (cert, host, port) => _isDevHost(host, allowedHosts);
          return c;
        };
      } else {
        // Prod/staging: pin when pins are configured; no pins → standard validation.
        CertificatePinning.apply(adapter, host: Uri.parse(ApiConfig.baseUrl).host);
      }
    }

    _instance = DioClient._(dio, reachability);
    return _instance!;
  }

  /// Hosts whose self-signed certificates are tolerated in debug dev builds.
  /// Includes the configured base URL host so an `API_HOST` override still works.
  static Set<String> _devCertificateHosts() => {
        'bisaas.test',
        '10.0.2.2',
        'localhost',
        '127.0.0.1',
        Uri.parse(ApiConfig.baseUrl).host,
      }..removeWhere((h) => h.isEmpty);

  /// Private LAN addresses are allowed so a physical device on Wi-Fi can reach
  /// the Laragon host; everything else is rejected even in debug.
  static bool _isDevHost(String host, Set<String> allowed) {
    if (allowed.contains(host)) return true;

    return host.startsWith('192.168.') ||
        host.startsWith('10.0.') ||
        host.startsWith('172.16.');
  }

  /// Update Accept-Language without recreating Dio.
  void setLocale(String locale) {
    dio.options.headers['Accept-Language'] = locale;
  }
}

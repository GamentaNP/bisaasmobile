import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

/// Structured network logging with `X-Request-Id` and `X-RateLimit-*`.
/// In release, only errors are logged to avoid PII leakage.
class AppLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final id = options.headers['X-Request-Id'];
      AppLogger.d('--> ${options.method} ${options.uri} id=$id');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final id = response.headers.value('x-request-id') ??
          response.requestOptions.headers['X-Request-Id'];
      final limit = response.headers.value('x-ratelimit-remaining');
      AppLogger.d(
        '<-- ${response.statusCode} ${response.requestOptions.uri} id=$id '
        'remaining=$limit',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final id = err.response?.headers.value('x-request-id') ??
        err.requestOptions.headers['X-Request-Id'];
    AppLogger.w(
      '<-- ERR ${err.response?.statusCode} ${err.requestOptions.uri} '
      'id=$id msg=${err.message}',
    );
    handler.next(err);
  }
}

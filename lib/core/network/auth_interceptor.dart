/// Bearer + refresh interceptor.
/// Contracts: `MOBILE_API_INTEGRATION_GUIDE.md:2.2`.
library;

import 'package:dio/dio.dart';

import '../security/token_manager.dart';
import 'api_exception.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens);
  final TokenManager _tokens;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    // Always honor Accept + optional device header for refresh rotation
    options.headers.putIfAbsent('Accept', () => 'application/json');
    final deviceName = await _tokens.readDeviceName();
    if (deviceName != null) options.headers['X-Device-Name'] = deviceName;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final reqId = err.response?.headers.value('x-request-id') ??
        err.requestOptions.headers['X-Request-Id'] as String?;

    // Map any JSON error body to ApiException
    final data = err.response?.data;
    if (data is Map<String, dynamic> && err.response != null) {
      final status = err.response!.statusCode ?? 0;
      // Don't throw for pass-through 401 — let caller decide refresh-vs-logout
      final apiEx = ApiException.fromJson(status, data, requestId: reqId);
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: apiEx,
        ),
      );
    }

    // Non-JSON (HTML fallback when Accept header missing upstream) — surface generic
    if (err.response?.statusCode != null) {
      final apiEx = ApiException(
        statusCode: err.response!.statusCode!,
        code: ApiErrorCode.unknown,
        message: err.message ?? 'Network error',
        requestId: reqId,
      );
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: apiEx,
        ),
      );
    }

    handler.next(err);
  }
}

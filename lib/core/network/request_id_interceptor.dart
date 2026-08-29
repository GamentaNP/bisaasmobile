import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Adds `X-Request-Id` to every request for traceability.
/// Backend returns same header in response — useful for `ApiException.requestId`.
class RequestIdInterceptor extends Interceptor {
  RequestIdInterceptor({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// Header name (backend contract).
  static const header = 'X-Request-Id';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent(header, _uuid.v4);
    handler.next(options);
  }
}

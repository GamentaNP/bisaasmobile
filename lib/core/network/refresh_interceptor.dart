import 'package:dio/dio.dart';

import '../logging/app_logger.dart';
import '../security/token_manager.dart';

/// Proactively refreshes token when 401 / token-expired.
/// Single-flight: concurrent 401s share one refresh future.
///
/// Contract: `MOBILE_API_INTEGRATION_GUIDE.md:2.2` — rotation is single-use,
/// persist atomically, send `X-Device-Name`.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor(this._tokens, this._dio);

  final TokenManager _tokens;
  final Dio _dio;

  bool _isRefreshing = false;
  final List<({RequestOptions opts, ErrorInterceptorHandler handler})> _queue =
      [];

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final opts = err.requestOptions;
    final isAuth = status == 401;
    final isRefreshCall = opts.path.contains('/auth/refresh') ||
        opts.path.contains('/auth/login');
    // Replays already carry the freshly rotated token — never re-refresh them.
    final isReplay = opts.extra['skipAuthRefresh'] == true;

    if (!isAuth || isRefreshCall || isReplay) {
      handler.next(err);
      return;
    }

    // Queue while another refresh is in-flight.
    if (_isRefreshing) {
      _queue.add((opts: opts, handler: handler));
      return;
    }

    _isRefreshing = true;
    try {
      AppLogger.i('401 detected → refreshing token');
      final deviceName = await _tokens.readDeviceName();
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        options: Options(
          headers: {
            if (deviceName case final String name) 'X-Device-Name': name,
          },
          extra: {'skipAuthRefresh': true},
        ),
      );
      final data = res.data?['data'] as Map<String, dynamic>?;
      final token = data?['token'] as String?;
      final expiresAt = data?['expires_at'] as String?;
      if (token == null || token.isEmpty) throw StateError('empty refresh token');

      await _tokens.persist(token: token, expiresAt: expiresAt);
      AppLogger.i('Token refreshed; retrying ${opts.path}');

      // Retry original — marked so a second 401 cannot loop the refresh.
      final replayOpts = opts
        ..headers['Authorization'] = 'Bearer $token'
        ..extra['skipAuthRefresh'] = true;
      final response = await _dio.fetch<dynamic>(replayOpts);
      handler.resolve(response);

      // Drain queue — same replays share the rotated token.
      for (final q in _queue) {
        final queuedOpts = q.opts
          ..headers['Authorization'] = 'Bearer $token'
          ..extra['skipAuthRefresh'] = true;
        try {
          final r = await _dio.fetch<dynamic>(queuedOpts);
          q.handler.resolve(r);
        } on DioException catch (e) {
          q.handler.next(e);
        }
      }
      _queue.clear();
    } catch (e, st) {
      AppLogger.e('Refresh failed — clearing session', e, st);
      await _tokens.clear();
      handler.next(err);
      for (final q in _queue) {
        q.handler.next(err);
      }
      _queue.clear();
    } finally {
      _isRefreshing = false;
    }
  }
}

import 'dart:async';

import 'package:dio/dio.dart';

import '../errors/error_reporter.dart';
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

    // Queue while another refresh is in-flight. Bound the queue so a cold
    // start with dozens of 401s cannot monopolise the client indefinitely.
    if (_isRefreshing) {
      if (_queue.length >= 20) {
        handler.next(err);
        return;
      }
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
      final body = res.data;
      // Tolerant envelope: some deployments return {data: {token, expires_at}},
      // others {token, expires_at} at the top level. Never crash on shape drift.
      final data = body is Map<String, dynamic>
          ? (body['data'] is Map<String, dynamic>
              ? body['data'] as Map<String, dynamic>
              : body)
          : null;
      final token = data?['token'] as String?;
      final expiresAt = data?['expires_at'] as String?;
      if (token == null || token.isEmpty) {
        throw StateError('refresh response missing token');
      }

      await _tokens.persist(token: token, expiresAt: expiresAt);
      AppLogger.i('Token refreshed; retrying ${opts.path}');

      // Everything below is request replay, NOT refresh. A 500 or timeout on
      // replay must surface as that request's error — never clear a session
      // whose rotation just succeeded.
      await _replay(opts, token, handler);
      final queued = List<
              ({RequestOptions opts, ErrorInterceptorHandler handler})>.from(
          _queue);
      _queue.clear();
      // Replays are independent: run them concurrently instead of serially.
      await Future.wait(
        queued.map((q) => _replayQueued(q, token)),
      );
    } catch (e, st) {
      // Only a failed refresh/rotation reaches here.
      AppLogger.e('Refresh failed — clearing session', e, st);
      unawaited(
        ErrorReporter.report(
          e,
          st,
          reason: 'token_refresh_failed',
          context: {
            'stage': 'refresh',
            'status': status ?? 0,
          },
        ),
      );
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

  /// Never throws: a replay failure belongs to the replaying request.
  Future<void> _replay(
    RequestOptions opts,
    String token,
    ErrorInterceptorHandler handler,
  ) async {
    final replayOpts = opts
      ..headers['Authorization'] = 'Bearer $token'
      ..extra['skipAuthRefresh'] = true;
    try {
      handler.resolve(await _dio.fetch<dynamic>(replayOpts));
    } on DioException catch (e) {
      handler.next(e);
    } catch (e, st) {
      AppLogger.w('Request replay failed: $e', e, st);
      handler.next(DioException(requestOptions: replayOpts, error: e));
    }
  }

  /// Never throws: one queued failure must not cancel the other replays.
  Future<void> _replayQueued(
    ({RequestOptions opts, ErrorInterceptorHandler handler}) q,
    String token,
  ) async {
    final queuedOpts = q.opts
      ..headers['Authorization'] = 'Bearer $token'
      ..extra['skipAuthRefresh'] = true;
    try {
      q.handler.resolve(await _dio.fetch<dynamic>(queuedOpts));
    } on DioException catch (e) {
      q.handler.next(e);
    } catch (e, st) {
      AppLogger.w('Queued request replay failed: $e', e, st);
      q.handler.next(DioException(requestOptions: queuedOpts, error: e));
    }
  }
}

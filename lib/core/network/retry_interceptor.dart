import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import '../logging/app_logger.dart';

/// Honors `Retry-After` on 429 and `X-RateLimit-*` backoff.
/// Uses exponential backoff with jitter for 5xx / network errors.
///
/// Contract (`MOBILE_API_INTEGRATION_GUIDE.md`): never retry non-idempotent
/// POSTs unless the server explicitly asks (429 Retry-After — rate-limited
/// calls never reached execution) or the call carries an `Idempotency-Key`
/// (server dedupes replays).
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
  });

  /// The live client — retries reuse the original interceptors, TLS policy and
  /// baseUrl instead of a stripped-down clone.
  final Dio dio;

  final int maxRetries;
  final Duration baseDelay;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final opts = err.requestOptions;
    final attempt = (opts.extra['retry_attempt'] as int?) ?? 0;

    if (attempt >= maxRetries) {
      handler.next(err);
      return;
    }

    final status = err.response?.statusCode;
    if (!_shouldRetry(err, status)) {
      handler.next(err);
      return;
    }

    final delay = _computeDelay(err, attempt);
    AppLogger.w(
      'Retrying ${opts.method} ${opts.path} '
      '(attempt ${attempt + 1}/$maxRetries) after ${delay.inMilliseconds}ms '
      'status=$status req=${opts.headers['X-Request-Id']}',
    );

    await Future<void>.delayed(delay);

    final newOpts = opts.copyWith(
      extra: {...opts.extra, 'retry_attempt': attempt + 1},
    );

    try {
      final response = await dio.fetch<dynamic>(newOpts);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(DioException err, int? status) {
    final opts = err.requestOptions;
    final method = opts.method.toUpperCase();
    final replaySafe = method == 'GET' ||
        method == 'HEAD' ||
        method == 'OPTIONS' ||
        opts.headers.containsKey('Idempotency-Key');

    // Always retry 429 (rate limit) — server says when via Retry-After.
    if (status == 429) return true;
    // Retry 5xx and network timeouts only when the server can dedupe replays.
    if (status != null && status >= 500 && status < 600) return replaySafe;
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return replaySafe;
    }
    return false;
  }

  Duration _computeDelay(DioException err, int attempt) {
    // Honor Retry-After header (seconds or http-date), capped at 60s so a
    // distant server date (or a stuck origin) cannot stall the UI for hours.
    final retryAfter = err.response?.headers.value('retry-after');
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) return Duration(seconds: seconds.clamp(1, 60));
      // Try http-date (e.g., Wed, 21 Oct 2015 07:28:00 GMT)
      try {
        final date = HttpDate.parse(retryAfter);
        final diff = date.difference(DateTime.now());
        if (!diff.isNegative) {
          return Duration(seconds: diff.inSeconds.clamp(1, 60));
        }
      } catch (_) {
        // Malformed http-date — fall through to backoff.
      }
    }

    // Honor X-RateLimit-Reset if present.
    final reset = err.response?.headers.value('x-ratelimit-reset');
    if (reset != null) {
      final epoch = int.tryParse(reset);
      if (epoch != null) {
        final resetDate = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
        final diff = resetDate.difference(DateTime.now());
        if (!diff.isNegative && diff.inSeconds < 60) return diff;
      }
    }

    // Exponential backoff: base * 2^attempt + jitter 0-250ms
    final exp = baseDelay * (1 << attempt);
    final jitter = Duration(milliseconds: Random().nextInt(250));
    return exp + jitter;
  }
}

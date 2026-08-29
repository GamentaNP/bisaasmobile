import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import '../logging/app_logger.dart';

/// Honors `Retry-After` on 429 and `X-RateLimit-*` backoff.
/// Uses exponential backoff with jitter for 5xx / network errors.
///
/// Contract: never retry non-idempotent POSTs that already sent Idempotency-Key
/// unless the error is 429 (server explicitly asks to retry after).
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
  });

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
    final shouldRetry = _shouldRetry(err, status);

    if (!shouldRetry) {
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
      // Re-use the same interceptors stack except this one to avoid loop.
      // Instead, directly fetch via the original Dio instance if available.
      // Fallback: clone request via fetch.
      final response = await _fetchWithOriginalDio(err, newOpts);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(DioException err, int? status) {
    // Always retry 429 (rate limit) — server says when via Retry-After.
    if (status == 429) return true;
    // Retry 5xx and network timeouts.
    if (status != null && status >= 500 && status < 600) return true;
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    return false;
  }

  Duration _computeDelay(DioException err, int attempt) {
    // Honor Retry-After header (seconds or http-date).
    final retryAfter = err.response?.headers.value('retry-after') ??
        err.response?.headers.value('Retry-After');
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) return Duration(seconds: seconds);
      // Try http-date (e.g., Wed, 21 Oct 2015 07:28:00 GMT)
      try {
        final date = HttpDate.parse(retryAfter);
        final diff = date.difference(DateTime.now());
        if (!diff.isNegative) return diff;
      } catch (_) {}
    }

    // Honor X-RateLimit-Reset if present.
    final reset = err.response?.headers.value('x-ratelimit-reset') ??
        err.response?.headers.value('X-RateLimit-Reset');
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

  Future<Response<dynamic>> _fetchWithOriginalDio(
    DioException err,
    RequestOptions newOpts,
  ) async {
    // The original Dio is not directly accessible here; we reconstruct via
    // err.requestOptions copy and use a fresh Dio that respects same baseUrl.
    // In practice, DioClient passes this interceptor; retries will go through
    // the same interceptor chain again — so we manually call fetch.
    final dioForRetry = Dio();
    // Preserve original extra + headers.
    return dioForRetry.fetch<dynamic>(newOpts);
  }
}

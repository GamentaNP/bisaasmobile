import 'dart:async';

import 'package:dio/dio.dart';

import '../logging/app_logger.dart';

/// Collapses identical in-flight GETs into a single network round trip.
///
/// ## Why this exists
///
/// There is exactly one `Dio` in the app (`dio_client.dart`), and about forty
/// places that build a data source from it. Several request the *same* URL and
/// nothing deduplicated them:
///
///   * `GET /me` fires twice on every cold start — once from `AuthNotifier.build()`
///     and again from `HomeRemoteDataSource.getDashboard()`.
///   * `GET /quiz/courses` has six independent call sites.
///   * `GET /learning/today` has three (home, learning, coaching).
///   * `GET /quiz/game/missions/dashboard` has two.
///
/// On a 3G connection that is the difference between a first paint waiting on
/// seven requests and one waiting on four. It is also pure waste against a
/// rate-limited API.
///
/// ## How
///
/// The first caller is the **leader**: it is not held at all, it just proceeds
/// and its own response settles everyone waiting. Any caller that arrives while
/// the leader is still in flight becomes a **follower** and receives a response
/// built from the leader's, without opening a second connection.
///
/// Deliberately simpler than re-issuing the request through a second `Dio`:
/// that would risk re-entering this interceptor, duplicating the auth-header
/// logic, and sharing a mutable `RequestOptions` across callers.
///
/// ## What it deliberately does not do
///
/// * **Only GET.** A POST is not safe to collapse: two callers pressing "buy"
///   must produce two orders. `Idempotency-Key` makes a POST safe to *retry*
///   (`RetryInterceptor` handles that) but never safe to *coalesce*.
/// * **Only concurrent requests.** The map entry is removed the moment the
///   leader settles, so this is not a cache and cannot serve stale data.
/// * **Never joins a replay.** A `RetryInterceptor` or `RefreshInterceptor`
///   replay must run on its own or the retry would wait on the request that
///   failed.
/// * **Sits behind `ResponseCacheInterceptor`.** A cache hit short-circuits
///   before this, which is fine: there is no round trip left to deduplicate.
class RequestCoalescer extends Interceptor {
  final Map<String, _InFlight> _inFlight = {};

  /// Test seam: how many requests are currently in flight.
  int get inFlightCount => _inFlight.length;

  /// A stable identity for "the same request".
  ///
  /// The query map is included because several endpoints are distinguished only
  /// by query, and `Accept-Language` is included because a Nepali session and an
  /// English session must never share a body.
  static String keyFor(RequestOptions options) {
    final parts = options.queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .toList()
      ..sort();
    final language = options.headers['Accept-Language'] ?? '';
    return '${options.method.toUpperCase()} ${options.path}'
        '${parts.isEmpty ? '' : '?${parts.join('&')}'}|$language';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isCoalescable(options)) {
      handler.next(options);
      return;
    }

    final key = keyFor(options);
    final pending = _inFlight[key];
    if (pending != null) {
      AppLogger.d('coalesced duplicate GET ${options.path}');
      pending.join(options, handler);
      return;
    }

    // Become the leader. Registering before `next` means an identical call
    // arriving in the same microtask still finds us.
    _inFlight[key] = _InFlight();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _settle(
      response.requestOptions,
      response: response,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _settle(err.requestOptions, error: err);
    handler.next(err);
  }

  /// Removes the key and settles everyone waiting on the leader.
  ///
  /// A follower's own response also passes through here, but by then its key is
  /// gone, so this is a no-op for it. That is what stops a follower from
  /// settling the leader it is following.
  void _settle(
    RequestOptions options, {
    Response<dynamic>? response,
    DioException? error,
  }) {
    if (!_isCoalescable(options)) return;
    final entry = _inFlight.remove(keyFor(options));
    if (entry == null) return;
    if (error != null) {
      entry.fail(error);
    } else if (response != null) {
      entry.succeed(response);
    }
  }

  bool _isCoalescable(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') return false;
    // A retry or auth-refresh replay is work already being redone elsewhere.
    if (options.extra['retry_attempt'] != null) return false;
    if (options.extra['skipAuthRefresh'] == true) return false;
    // Streaming bodies must not be shared; each caller reads its own.
    if (options.responseType == ResponseType.stream) return false;
    return true;
  }
}

/// One leader request plus the followers waiting on it.
class _InFlight {
  final Completer<Response<dynamic>> _completer =
      Completer<Response<dynamic>>();

  /// Whether anyone is actually listening.
  ///
  /// A leader that fails with no followers must not call `completeError`: the
  /// Completer would have no listener, Dart reports it as an unhandled async
  /// error, and the test zone (or the app's error handler) sees a failure that
  /// never happened. Most GETs in this app are leaders with no followers, so
  /// this is the common case, not the edge case.
  bool _hasJoiners = false;

  /// Hands [handler] the leader's response once it lands.
  ///
  /// The response is rebuilt against the *follower's* own `RequestOptions`
  /// rather than handed over wholesale, so no consumer can end up reading
  /// another caller's request object.
  void join(RequestOptions follower, RequestInterceptorHandler handler) {
    _hasJoiners = true;
    _completer.future.then(
      (leaderResponse) => handler.resolve(
        Response<dynamic>(
          requestOptions: follower,
          data: leaderResponse.data,
          statusCode: leaderResponse.statusCode,
          statusMessage: leaderResponse.statusMessage,
          headers: leaderResponse.headers,
          isRedirect: leaderResponse.isRedirect,
          redirects: leaderResponse.redirects,
          extra: leaderResponse.extra,
        ),
      ),
      onError: (Object error, StackTrace _) {
        if (error is DioException) {
          handler.reject(error, true);
        } else {
          handler.reject(
            DioException(requestOptions: follower, error: error),
            true,
          );
        }
      },
    );
  }

  void succeed(Response<dynamic> response) {
    if (!_completer.isCompleted) _completer.complete(response);
  }

  void fail(DioException error) {
    if (!_hasJoiners || _completer.isCompleted) {
      // Nobody is waiting, so completing with an error would be an unhandled
      // async error. The leader's own caller already receives the real
      // DioException through the normal Dio error path.
      return;
    }
    _completer.completeError(error);
  }
}

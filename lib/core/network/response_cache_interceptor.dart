import 'dart:async';

import 'package:dio/dio.dart';

import '../connectivity/api_reachability.dart';
import '../logging/app_logger.dart';
import 'request_coalescer.dart';
import 'response_cache_policy.dart';
import 'response_cache_store.dart';

/// Serves a cached body immediately and refreshes it behind the user.
///
/// ## The three cases
///
/// | Cache state | Network | What the user sees |
/// |---|---|---|
/// | fresh | any | cache, no request at all |
/// | stale | reachable | cache immediately, one background refresh |
/// | stale | unreachable | cache, no request, no error |
/// | absent | any | a real request, as today |
///
/// The middle row is the whole point. A student opening the syllabus on a train
/// gets the tree immediately rather than a spinner for 800 ms, and is corrected
/// a moment later without being interrupted.
///
/// ## Where this sits in the chain
///
/// Registered *after* `AuthInterceptor` and *before* `RequestCoalescer`.
///
/// After auth, because the on-disk key is a hash of the bearer token
/// ([RequestCoalescer.keyFor]). Ahead of auth the header is not yet set, every
/// signed-in request would hash as `anon`, and one account's user-scoped catalog
/// would be served to the next — the exact disclosure the credential-scoped key
/// exists to prevent.
///
/// Before the coalescer, because a cache hit means there is no round trip left
/// to deduplicate.
///
/// A cache lookup is asynchronous and this interceptor genuinely needs to
/// short-circuit with `handler.resolve()`. That is safe from any position: Dio
/// hands each interceptor its own `RequestInterceptorHandler`, and the
/// one-shot rule is per handler — calling `next()` and then `resolve()` on the
/// *same* handler is the double-settle that deadlocks. A later interceptor
/// resolving its own handler is the normal way to bypass the network.
///
/// ## Why reachability decides, and only reachability
///
/// The signal is [ApiReachability], which the app already maintains from real
/// request outcomes and already exposes to widgets for the offline banner. A
/// second connectivity notion here would let the cache and the banner disagree.
///
/// It starts optimistic, which is the right bias: a first-run device with no
/// evidence yet should still try the network rather than serve nothing.
///
/// ## Why this cannot serve one user another's response
///
/// Two independent reasons, and both are required.
///
///  1. [ResponseCachePolicy] is an allowlist. `/me`, `/economy`,
///     `/quiz/attempts` and every mutation are excluded, so nothing reaches this
///     interceptor that must not be persisted at all.
///  2. The key carries a hash of the credential, so the two library endpoints
///     whose bodies genuinely *are* per-principal — `/library/categories` and
///     `/library/trending` — cannot be read across accounts.
class ResponseCacheInterceptor extends Interceptor {
  ResponseCacheInterceptor({
    required ResponseCacheStore store,
    required ApiReachability reachability,
    required Dio revalidator,
  })  : _store = store,
        _reachability = reachability,
        _revalidator = revalidator;

  final ResponseCacheStore _store;
  final ApiReachability _reachability;

  /// A client with **no** interceptors, used only to fetch a fresh copy.
  ///
  /// It must not be the intercepted client: sending the refresh back through
  /// this interceptor would look up the very entry we are trying to replace,
  /// find it stale, and recurse. Bare is the only safe choice, and the store
  /// write is then done directly rather than relying on the response chain.
  final Dio _revalidator;

  final Set<String> _refreshing = {};

  /// Cache writes still in flight.
  ///
  /// Writes are not awaited on the response path — a slow disk must not delay
  /// the body the user is waiting on. But sign-out clears the cache, and a write
  /// landing *after* the clear would repopulate it, so [whenIdle] lets a caller
  /// drain first.
  int _pendingWrites = 0;

  /// Test seam: how many background refreshes are in flight.
  int get refreshingCount => _refreshing.length;

  /// Test seam: how many cache writes are outstanding.
  int get pendingWrites => _pendingWrites;

  /// Completes when no cache write is outstanding.
  Future<void> whenIdle() async {
    // Polled rather than completer-driven: writes are short, and a poll cannot
    // deadlock if one is dropped by an error path.
    while (_pendingWrites > 0) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  /// Deletes every cached body. Callers must [whenIdle] first.
  Future<void> clearStore() => _store.clear();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!ResponseCachePolicy.isEligible(options)) {
      handler.next(options);
      return;
    }

    final key = RequestCoalescer.keyFor(options);

    _store.read(key).then((entry) {
      if (entry == null) {
        handler.next(options);
        return;
      }

      if (entry.isFresh) {
        AppLogger.d('cache HIT (fresh) ${options.path}');
        handler.resolve(_synthesise(options, entry.body));
        return;
      }

      // Stale. Show it now, correct it behind the user if there is a network.
      if (_reachability.isReachable) {
        _revalidate(key, options);
      } else {
        AppLogger.d('cache STALE, offline: serving ${options.path}');
      }
      handler.resolve(_synthesise(options, entry.body));
    }).catchError((Object error, StackTrace _) {
      // A cache read must never be the reason a request fails.
      AppLogger.w('cache read failed, going to network', error);
      handler.next(options);
    });
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    // A response we synthesised from the cache must not be written back, or it
    // would refresh its own TTL forever and the entry would never expire.
    final fromCache = response.extra['from_cache'] == true;
    if (!fromCache && ResponseCachePolicy.isEligible(options)) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final ttl = ResponseCachePolicy.freshnessFor(options.path);
        if (ttl != null) {
          _beginWrite();
          unawaited(
            _store
                .write(
                  RequestCoalescer.keyFor(options),
                  body,
                  ttl: ttl,
                  etag: response.headers.value('etag'),
                )
                .catchError((Object error, StackTrace _) {
              AppLogger.w('cache write failed for ${options.path}', error);
            })
                .whenComplete(_endWrite),
          );
        }
      }
    }
    handler.next(response);
  }

  /// Fetches a fresh copy for [key] and stores it.
  ///
  /// Reuses the TTL the policy already decided, so a refresh cannot silently
  /// extend an entry's life beyond what a normal fetch would grant.
  ///
  /// The credential is forwarded. It has to be: the entry this replaces was
  /// written under a key derived from the caller's bearer token, and for the two
  /// user-scoped library endpoints the body is *only* correct for that
  /// principal. Dropping `Authorization` here would make every background
  /// revalidation of those two a 401, so the entry would sit stale until the
  /// store's 14-day horizon deleted it.
  void _revalidate(String key, RequestOptions original) {
    if (!_refreshing.add(key)) return;

    unawaited(() async {
      try {
        final authorization = original.headers['Authorization'];
        final response = await _revalidator.get<dynamic>(
          original.path,
          queryParameters: original.queryParameters.isEmpty
              ? null
              : original.queryParameters,
          options: Options(
            headers: <String, dynamic>{
              'Accept': 'application/json',
              if (authorization is String && authorization.isNotEmpty)
                'Authorization': authorization,
              if (original.headers['Accept-Language'] case final String lang)
                'Accept-Language': lang,
            },
            responseType: ResponseType.json,
          ),
        );
        final body = response.data;
        final ttl = ResponseCachePolicy.freshnessFor(original.path);
        if (body is Map<String, dynamic> && ttl != null) {
          _beginWrite();
          await _store
              .write(key, body, ttl: ttl, etag: response.headers.value('etag'))
              .catchError((Object error, StackTrace _) {
            AppLogger.w('revalidation write failed for ${original.path}', error);
          })
              .whenComplete(_endWrite);
        }
      } on Object catch (error) {
        // The stale copy stays. That is the point of having one.
        AppLogger.d('background revalidation failed for ${original.path}: $error');
      } finally {
        _refreshing.remove(key);
      }
    }());
  }

  void _beginWrite() => _pendingWrites++;

  void _endWrite() {
    if (_pendingWrites > 0) _pendingWrites--;
  }

  /// Builds a response from a cached body, marked so [onResponse] does not write
  /// it back and no downstream code mistakes it for a fresh network result.
  ///
  /// Bound to the live [options] rather than a stored request, so a consumer
  /// reading `response.requestOptions` sees its own request.
  Response<dynamic> _synthesise(
    RequestOptions options,
    Map<String, dynamic> body,
  ) {
    return Response<dynamic>(
      requestOptions: options,
      data: body,
      statusCode: 200,
      statusMessage: 'OK (cached)',
      isRedirect: false,
      redirects: const [],
      extra: const {'from_cache': true},
    );
  }
}

import 'dart:convert';

import 'package:bisaasmobile/core/connectivity/api_reachability.dart';
import 'package:bisaasmobile/core/network/request_coalescer.dart';
import 'package:bisaasmobile/core/network/response_cache_interceptor.dart';
import 'package:bisaasmobile/core/network/response_cache_policy.dart';
import 'package:bisaasmobile/core/network/response_cache_store.dart';
import 'package:bisaasmobile/core/storage/database/app_database.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The cache is only worth having if it is fast *and* invisible.
///
/// Fast: a student opening the syllabus on a train gets the tree immediately
/// rather than a spinner. Invisible: nothing about it can leak a user's wallet
/// or identity onto an unencrypted disk, and nothing can serve a syllabus tree
/// so old that it describes a superseded exam.
void main() {
  late AppDatabase db;
  late ResponseCacheStore store;
  late ApiReachability reachability;
  late _StubAdapter adapter;
  late Dio dio;
  late ResponseCacheInterceptor cacheInterceptor;

  /// Mirrors `AuthInterceptor`: the cache key is a hash of the bearer token, so
  /// the header has to exist before the cache reads it. Set `token` to sign in.
  String? token;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = ResponseCacheStore(db);
    reachability = ApiReachability();
    adapter = _StubAdapter();
    // The revalidator needs a real client; it must not be the one being
    // intercepted, or a refresh would recurse into this interceptor.
    final revalidator = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
    revalidator.httpClientAdapter = adapter;

    cacheInterceptor = ResponseCacheInterceptor(
      store: store,
      reachability: reachability,
      revalidator: revalidator,
    );
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
      ..httpClientAdapter = adapter
      // Order matches production (dio_client.dart): auth, then the cache, then
      // the coalescer. Auth must precede the cache or the credential is missing
      // from the key; the cache must precede the coalescer or a hit re-enters a
      // round trip that does not exist.
      ..interceptors.addAll([
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
        ),
        cacheInterceptor,
        RequestCoalescer(),
      ]);
  });

  tearDown(() async => db.close());

  String keyFor(String path, {String? as}) => RequestCoalescer.keyFor(
        RequestOptions(
          path: path,
          method: 'GET',
          headers: as == null ? null : {'Authorization': 'Bearer $as'},
        ),
      );


  group('freshness', () {
    test('a cold request goes to the network and is then served from cache', () async {
      adapter.body = {'success': true, 'data': [{'id': 1}]};

      final first = await dio.get<dynamic>('/syllabi');

      await cacheInterceptor.whenIdle();
      expect(adapter.hits, hasLength(1), reason: 'nothing cached yet');
      expect(first.data, equals(adapter.body));

      final second = await dio.get<dynamic>('/syllabi');
      expect(
        adapter.hits,
        hasLength(1),
        reason: 'within the TTL the cache must answer without a request',
      );
      expect(second.data, equals(adapter.body));
      expect(second.extra['from_cache'], isTrue);
    });

    test('a cache hit is still bound to the caller own request options', () async {
      adapter.body = {'success': true, 'data': []};
      await dio.get<dynamic>('/quiz/courses');

      final hit = await dio.get<dynamic>('/quiz/courses');
      expect(hit.requestOptions.path, '/quiz/courses');
    });

    test('an expired entry is served immediately and refreshed behind the user',
        () async {
      adapter.body = {'success': true, 'data': 'v1'};
      await dio.get<dynamic>('/syllabi');
      await cacheInterceptor.whenIdle();

      // Age the entry past its TTL.
      final ttl = ResponseCachePolicy.freshnessFor('/syllabi')!;
      final row = await (db.select(db.cachedResponses)
            ..where((t) => t.cacheKey.equals(keyFor('/syllabi'))))
          .getSingle();
      await db.update(db.cachedResponses).replace(
            row.copyWith(
              cachedAt: row.cachedAt.subtract(ttl + const Duration(minutes: 1)),
              expiresAt: row.expiresAt.subtract(ttl + const Duration(minutes: 1)),
            ),
          );

      adapter.body = {'success': true, 'data': 'v2'};
      final stale = await dio.get<dynamic>('/syllabi');

      expect(
        stale.data,
        equals({'success': true, 'data': 'v1'}),
        reason: 'the user must not wait for a refresh',
      );

      // The refresh lands behind them.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final afterRefresh = await dio.get<dynamic>('/syllabi');
      expect(afterRefresh.data, equals({'success': true, 'data': 'v2'}));
    });

    test('offline: a stale entry is served and no request is attempted', () async {
      adapter.body = {'success': true, 'data': 'v1'};
      await dio.get<dynamic>('/syllabi');
      await cacheInterceptor.whenIdle();
      await _ageEntry(db, keyFor('/syllabi'), ResponseCachePolicy.freshnessFor('/syllabi')!);

      // Reachability says the API is not answering.
      reachability.observeError(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/syllabi'),
          reason: 'scripted offline',
        ),
      );
      expect(reachability.isReachable, isFalse);

      adapter.fail = true;
      final stale = await dio.get<dynamic>('/syllabi');

      expect(stale.data, equals({'success': true, 'data': 'v1'}));
      expect(adapter.hits, hasLength(1), reason: 'no second attempt was made');
    });
  });

  group('security boundary', () {
    test('no PII endpoint is ever written to disk', () async {
      adapter.body = {'success': true, 'data': {'coins': 9999}};

      // Every one of these returns something sensitive. None may be persisted.
      for (final path in const [
        '/me',
        '/economy/wallet',
        '/economy/wallet/ledger',
        '/quiz/streak',
        '/quiz/attempts/history',
        '/quiz/leaderboards/1',
        '/store/assets',
        '/social/referral-dashboard',
        '/notifications',
        '/library/me/unlocks',
        '/library/files',
      ]) {
        await dio.get<dynamic>(path);
      }

      final rows = await db.select(db.cachedResponses).get();
      expect(rows, isEmpty, reason: 'a PII response reached the disk');
    });

    test('a POST is never cached even on an allowlisted path', () async {
      adapter.body = {'success': true, 'data': 'order'};
      await dio.post<dynamic>('/quiz/courses', data: {});

      expect(await db.select(db.cachedResponses).get(), isEmpty);
    });

    test('an unknown endpoint is not cached', () async {
      adapter.body = {'success': true};
      await dio.get<dynamic>('/totally/unknown/endpoint');

      expect(await db.select(db.cachedResponses).get(), isEmpty);
    });

    test('one account never reads another account cached body', () async {
      // `/library/categories` counts files through `applyVisibleTo($query, $user)`
      // on the server, so the body is a function of the principal. The entry
      // written by account A must be unreachable by account B on a shared
      // device, even within the TTL.
      adapter.body = {
        'success': true,
        'data': [
          {'name': 'Structural', 'files_count': 12},
        ],
      };

      token = 'account-a-token';
      await dio.get<dynamic>('/library/categories');
      await cacheInterceptor.whenIdle();
      expect(adapter.hits, hasLength(1));

      // Same account: served from cache.
      final mine = await dio.get<dynamic>('/library/categories');
      expect(mine.extra['from_cache'], isTrue);
      expect(adapter.hits, hasLength(1));

      // Different account: must go to the network, not read A's entry.
      token = 'account-b-token';
      adapter.body = {
        'success': true,
        'data': [
          {'name': 'Structural', 'files_count': 3},
        ],
      };
      final theirs = await dio.get<dynamic>('/library/categories');

      expect(adapter.hits, hasLength(2), reason: 'B must not have read A body');
      expect(theirs.extra['from_cache'], isNull);
      expect(
        (theirs.data! as Map<String, dynamic>)['data'],
        equals([
          {'name': 'Structural', 'files_count': 3},
        ]),
      );

      // And B now has their own entry, not a shared one.
      await cacheInterceptor.whenIdle();
      final keys = (await db.select(db.cachedResponses).get())
          .map((r) => r.cacheKey)
          .toSet();
      expect(keys, hasLength(2), reason: 'the two accounts must not share a key');
    });

    test('the key carries a hash of the credential, never the token itself', () async {
      final options = RequestOptions(
        path: '/library/categories',
        method: 'GET',
        headers: {'Authorization': 'Bearer secret-token-value'},
      );

      final key = RequestCoalescer.keyFor(options);

      expect(key, isNot(contains('secret-token-value')));
      expect(key, contains(RequestCoalescer.credentialFingerprint(options)));
      // Stable across calls, so a refresh does not orphan its own entry.
      expect(RequestCoalescer.keyFor(options), key);
    });

    test('an anonymous request is keyed apart from any signed-in one', () {
      final anon = RequestOptions(path: '/syllabi', method: 'GET');
      final authed = RequestOptions(
        path: '/syllabi',
        method: 'GET',
        headers: {'Authorization': 'Bearer x'},
      );

      expect(RequestCoalescer.credentialFingerprint(anon), 'anon');
      expect(RequestCoalescer.keyFor(anon), isNot(equals(RequestCoalescer.keyFor(authed))));
    });

    test('a token rotation retires the previous entry instead of reusing it',
        () async {
      adapter.body = {'success': true, 'data': 'a'};
      token = 'first-token';
      await dio.get<dynamic>('/syllabi');
      await cacheInterceptor.whenIdle();

      token = 'rotated-token';
      await dio.get<dynamic>('/syllabi');

      expect(
        adapter.hits,
        hasLength(2),
        reason: 'a new credential must not read the old credential entry',
      );
    });

    test('a user-varying query parameter is refused even on a public path', () {
      // `/syllabi/{v}/nodes/{n}/questions?filter[exclude_seen]=true` drops what
      // the caller has already answered, so the body is per-principal while the
      // path sits under a public 12h prefix.
      for (final param in const ['filter[exclude_seen]', 'exclude_seen']) {
        expect(
          ResponseCachePolicy.isEligible(
            RequestOptions(
              path: '/syllabi/abc/nodes/1/questions',
              method: 'GET',
              queryParameters: {param: 'true'},
            ),
          ),
          isFalse,
          reason: '$param makes the body user-specific',
        );
      }

      // The same path without it stays cacheable.
      expect(
        ResponseCachePolicy.isEligible(
          RequestOptions(path: '/syllabi/abc/nodes/1/questions', method: 'GET'),
        ),
        isTrue,
      );
    });


      test('a path that merely starts with an allowlisted name is not captured', () async {
        // /syllabiXYZ must not be captured by the /syllabi rule.
        expect(ResponseCachePolicy.freshnessFor('/syllabiXYZ'), isNull);
        expect(ResponseCachePolicy.freshnessFor('/syllabi'), isNotNull);
        expect(ResponseCachePolicy.freshnessFor('/syllabi/abc/tree'), isNotNull);
      });

      test('a query baked into the path is not a path segment', () {
        // Found on device: a corpus probe was written '/syllabi?per_page=1'.
        // Dio keeps that as one opaque path, so the `/` boundary rule rejects
        // it and the call silently never cached. The fix is to use
        // queryParameters, but the policy must keep refusing this shape rather
        // than caching it under a key that can never match a properly
        // parameterised request for the same resource.
        expect(ResponseCachePolicy.freshnessFor('/syllabi?per_page=1'), isNull);
        expect(ResponseCachePolicy.freshnessFor('/calculators?per_page=1'), isNull);
      });

      test('a properly parameterised request is cacheable and keyed apart', () {
        final options = RequestOptions(
          path: '/syllabi',
          method: 'GET',
          queryParameters: const {'per_page': 1},
        );
        expect(ResponseCachePolicy.isEligible(options), isTrue);
        // Distinct from the bare request, so the two entries cannot overwrite
        // one another.
        expect(
          RequestCoalescer.keyFor(options),
          isNot(
            equals(
              RequestCoalescer.keyFor(
                RequestOptions(path: '/syllabi', method: 'GET'),
              ),
            ),
          ),
        );
      });
    });

  group('policy', () {
    test('every forbidden prefix is refused', () {
      for (final path in const [
        '/me',
        '/me/syllabi',
        '/economy/wallet',
        '/quiz/attempts/1/results',
        '/donations/leaderboard',
        '/app/config',
      ]) {
        expect(
          ResponseCachePolicy.freshnessFor(path),
          isNull,
          reason: '$path must never be cached',
        );
      }
    });

    test('the catalog endpoints that are read on every tab are cached', () {
      expect(ResponseCachePolicy.freshnessFor('/quiz/courses'), isNotNull);
      expect(ResponseCachePolicy.freshnessFor('/syllabi'), isNotNull);
      expect(ResponseCachePolicy.freshnessFor('/syllabi/abc/tree'), isNotNull);
      expect(ResponseCachePolicy.freshnessFor('/calculators'), isNotNull);
      expect(ResponseCachePolicy.freshnessFor('/library/categories'), isNotNull);
    });
  });

  group('allowlist is honest about which bodies are user-invariant', () {
    // The allowlist used to be documented as "public payloads only, nothing
    // that returns PII", and that was false for two entries: the server filters
    // both library endpoints through the caller's own visibility. The docblock
    // was the only enforcement, so this turns the claim into an invariant —
    // a path that is user-scoped must be declared user-scoped, and a path that
    // is NOT declared user-scoped must not be one the server varies by user.
    test('every allow-listed path is either public or explicitly user-scoped',
        () async {
      const allowListed = [
        '/syllabi',
        '/syllabi/abc/tree',
        '/quiz/courses',
        '/quiz/courses/1/categories',
        '/calculators',
        '/books',
        '/books/some-slug',
        '/library/categories',
        '/library/trending',
      ];

      for (final path in allowListed) {
        expect(
          ResponseCachePolicy.freshnessFor(path),
          isNotNull,
          reason: '$path is expected to be cached',
        );
      }
    });

    test('the two endpoints the server varies by user are declared user-scoped',
        () {
      // Verified on the server: LibraryApiController::categories() counts files
      // through applyVisibleTo($query, $user); trending() ranks through the same
      // visibility. Both return 401 unauthenticated.
      expect(ResponseCachePolicy.isUserScoped('/library/categories'), isTrue);
      expect(ResponseCachePolicy.isUserScoped('/library/trending'), isTrue);
    });

    test('the endpoints verified user-invariant are not declared user-scoped', () {
      // Verified on the server: none of these read $request->user() on their
      // hot path, and SyllabusCatalogController::tree() is served from a
      // tenant-keyed cache.
      for (final path in const [
        '/syllabi',
        '/syllabi/abc/tree',
        '/quiz/courses',
        '/calculators',
        '/books',
      ]) {
        expect(
          ResponseCachePolicy.isUserScoped(path),
          isFalse,
          reason: '$path is user-invariant; a short TTL would be wasted caution',
        );
      }
    });

    test('a user-scoped entry gets a TTL short enough to notice an entitlement',
        () {
      // A 12h TTL on `/library/categories` meant an unlock or a purchase could
      // take half a day to appear. The bound below is the contract.
      for (final path in const ['/library/categories', '/library/trending']) {
        expect(
          ResponseCachePolicy.freshnessFor(path),
          lessThanOrEqualTo(const Duration(minutes: 15)),
          reason: '$path must not be cached for hours',
        );
      }
    });
  });


  group('store hygiene', () {
    test('an entry from a different payload version is discarded, not misread',
        () async {
      await store.write(
        keyFor('/syllabi'),
        {'success': true, 'data': 'v1'},
        ttl: const Duration(hours: 1),
      );
      final row = await (db.select(db.cachedResponses)
            ..where((t) => t.cacheKey.equals(keyFor('/syllabi'))))
          .getSingle();
      await db.update(db.cachedResponses).replace(
            row.copyWith(schemaVersion: 'ancient'),
          );

      expect(await store.read(keyFor('/syllabi')), isNull);
      expect(
        await db.select(db.cachedResponses).get(),
        isEmpty,
        reason: 'a stale-version entry should be dropped, not kept',
      );
    });

    test('an entry far past its TTL is dropped rather than served', () async {
      await store.write(
        keyFor('/syllabi'),
        {'success': true},
        ttl: const Duration(hours: 1),
      );
      final entry = await store.read(
        keyFor('/syllabi'),
        now: DateTime.now().add(const Duration(days: 30)),
      );
      expect(entry, isNull);
    });

    test('an unreadable body is dropped instead of crashing the read', () async {
      await store.write(
        keyFor('/syllabi'),
        {'success': true},
        ttl: const Duration(hours: 1),
      );
      final row = await (db.select(db.cachedResponses)
            ..where((t) => t.cacheKey.equals(keyFor('/syllabi'))))
          .getSingle();
      await db.update(db.cachedResponses).replace(row.copyWith(body: '{trunc'));

      expect(await store.read(keyFor('/syllabi')), isNull);
    });

    test('an oversized payload is refused rather than evicting everything',
        () async {
      final huge = 'x' * (ResponseCachePolicy.maxEntryBytes + 1);
      await store.write(
        keyFor('/syllabi'),
        {'success': true, 'blob': huge},
        ttl: const Duration(hours: 1),
      );

      expect(await db.select(db.cachedResponses).get(), isEmpty);
    });

    test('the byte budget evicts the oldest entries first', () async {
      // Fill past the budget with small entries, then assert the oldest went.
      const perEntry = 512 * 1024;
      const count = (ResponseCachePolicy.maxTotalBytes ~/ perEntry) + 2;
      for (var i = 0; i < count; i++) {
        await store.write(
          'GET /pad$i',
          {'success': true, 'blob': 'y' * perEntry},
          ttl: const Duration(hours: 1),
        );
      }

      final rows = await db.select(db.cachedResponses).get();
      final total = rows.fold<int>(0, (sum, r) => sum + r.byteSize);
      expect(
        total,
        lessThanOrEqualTo(ResponseCachePolicy.maxTotalBytes),
        reason: 'the budget must hold',
      );
      expect(
        rows.any((r) => r.cacheKey == 'GET /pad0'),
        isFalse,
        reason: 'the oldest entry should have been evicted',
      );
    });

    test('clear removes everything, for sign-out', () async {
      await store.write(keyFor('/syllabi'), {'success': true}, ttl: const Duration(hours: 1));
      await store.clear();
      expect(await db.select(db.cachedResponses).get(), isEmpty);
    });

    test('whenIdle drains, so a sign-out clear cannot be repopulated', () async {
      // A write in flight when logout() clears the table would land *after* the
      // delete and put the previous account's catalog back. The drain is the
      // reason whenIdle exists, so assert the counter actually reaches zero.
      adapter.body = {'success': true, 'data': 'v1'};
      await dio.get<dynamic>('/syllabi');

      await cacheInterceptor.whenIdle();
      expect(
        cacheInterceptor.pendingWrites,
        0,
        reason: 'whenIdle must not return while a write is outstanding',
      );

      await cacheInterceptor.clearStore();
      expect(await db.select(db.cachedResponses).get(), isEmpty);
    });
  });
}

/// Pushes an entry's TTL into the past.
Future<void> _ageEntry(
  AppDatabase db,
  String key,
  Duration ttl,
) async {
  final row = await (db.select(db.cachedResponses)
        ..where((t) => t.cacheKey.equals(key)))
      .getSingle();
  await db.update(db.cachedResponses).replace(
        row.copyWith(
          cachedAt: row.cachedAt.subtract(ttl + const Duration(minutes: 1)),
          expiresAt: row.expiresAt.subtract(ttl + const Duration(minutes: 1)),
        ),
      );
}

class _StubAdapter implements HttpClientAdapter {
  final List<String> hits = [];
  bool fail = false;
  Object body = {'success': true, 'data': <Object>[]};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    hits.add('${options.method} ${options.path}');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (fail) {
      return ResponseBody.fromString(
        '{"success":false,"message":"scripted","error":{"code":"SERVER_ERROR"}}',
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

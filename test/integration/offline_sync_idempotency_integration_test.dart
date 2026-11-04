/// P5-32 — the offline queue's idempotency proven through the HTTP stack.
///
/// The unit test (`test/core/sync/sync_queue_replay_test.dart`) proves the row
/// keeps its key. This file proves the *request* does: a real `Dio` →
/// interceptor chain → `HttpClientAdapter`, with a scripted transport that can
/// fail the first attempt and succeed on the next.
///
/// The server semantics this mirrors (`App\Http\Middleware\EnsureApiIdempotency`):
///
///   * a key is scoped per user, stored on the first successful response and
///     replayed with `X-Idempotent-Replay: true`;
///   * a 5xx or 429 response is **not** stored, so the retry executes again;
///   * the request hash includes method, path and body, so the same key with a
///     different payload is `409 IDEMPOTENCY_CONFLICT` — which is why one key
///     belongs to one logical operation, not to a whole offline session.
///
/// What a regression looks like: `bump()` or `SyncManager` mints a new key on
/// retry, and the server records a second write. Nothing in the client would
/// notice — which is exactly why the header value is asserted on every attempt
/// rather than only the final state.
library;

import 'package:bisaasmobile/core/connectivity/connectivity_service.dart';
import 'package:bisaasmobile/core/network/auth_interceptor.dart';
import 'package:bisaasmobile/core/security/token_manager.dart';
import 'package:bisaasmobile/core/storage/database/app_database.dart';
import 'package:bisaasmobile/core/storage/database/daos/sync_queue_dao.dart';
import 'package:bisaasmobile/core/sync/sync_manager.dart';
import 'package:bisaasmobile/core/sync/sync_queue.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'support/fake_api.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AppDatabase db;
  late SyncQueueService queue;
  late DateTime clock;
  late _MockConnectivity connectivity;
  late _MockSecureStorage storage;

  setUp(() {
    clock = DateTime.utc(2026, 11, 4, 12);
    db = AppDatabase(NativeDatabase.memory());
    queue = SyncQueueService(
      SyncQueueDao(db, now: () => clock),
      now: () => clock,
    );
    connectivity = _MockConnectivity();
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    storage = _MockSecureStorage();
    when(() => storage.read(key: 'auth_token'))
        .thenAnswer((_) async => 'pat-session');
    when(() => storage.read(key: 'device_name'))
        .thenAnswer((_) async => 'integration-test');
  });

  tearDown(() async => db.close());

  /// The production chain, minus the pieces this test does not exercise:
  /// the auth interceptor is real, so the queued request carries the session
  /// the retry will actually be attributed to.
  Dio dioWithAuth(FakeApi api) {
    final dio = dioFor(api);
    dio.interceptors.add(AuthInterceptor(TokenManager(storage: storage)));
    return dio;
  }

  SyncManager managerFor(FakeApi api) => SyncManager(
        queue: queue,
        dio: dioWithAuth(api),
        connectivity: connectivity,
      );

  Future<List<SyncQueueData>> rows() => db.select(db.syncQueue).get();

  /// Moves past the backoff deadline the failed attempt wrote.
  void advancePastBackoff() {
    clock = clock.add(const Duration(minutes: 5));
  }

  group('a failed attempt retries the same operation', () {
    test('500 then 200: identical Idempotency-Key on both attempts', () async {
      final api = FakeApi(<String, FakeRoute>{})
        ..onSequence('PUT', '/calculation-snapshots', <FakeRoute>[
          FakeRoute.error(500, 'INTERNAL_ERROR', 'Server exploded.'),
          FakeRoute.ok(<String, dynamic>{'synced': 1}),
        ]);

      await queue.enqueueSnapshot(
        domain: 'civil',
        calculatorSlug: 'bmr',
        inputs: const <String, dynamic>{'weight_kg': 70},
        result: const <String, dynamic>{'bmi': 24.5},
      );
      final key = (await rows()).single.idempotencyKey!;

      final manager = managerFor(api);

      await manager.syncNow();
      expect(api.countOf('PUT', '/calculation-snapshots'), 1);
      expect(
        (await rows()).single.idempotencyKey,
        key,
        reason: 'a failed attempt must not rewrite the operation identity',
      );

      advancePastBackoff();
      await manager.syncNow();

      expect(api.countOf('PUT', '/calculation-snapshots'), 2);
      expect(api.headerOf(0, 'Idempotency-Key'), key);
      expect(api.headerOf(1, 'Idempotency-Key'), key);
      expect(
        await rows(),
        isEmpty,
        reason: 'the successful retry drains the row',
      );
    });

    test('429 then 200: the Retry-After path keeps the same key', () async {
      // A throttle is the most likely failure on a burst of queued writes, and
      // it is the one a careless implementation treats as "start over".
      final api = FakeApi(<String, FakeRoute>{})
        ..onSequence('POST', '/quiz/offline/match-receipt', <FakeRoute>[
          FakeRoute.error(429, 'RATE_LIMIT_EXCEEDED', 'Slow down.'),
          FakeRoute.ok(<String, dynamic>{'recorded': true}),
        ]);

      await queue.enqueueOfflineMatchReceipt(
        manifestId: 'manifest-7',
        payload: const <String, dynamic>{'score': 3},
      );

      final manager = managerFor(api);
      await manager.syncNow();
      advancePastBackoff();
      await manager.syncNow();

      expect(api.countOf('POST', '/quiz/offline/match-receipt'), 2);
      expect(api.headerOf(0, 'Idempotency-Key'), 'manifest-7');
      expect(api.headerOf(1, 'Idempotency-Key'), 'manifest-7');
      expect(await rows(), isEmpty);
    });

    test('three attempts, one key, one row', () async {
      final api = FakeApi(<String, FakeRoute>{})
        ..onSequence('PUT', '/calculation-snapshots', <FakeRoute>[
          FakeRoute.error(500, 'INTERNAL_ERROR', 'first'),
          FakeRoute.error(503, 'SERVICE_UNAVAILABLE', 'second'),
          FakeRoute.ok(<String, dynamic>{'synced': 1}),
        ]);

      await queue.enqueueSnapshot(
        domain: 'civil',
        inputs: const <String, dynamic>{'a': 1},
        result: const <String, dynamic>{'b': 2},
      );
      final key = (await rows()).single.idempotencyKey!;
      final manager = managerFor(api);

      for (var attempt = 0; attempt < 3; attempt++) {
        await manager.syncNow();
        // A failed attempt leaves the one row; the successful third drains it.
        expect(
          await rows(),
          hasLength(attempt < 2 ? 1 : 0),
          reason: 'attempt $attempt must not duplicate or lose the operation',
        );
        advancePastBackoff();
      }

      expect(api.countOf('PUT', '/calculation-snapshots'), 3);
      for (var i = 0; i < 3; i++) {
        expect(api.headerOf(i, 'Idempotency-Key'), key, reason: 'attempt $i');
      }
    });
  });

  group('a duplicate replay completes the operation', () {
    test('the replay answer removes the row and does not re-enqueue', () async {
      // The server already completed this write during an earlier attempt whose
      // response was lost. It answers the replay with the stored response and
      // `X-Idempotent-Replay: true`; the client must treat that as done.
      final api = FakeApi(<String, FakeRoute>{})
        ..on('PUT', '/calculation-snapshots', FakeRoute(
          200,
          <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{'synced': 1},
            'message': 'replayed',
          },
          headers: const <String, String>{'X-Idempotent-Replay': 'true'},
        ));

      await queue.enqueueSnapshot(
        domain: 'civil',
        inputs: const <String, dynamic>{'a': 1},
        result: const <String, dynamic>{'b': 2},
      );
      final key = (await rows()).single.idempotencyKey!;

      final manager = managerFor(api);
      await manager.syncNow();

      expect(api.headerOf(0, 'Idempotency-Key'), key);
      expect(await rows(), isEmpty);

      // A drained queue must stay drained: the next tick sends nothing.
      advancePastBackoff();
      await manager.syncNow();
      expect(api.requests, hasLength(1));
      expect(await rows(), isEmpty);
    });

    test('a 409 payload conflict stops retrying with a fresh key', () async {
      // Sending the same key with a different body is a client bug, not a
      // transient failure. The important half of the guarantee is that the
      // client does not "fix" it by minting a new key — that would turn a
      // refused write into a successful duplicate.
      final api = FakeApi(<String, FakeRoute>{})
        ..on(
          'PUT',
          '/calculation-snapshots',
          FakeRoute.error(409, 'IDEMPOTENCY_CONFLICT', 'Payload mismatch.'),
        );

      await queue.enqueueSnapshot(
        domain: 'civil',
        inputs: const <String, dynamic>{'a': 1},
        result: const <String, dynamic>{'b': 2},
      );
      final key = (await rows()).single.idempotencyKey!;
      final manager = managerFor(api);

      await manager.syncNow();
      advancePastBackoff();
      await manager.syncNow();

      expect(api.headerOf(0, 'Idempotency-Key'), key);
      expect(api.headerOf(1, 'Idempotency-Key'), key);
      expect((await rows()).single.idempotencyKey, key);
    });
  });
}

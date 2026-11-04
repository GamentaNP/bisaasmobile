/// P5-32 — idempotent replay of the offline queue.
///
/// The queue has three ways to duplicate a write, and only one of them was
/// tested before this file:
///
///  1. two `enqueue()` calls for the same logical operation must collapse to
///     one row (the unique `idempotency_key` is the mechanism);
///  2. a failed attempt must keep its key, so the retry is the same operation
///     to the server rather than a new one;
///  3. nothing in the retry path may mint a replacement key.
///
/// (1) had a unit test. (2) and (3) were assumptions. `SyncManager` reads the
/// key off the row on every attempt, so the invariant holds today — but it is
/// one `??= _uuid.v4()` in `bump()` away from not holding, and the failure is
/// invisible until a user is double-charged or double-credited.
///
/// The drain itself is proven through the HTTP stack in
/// `test/integration/offline_sync_idempotency_integration_test.dart`.
library;

import 'package:bisaasmobile/core/storage/database/app_database.dart';
import 'package:bisaasmobile/core/storage/database/daos/sync_queue_dao.dart';
import 'package:bisaasmobile/core/sync/sync_queue.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SyncQueueService queue;
  late DateTime clock;

  setUp(() {
    clock = DateTime.utc(2026, 11, 4, 12);
    db = AppDatabase(NativeDatabase.memory());
    queue = SyncQueueService(
      SyncQueueDao(db, now: () => clock),
      now: () => clock,
    );
  });

  tearDown(() async => db.close());

  Future<List<SyncQueueData>> rows() => db.select(db.syncQueue).get();

  group('one logical operation, one row', () {
    test('the same key enqueued twice leaves exactly one row', () async {
      const key = '0f8fad5b-d9cb-469f-a165-70867728950e';
      const body = '{"snapshots":[{"domain":"civil"}]}';

      final first = await queue.enqueue(
        endpoint: '/calculation-snapshots',
        method: 'PUT',
        payload: body,
        idempotencyKey: key,
      );
      final second = await queue.enqueue(
        endpoint: '/calculation-snapshots',
        method: 'PUT',
        payload: body,
        idempotencyKey: key,
      );

      expect(second, first, reason: 'the retry must resolve to the queued row');
      final all = await rows();
      expect(all, hasLength(1));
      expect(all.single.idempotencyKey, key);
    });

    test('a user re-tapping save does not throw on the unique index', () async {
      // The realistic offline retry: the user taps "save" again because the
      // first tap appeared to do nothing. Before `insertOrIgnore` this was an
      // unhandled SqliteException, not a dedupe.
      const key = 'retry-after-visible-no-op';
      await queue.enqueue(endpoint: '/calculation-snapshots', idempotencyKey: key);

      await expectLater(
        queue.enqueue(endpoint: '/calculation-snapshots', idempotencyKey: key),
        completes,
      );
      expect(await rows(), hasLength(1));
    });

    test('an offline match receipt uses the manifest id as its key', () async {
      await queue.enqueueOfflineMatchReceipt(
        manifestId: 'manifest-42',
        payload: const <String, dynamic>{'score': 3},
      );
      await queue.enqueueOfflineMatchReceipt(
        manifestId: 'manifest-42',
        payload: const <String, dynamic>{'score': 3},
      );

      final all = await rows();
      expect(all, hasLength(1));
      expect(all.single.idempotencyKey, 'manifest-42');
    });

    test('two distinct operations get two distinct keys', () async {
      await queue.enqueue(endpoint: '/a');
      await queue.enqueue(endpoint: '/b');

      final keys = (await rows()).map((r) => r.idempotencyKey).toList();
      expect(keys, hasLength(2));
      expect(keys.toSet(), hasLength(2));
    });
  });

  group('a retry never becomes a new operation', () {
    test('backoff preserves the key, the payload and the row identity', () async {
      const key = 'stable-across-retries';
      const body = '{"snapshots":[{"domain":"civil","input_payload":{"a":1}}]}';

      await queue.enqueue(
        endpoint: '/calculation-snapshots',
        method: 'PUT',
        payload: body,
        idempotencyKey: key,
      );
      final before = (await rows()).single;

      await queue.bump(before.id, before.attempts);

      final after = (await rows()).single;
      expect(after.id, before.id, reason: 'a retry continues the same row');
      expect(after.idempotencyKey, key, reason: 'the key is the operation identity');
      expect(after.payload, body);
      expect(after.endpoint, before.endpoint);
      expect(after.method, before.method);
      expect(after.attempts, before.attempts + 1);
    });

    test('the row is not due again until the backoff window has passed', () async {
      await queue.enqueue(endpoint: '/a', idempotencyKey: 'k');
      final row = (await rows()).single;

      await queue.bump(row.id, row.attempts);
      expect(
        await queue.pending(),
        isEmpty,
        reason: 'a dead endpoint must not spin on every sync tick',
      );

      // 30 s for attempt 0 → 60 s for attempt 1. Advancing the injectable
      // clock is what makes this a test rather than a sleep.
      clock = clock.add(const Duration(seconds: 31));
      expect((await queue.pending()).single.id, row.id);
    });

    test('bumping never rewrites the key, even repeatedly', () async {
      await queue.enqueue(endpoint: '/a', idempotencyKey: 'never-rotate');
      var row = (await rows()).single;

      for (var attempt = 0; attempt < 3; attempt++) {
        await queue.bump(row.id, row.attempts);
        clock = clock.add(const Duration(minutes: 5));
        row = (await rows()).single;
        expect(row.idempotencyKey, 'never-rotate');
      }

      expect(row.attempts, 3);
    });
  });
}

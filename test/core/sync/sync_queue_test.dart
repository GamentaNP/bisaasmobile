import 'dart:convert';

import 'package:bisaasmobile/core/storage/database/app_database.dart';
import 'package:bisaasmobile/core/storage/database/daos/sync_queue_dao.dart';
import 'package:bisaasmobile/core/sync/sync_queue.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// `SyncQueueService.enqueue` has no production caller — the calculator-snapshot
/// path that fed it was unwired without the method being removed, and
/// `unwired_tables_test.dart` fails if something starts calling it again.
///
/// That makes this file the *only* coverage the queue will get until someone
/// makes a product decision about which writes are worth queueing. So it tests
/// the two ways the machinery would fail the moment it was switched on, both of
/// which are invisible until then.
void main() {
  late AppDatabase db;
  late SyncQueueService queue;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = SyncQueueService(SyncQueueDao(db));
  });

  tearDown(() async => db.close());

  group('endpoint validation', () {
    test('accepts a relative path under the API base', () {
      for (final endpoint in const [
        '/calculation-snapshots',
        '/quiz/attempts',
        '/economy/snapshots/1',
      ]) {
        expect(
          SyncQueueService.validateEndpoint(endpoint),
          isNull,
          reason: '$endpoint should be allowed',
        );
      }
    });

    test('refuses an absolute URL, which would carry the bearer token away', () {
      // Dio replaces `baseUrl` with an absolute path, and `AuthInterceptor`
      // attaches the user's token to every request. The queue is a table, not a
      // trust boundary.
      expect(
        SyncQueueService.validateEndpoint('https://attacker.example/collect'),
        'an absolute URL',
      );
      expect(
        SyncQueueService.validateEndpoint('http://attacker.example/collect'),
        'an absolute URL',
      );
    });

    test('refuses a protocol-relative URL', () {
      // `//evil.example/x` is host-relative to a browser, and several URL
      // resolvers read the authority out of it.
      expect(
        SyncQueueService.validateEndpoint('//attacker.example/collect'),
        'a protocol-relative URL',
      );
    });

    test('refuses a scheme without the usual slashes', () {
      expect(SyncQueueService.validateEndpoint('mailto:a@b.example'), isNotNull);
      expect(SyncQueueService.validateEndpoint('file:///etc/passwd'), isNotNull);
      expect(SyncQueueService.validateEndpoint('javascript:alert(1)'), isNotNull);
    });

    test('refuses an unrooted or traversing path', () {
      expect(
        SyncQueueService.validateEndpoint('calculation-snapshots'),
        'a path that is not rooted',
      );
      expect(
        SyncQueueService.validateEndpoint('/../admin/users'),
        'a path containing traversal',
      );
    });

    test('refuses empty and whitespace-padded input', () {
      expect(SyncQueueService.validateEndpoint(''), 'an empty endpoint');
      expect(
        SyncQueueService.validateEndpoint('/quiz/attempts '),
        'a path with surrounding whitespace',
      );
    });

    test('enqueue refuses rather than storing an unsafe row', () async {
      expect(
        () => queue.enqueue(endpoint: 'https://attacker.example/collect'),
        throwsA(isA<ArgumentError>()),
      );
      expect(await db.select(db.syncQueue).get(), isEmpty);
    });
  });

  group('snapshot body', () {
    test('matches the shape CalculationSnapshotController::sync validates', () async {
      // The server requires a `snapshots` collection where `domain` is a string
      // and `input_payload` / `result_payload` are both arrays. The previous
      // flat `{domain, slug, inputs, outputs}` body would have 422'd, retried
      // and given up, looking exactly like a network outage.
      await queue.enqueueSnapshot(
        domain: 'civil',
        calculatorSlug: 'bmr',
        inputs: const {'weight_kg': 70},
        result: const {'bmi': 24.5},
      );

      final row = (await db.select(db.syncQueue).get()).single;
      expect(row.endpoint, '/calculation-snapshots');
      expect(row.method, 'PUT');

      final body = jsonDecode(row.payload!) as Map<String, dynamic>;
      final snapshots = body['snapshots'] as List<dynamic>;
      expect(snapshots, hasLength(1));

      final snapshot = snapshots.single as Map<String, dynamic>;
      expect(snapshot['domain'], 'civil');
      expect(snapshot['calculator_slug'], 'bmr');
      expect(snapshot['input_payload'], {'weight_kg': 70});
      expect(snapshot['result_payload'], {'bmi': 24.5});
      expect(snapshot.containsKey('client_uuid'), isFalse);
      expect(snapshot.containsKey('is_favorite'), isFalse);
    });

    test('round-trips nested and unicode payloads', () async {
      await queue.enqueueSnapshot(
        domain: 'civil',
        calculatorSlug: 'concrete',
        inputs: const {
          'title': '??????',
          'nested': {
            'list': [1, 2, true],
            'null_field': null,
          },
        },
        result: const {'volume': 12.5},
      );

      final row = (await db.select(db.syncQueue).get()).single;
      final body = jsonDecode(row.payload!) as Map<String, dynamic>;
      final snapshot =
          (body['snapshots'] as List<dynamic>).single as Map<String, dynamic>;
      expect(snapshot['input_payload'], {
        'title': '??????',
        'nested': {
          'list': [1, 2, true],
          'null_field': null,
        },
      });
    });

    test('omits client_uuid rather than sending a malformed one', () async {
      // The server validates it as a uuid and rejects the whole batch over one
      // bad value, so a non-UUID must be dropped rather than forwarded.
      await queue.enqueueSnapshot(
        domain: 'civil',
        calculatorSlug: 'bmr',
        inputs: const {'a': 1},
        result: const {'b': 2},
        clientUuid: 'not-a-uuid',
      );

      final row = (await db.select(db.syncQueue).get()).single;
      final body = jsonDecode(row.payload!) as Map<String, dynamic>;
      final snapshot =
          (body['snapshots'] as List<dynamic>).single as Map<String, dynamic>;
      expect(snapshot.containsKey('client_uuid'), isFalse);
    });

    test('sends client_uuid when it really is a UUID', () async {
      await queue.enqueueSnapshot(
        domain: 'civil',
        calculatorSlug: 'bmr',
        inputs: const {'a': 1},
        result: const {'b': 2},
        clientUuid: '0f8fad5b-d9cb-469f-a165-70867728950e',
      );

      final row = (await db.select(db.syncQueue).get()).single;
      final body = jsonDecode(row.payload!) as Map<String, dynamic>;
      final snapshot =
          (body['snapshots'] as List<dynamic>).single as Map<String, dynamic>;
      expect(snapshot['client_uuid'], '0f8fad5b-d9cb-469f-a165-70867728950e');
    });

    test('omits last_opened_at, so a skewed clock cannot lose the batch', () async {
      // The server validates it `before_or_equal:now` and rejects the WHOLE
      // collection over one bad row. A phone whose clock is minutes ahead would
      // therefore lose the user's inputs and results to protect a field that is
      // nullable and only used for display ordering.
      //
      // Verified against the live endpoint: a body carrying last_opened_at was
      // rejected with "must be a date before or equal to now"; the same body
      // without it validates.
      await queue.enqueueSnapshot(
        domain: 'civil',
        inputs: const {'a': 1},
        result: const {'b': 2},
      );

      final row = (await db.select(db.syncQueue).get()).single;
      final body = jsonDecode(row.payload!) as Map<String, dynamic>;
      final snapshot =
          (body['snapshots'] as List<dynamic>).single as Map<String, dynamic>;
      expect(snapshot.containsKey('last_opened_at'), isFalse);
    });
  });

  group('queue mechanics', () {
    test('mints a fresh idempotency key per enqueue', () async {
      await queue.enqueue(endpoint: '/a');
      await queue.enqueue(endpoint: '/b');

      final keys = (await db.select(db.syncQueue).get())
          .map((r) => r.idempotencyKey)
          .toSet();
      expect(keys, hasLength(2), reason: 'two distinct operations need two keys');
    });

    test('reuses a caller-supplied key so a retry dedupes', () async {
      const key = 'same-logical-operation';
      await queue.enqueue(endpoint: '/a', idempotencyKey: key);
      await queue.enqueue(endpoint: '/a', idempotencyKey: key);

      final rows = await db.select(db.syncQueue).get();
      expect(rows, hasLength(1), reason: 'the unique key must collapse the retry');
    });

    test('normalises the method', () async {
      await queue.enqueue(endpoint: '/a', method: 'put');
      expect((await db.select(db.syncQueue).get()).single.method, 'PUT');
    });
  });
}

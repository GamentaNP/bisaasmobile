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
    test('is JSON, not Dart map syntax', () async {
      // `snapshot.toString()` produced `{domain: Civil, inputs: {}}` — unquoted
      // keys, which is not JSON. The API would 422 it, `bump` would retry five
      // times and give up, and the result would be indistinguishable from the
      // network being down.
      final snapshot = <String, dynamic>{
        'domain': 'civil',
        'slug': 'bmr',
        'inputs': {'weight_kg': 70},
        'outputs': {'bmi': 24.5},
        'calculated_at': '2026-09-30T00:00:00+05:45',
      };

      await queue.enqueueSnapshot(snapshot);

      final row = (await db.select(db.syncQueue).get()).single;
      expect(row.endpoint, '/calculation-snapshots');
      expect(row.method, 'PUT');
      expect(jsonDecode(row.payload!), snapshot);
    });

    test('round-trips nested and unicode payloads', () async {
      final snapshot = <String, dynamic>{
        'title': 'भारतको इतिहास',
        'nested': {
          'list': [1, 2, {'deep': true}],
          'null_field': null,
        },
      };

      await queue.enqueueSnapshot(snapshot);

      final row = (await db.select(db.syncQueue).get()).single;
      expect(jsonDecode(row.payload!), snapshot);
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

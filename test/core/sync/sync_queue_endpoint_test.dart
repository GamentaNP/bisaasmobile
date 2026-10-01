import 'package:bisaasmobile/core/storage/database/app_database.dart';
import 'package:bisaasmobile/core/storage/database/daos/sync_queue_dao.dart';
import 'package:bisaasmobile/core/sync/sync_queue.dart';
import 'package:drift/drift.dart' show Value;
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncQueueDao extends Mock implements SyncQueueDao {}

/// Regression: the calculation-snapshot drain was posting to
/// `/v1/calculation-snapshots/sync`. `ApiConfig.baseUrl` already ends in
/// `/api/v1`, so every attempt went to `/api/v1/v1/calculation-snapshots/sync`
/// and returned 404 — offline snapshots were never synced and the queue backed
/// off forever.
///
/// Verified against the running backend:
///   POST /api/v1/v1/calculation-snapshots/sync -> 404  (no such route)
///   POST /api/v1/calculation-snapshots/sync     -> 401  (route resolves)
///   PUT  /api/v1/calculation-snapshots          -> 401  (canonical, `sync.update`)
void main() {
  late MockSyncQueueDao dao;
  late SyncQueueService queue;

  setUpAll(() {
    registerFallbackValue(
      const SyncQueueCompanion(endpoint: Value('')),
    );
  });

  setUp(() {
    dao = MockSyncQueueDao();
    when(() => dao.enqueue(any())).thenAnswer((_) async => 1);
    queue = SyncQueueService(dao);
  });

  Future<SyncQueueCompanion> enqueueSnapshot() async {
    await queue.enqueueSnapshot(
      domain: 'civil',
      calculatorSlug: 'beam-shear',
      inputs: const <String, dynamic>{'b': 200},
      result: const <String, dynamic>{'v': 12},
    );
    return verify(() => dao.enqueue(captureAny())).captured.single
        as SyncQueueCompanion;
  }

  test('path is /api/v1-relative — never a second /v1', () async {
    final row = await enqueueSnapshot();
    expect(row.endpoint.value, '/calculation-snapshots');
    // The old value was '/v1/calculation-snapshots/sync'.
    expect(row.endpoint.value, isNot(startsWith('/v1/')));
    expect(row.endpoint.value, isNot(contains('/sync')));
  });

  test('uses PUT, the canonical collection verb', () async {
    final row = await enqueueSnapshot();
    expect(row.method.value, 'PUT');
  });

  test('carries an idempotency key so a retry cannot duplicate', () async {
    final row = await enqueueSnapshot();
    expect(row.idempotencyKey.value, isNotNull);
    expect(row.idempotencyKey.value, isNotEmpty);
  });

  test('the payload carries what the server validates', () async {
    final row = await enqueueSnapshot();
    final body =
        jsonDecode(row.payload.value!) as Map<String, dynamic>;
    final snapshot =
        (body['snapshots'] as List<dynamic>).single as Map<String, dynamic>;
    expect(snapshot['calculator_slug'], 'beam-shear');
    expect(snapshot['input_payload'], {'b': 200});
    expect(snapshot['result_payload'], {'v': 12});
  });
}

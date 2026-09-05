import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../storage/database/app_database.dart';
import '../storage/database/daos/sync_queue_dao.dart';

class SyncQueueService {
  SyncQueueService(this._dao, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();
  final SyncQueueDao _dao;
  final Uuid _uuid;

  /// Enqueues one offline operation.
  ///
  /// [idempotencyKey] is optional: when the *same logical operation* is
  /// retried (e.g. a user re-taps "save"), pass the same key so the unique
  /// constraint on `sync_queue.idempotency_key` dedupes and the server can
  /// dedupe across retries. When omitted, a fresh key is minted per enqueue
  /// (best-effort for fire-once callers).
  Future<int> enqueue({
    required String endpoint,
    String method = 'POST',
    String? payload,
    String? idempotencyKey,
  }) {
    return _dao.enqueue(
      SyncQueueCompanion(
        endpoint: Value(endpoint),
        method: Value(method),
        payload: Value(payload),
        idempotencyKey: Value(idempotencyKey ?? _uuid.v4()),
      ),
    );
  }

  /// Offline calculation snapshot — synced to `POST /v1/calculation-snapshots/sync` on reconnect.
  /// Payload is JSON-encoded `{domain, slug, inputs, outputs, calculated_at}`.
  Future<int> enqueueSnapshot(Map<String, dynamic> snapshot) => enqueue(
        endpoint: '/v1/calculation-snapshots/sync',
        payload: snapshot.toString(),
      );

  Future<List<SyncQueueData>> pending() => _dao.pending();
  Future<void> remove(int id) async => _dao.remove(id);

  /// Backoff after a failed attempt — linear-ish, capped under the retry limit.
  Future<void> bump(int id, int attempts) =>
      _dao.bump(id, DateTime.now().add(Duration(seconds: 30 * (attempts + 1))));
}

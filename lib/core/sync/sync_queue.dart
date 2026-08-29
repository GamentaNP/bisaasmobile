import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../storage/database/app_database.dart';
import '../storage/database/daos/sync_queue_dao.dart';

class SyncQueueService {
  SyncQueueService(this._dao, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();
  final SyncQueueDao _dao;
  final Uuid _uuid;

  Future<int> enqueue({
    required String endpoint,
    String method = 'POST',
    String? payload,
  }) {
    return _dao.enqueue(
      SyncQueueCompanion(
        endpoint: Value(endpoint),
        method: Value(method),
        payload: Value(payload),
        idempotencyKey: Value(_uuid.v4()),
      ),
    );
  }

  Future<List<SyncQueueData>> pending() => _dao.pending();
  Future<void> remove(int id) => _dao.remove(id);
}

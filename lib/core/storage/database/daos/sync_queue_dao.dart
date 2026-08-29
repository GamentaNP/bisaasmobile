import 'package:drift/drift.dart';

import '../app_database.dart';

class SyncQueueDao {
  SyncQueueDao(this.db);
  final AppDatabase db;

  Future<List<SyncQueueData>> pending() =>
      (db.select(db.syncQueue)..where((t) => t.attempts.isSmallerThanValue(5))).get();

  Future<int> enqueue(SyncQueueCompanion c) => db.into(db.syncQueue).insert(c);

  Future<int> remove(int id) =>
      (db.delete(db.syncQueue)..where((t) => t.id.equals(id))).go();

  Future<int> bump(int id, DateTime next) => (db.update(db.syncQueue)
        ..where((t) => t.id.equals(id)))
      .write(SyncQueueCompanion(attempts: const Value(1), nextAttemptAt: Value(next)));
}

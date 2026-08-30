import 'package:drift/drift.dart';

import '../app_database.dart';

class SyncQueueDao {
  SyncQueueDao(this.db);
  final AppDatabase db;

  /// Items worth attempting now: under the retry cap and past their backoff.
  Future<List<SyncQueueData>> pending() {
    final now = DateTime.now();
    return (db.select(db.syncQueue)
          ..where(
            (t) =>
                t.attempts.isSmallerThanValue(5) &
                (t.nextAttemptAt.isNull() |
                    t.nextAttemptAt.isSmallerOrEqualValue(now)),
          ))
        .get();
  }

  Future<int> enqueue(SyncQueueCompanion c) => db.into(db.syncQueue).insert(c);

  Future<int> remove(int id) =>
      (db.delete(db.syncQueue)..where((t) => t.id.equals(id))).go();

  /// Records a failed attempt by incrementing the counter (never resetting it)
  /// and schedules the next attempt after [next].
  Future<void> bump(int id, DateTime next) => db.customUpdate(
        'UPDATE sync_queue SET attempts = attempts + 1, next_attempt_at = ? WHERE id = ?',
        variables: [Variable(next), Variable(id)],
      );
}

import 'package:drift/drift.dart';

import '../app_database.dart';

class SyncQueueDao {
  SyncQueueDao(this.db);
  final AppDatabase db;

  /// Items worth attempting now: under the retry cap and past their backoff.
  /// Ordered oldest-first so dependent operations flush in enqueue order.
  Future<List<SyncQueueData>> pending() {
    final now = DateTime.now();
    return (db.select(db.syncQueue)
          ..where(
            (t) =>
                t.attempts.isSmallerThanValue(5) &
                (t.nextAttemptAt.isNull() |
                    t.nextAttemptAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt), (t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  /// Stores [c], collapsing a retry onto the row that is already queued.
  ///
  /// Returns the id of the row that now represents this operation — the newly
  /// inserted one, or the pre-existing one when the `idempotency_key` matched.
  ///
  /// This was a plain `insert()`, and the unique constraint on
  /// `idempotency_key` did not dedupe as `SyncQueueService.enqueue` claimed: it
  /// *threw*. So the documented behaviour — "pass the same key so a retry
  /// dedupes" — was an unhandled `SqliteException` instead. The realistic path
  /// is a user re-tapping "save" while offline, which is precisely the case the
  /// idempotency key exists for.
  ///
  /// `insertOrIgnore` then a re-read, rather than a select-then-insert, so two
  /// concurrent enqueues of the same key cannot both decide the row is missing.
  Future<int> enqueue(SyncQueueCompanion c) async {
    await db
        .into(db.syncQueue)
        .insert(c, mode: InsertMode.insertOrIgnore);

    final key = c.idempotencyKey.value;
    if (key == null) {
      // No key to resolve, so the newest row is the one just written.
      final rows = await (db.select(db.syncQueue)
            ..orderBy([(t) => OrderingTerm.desc(t.id)]))
          .get();
      return rows.isEmpty ? 0 : rows.first.id;
    }

    final row = await (db.select(db.syncQueue)
          ..where((t) => t.idempotencyKey.equals(key)))
        .getSingleOrNull();

    return row?.id ?? 0;
  }

  Future<int> remove(int id) =>
      (db.delete(db.syncQueue)..where((t) => t.id.equals(id))).go();

  /// Records a failed attempt by incrementing the counter (never resetting it)
  /// and schedules the next attempt after [next].
  Future<void> bump(int id, DateTime next) => db.customUpdate(
        'UPDATE sync_queue SET attempts = attempts + 1, next_attempt_at = ? WHERE id = ?',
        variables: [Variable(next), Variable(id)],
      );
}

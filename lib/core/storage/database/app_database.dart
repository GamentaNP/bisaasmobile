library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/attempts_table.dart';
import 'tables/calculations_table.dart';
import 'tables/courses_table.dart';
import 'tables/downloads_table.dart';
import 'tables/questions_table.dart';
import 'tables/quiz_attempts_table.dart';
import 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Questions, Attempts, Courses, Calculations, SyncQueue, QuizAttempts, Downloads])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'bisaas_app'));

  static AppDatabase? _instance;

  /// Process-wide database — warmed by bootstrap() so the first screen never
  /// blocks on schema creation.
  factory AppDatabase.instance() => _instance ??= AppDatabase();

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2 new tables (per-attempt header, offline packs).
            await m.createTable(quizAttempts);
            await m.createTable(downloads);

            // Questions changed shape entirely (v1: id PK + title/body;
            // v2: remote_id PK + options JSON). It is a disposable cache —
            // drop and recreate rather than attempt a column-by-column copy.
            await customStatement('DROP TABLE IF EXISTS questions');
            await m.createTable(questions);

            // SyncQueue.idempotency_key gains uniqueness — SQLite cannot
            // ALTER ADD a UNIQUE constraint, so create the index explicitly
            // (nullable column: multiple NULLs are legal in a unique index).
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS sync_queue_idempotency_key_uq '
              'ON sync_queue (idempotency_key)',
            );
          }

          if (from < 3) {
            // v3 (security plan W2.2): the plaintext response-body cache is
            // gone. It stored full GET payloads (courses, calculators) on
            // disk unencrypted, and nothing ever read it back — HTTP ETag
            // replay via ApiCacheHeaders is the only cache. Devices that
            // created it under v2 drop it here; fresh installs never had it.
            await customStatement('DROP TABLE IF EXISTS cached_responses');
          }
        },
      );
}

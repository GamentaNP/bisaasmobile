import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:bisaasmobile/core/storage/database/app_database.dart';

/// End-to-end v1→v3 migration test.
///
/// Builds the REAL v1 database by hand (the shape devices running the first
/// release carry), sets user_version=1, then opens it through drift so the
/// production MigrationStrategy.onUpgrade runs — not a reimplementation.
void main() {
  test('v1 → v3: questions rebuilt, new tables created, sync_queue unique index enforced', () async {
    final raw = sqlite3.openInMemory();
    raw.execute('PRAGMA foreign_keys = OFF');

    // ── v1 schema (as shipped in schemaVersion 1) ──────────────────────────
    raw.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NULL,
        difficulty INTEGER NOT NULL DEFAULT 0,
        cached_at INTEGER NULL
      )''');
    raw.execute("INSERT INTO questions (title, body, difficulty) VALUES ('legacy', 'old shape', 1)");
    raw.execute('''
      CREATE TABLE attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        selected_option INTEGER NULL,
        is_correct INTEGER NULL,
        answered_at INTEGER NOT NULL DEFAULT 0
      )''');
    raw.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        slug TEXT NOT NULL UNIQUE,
        payload TEXT NULL,
        cached_at INTEGER NULL
      )''');
    raw.execute('''
      CREATE TABLE calculations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        calculator_id TEXT NOT NULL,
        inputs TEXT NOT NULL,
        result TEXT NULL,
        created_at INTEGER NOT NULL DEFAULT 0
      )''');
    raw.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL DEFAULT 'POST',
        payload TEXT NULL,
        idempotency_key TEXT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL DEFAULT 0,
        next_attempt_at INTEGER NULL
      )''');
    raw.execute("INSERT INTO sync_queue (endpoint, idempotency_key) VALUES ('/legacy', 'k-1')");
    raw.execute('PRAGMA user_version = 1');

    // ── Open through drift: user_version 1 < schemaVersion 3 → onUpgrade ───
    final db = AppDatabase(NativeDatabase.opened(raw));
    // Touch the database to force initialization.
    await db.customSelect('SELECT 1').getSingle();

    // Legacy cache rows are gone; the table now has the v2 shape.
    final names = (await db.customSelect('PRAGMA table_info(questions)').get())
        .map((r) => r.data['name'])
        .toSet();
    expect(names, containsAll(['remote_id', 'quiz_id', 'options_json', 'correct_option_id']));
    expect(names, isNot(contains('title')));

    // v2 tables exist.
    for (final t in ['quiz_attempts', 'downloads']) {
      final cols = await db.customSelect('PRAGMA table_info($t)').get();
      expect(cols, isNotEmpty, reason: '$t should exist after v1→v2');
    }

    // Unique index created for upgraded installs, and it actually enforces.
    final idx = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='index' "
          "AND name='sync_queue_idempotency_key_uq'",
        )
        .getSingle();
    expect(idx.data['name'], 'sync_queue_idempotency_key_uq');
    expect(
      () => raw.execute("INSERT INTO sync_queue (endpoint, idempotency_key) VALUES ('/dup', 'k-1')"),
      throwsA(anything),
      reason: 'duplicate idempotency_key must be rejected on upgraded installs',
    );
    // NULL keys are still allowed multiple times (unique index semantics).
    raw.execute("INSERT INTO sync_queue (endpoint) VALUES ('/n1')");
    raw.execute("INSERT INTO sync_queue (endpoint) VALUES ('/n2')");

    // Fresh-install path also enforces uniqueness via the table definition.
    final fresh = AppDatabase(NativeDatabase.memory());
    await fresh.into(fresh.syncQueue).insert(SyncQueueCompanion.insert(endpoint: '/a', idempotencyKey: Value('x-1')));
    await fresh.into(fresh.syncQueue).insert(SyncQueueCompanion.insert(endpoint: '/b', idempotencyKey: Value('x-2')));
    expect(
      () => fresh.into(fresh.syncQueue).insert(SyncQueueCompanion.insert(endpoint: '/c', idempotencyKey: Value('x-1'))),
      throwsA(anything),
    );
    await fresh.close();
    await db.close();
  });

  test('v2 → v3: plaintext cached_responses table is dropped (security plan W2.2)', () async {
    final raw = sqlite3.openInMemory();
    raw.execute('PRAGMA foreign_keys = OFF');

    // ── v2 shape: everything v2 created, including the ETag body cache that
    // stored full GET payloads on disk unencrypted and was never read back.
    raw.execute('''
      CREATE TABLE questions (
        remote_id TEXT NOT NULL PRIMARY KEY,
        quiz_id TEXT NULL,
        options_json TEXT NOT NULL,
        correct_option_id INTEGER NULL,
        cached_at INTEGER NULL
      )''');
    raw.execute('''
      CREATE TABLE quiz_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_attempt_id TEXT NULL,
        payload TEXT NULL,
        created_at INTEGER NOT NULL DEFAULT 0
      )''');
    raw.execute('''
      CREATE TABLE downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at INTEGER NOT NULL DEFAULT 0
      )''');
    raw.execute('''
      CREATE TABLE cached_responses (
        cache_key TEXT NOT NULL PRIMARY KEY,
        etag TEXT NULL,
        body TEXT NOT NULL,
        url TEXT NULL,
        cached_at INTEGER NOT NULL DEFAULT 0,
        expires_at INTEGER NULL
      )''');
    raw.execute("INSERT INTO cached_responses (cache_key, body) VALUES ('https://bisaas.test/api/v1/quiz/courses', '{\"data\":{\"items\":[{\"title\":\"leak me\"}]}}')");
    raw.execute('''
      CREATE TABLE attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        selected_option INTEGER NULL,
        is_correct INTEGER NULL,
        answered_at INTEGER NOT NULL DEFAULT 0
      )''');
    raw.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        slug TEXT NOT NULL UNIQUE,
        payload TEXT NULL,
        cached_at INTEGER NULL
      )''');
    raw.execute('''
      CREATE TABLE calculations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        calculator_id TEXT NOT NULL,
        inputs TEXT NOT NULL,
        result TEXT NULL,
        created_at INTEGER NOT NULL DEFAULT 0
      )''');
    raw.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL DEFAULT 'POST',
        payload TEXT NULL,
        idempotency_key TEXT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL DEFAULT 0,
        next_attempt_at INTEGER NULL
      )''');
    raw.execute('PRAGMA user_version = 2');

    final db = AppDatabase(NativeDatabase.opened(raw));
    await db.customSelect('SELECT 1').getSingle();

    // The v2→v3 upgrade dropped the plaintext body cache.
    final table = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='cached_responses'",
        )
        .get();
    expect(table, isEmpty, reason: 'cached_responses must be gone after v2→v3');

    // The database still opens and serves normally afterwards.
    await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(endpoint: '/ok', idempotencyKey: Value('v3-1')));
    final rows = await db.select(db.syncQueue).get();
    expect(rows, hasLength(1));

    await db.close();
  });

  test('v3 fresh install: cached_responses never exists', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').getSingle();

    final table = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='cached_responses'",
        )
        .get();
    expect(table, isEmpty);

    expect(db.schemaVersion, 3);
    await db.close();
  });
}

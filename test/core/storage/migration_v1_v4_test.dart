import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:bisaasmobile/core/storage/database/app_database.dart';

/// End-to-end v1→v4 migration test.
///
/// Builds the REAL v1 database by hand (the shape devices running the first
/// release carry), sets user_version=1, then opens it through drift so the
/// production MigrationStrategy.onUpgrade runs — not a reimplementation.
///
/// Covers v1→v4, including the v3 security decision to drop the plaintext
/// response cache and the v4 decision to restore it under a stricter shape.
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

    // The v2→v3 upgrade dropped the plaintext body cache, and v4 recreated it
    // under a stricter shape. What matters here is that the *legacy* rows did
    // not survive: a v2 device's unencrypted bodies must be gone, not carried
    // forward into the new table. The schema difference is asserted by the
    // dedicated v3→v4 test below.
    final legacy = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name='cached_responses'",
        )
        .get();
    expect(legacy, hasLength(1), reason: 'v4 recreates the table');

    final carried = await db.select(db.cachedResponses).get();
    expect(
      carried,
      isEmpty,
      reason: "a v2 device's cached bodies must not survive the migration",
    );

    final columns = await db
        .customSelect('PRAGMA table_info(cached_responses)')
        .get();
    final names = columns.map((r) => r.read<String>('name')).toSet();
    expect(
      names,
      containsAll(['cache_key', 'body', 'etag', 'cached_at', 'expires_at',
        'byte_size', 'schema_version']),
      reason: 'the v4 table must carry the bounded, versioned shape',
    );
    expect(
      names,
      isNot(contains('id')),
      reason: 'cache_key is the primary key; there is no surrogate id',
    );

    // The database still opens and serves normally afterwards.
    await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(endpoint: '/ok', idempotencyKey: Value('v3-1')));
    final rows = await db.select(db.syncQueue).get();
    expect(rows, hasLength(1));

    await db.close();
  });

  test('v3 → v4: the response cache comes back, and is empty', () async {
    // v3 removed the plaintext body cache and named a replacement that never
    // arrived: "HTTP ETag replay via ApiCacheHeaders is the only cache" is a
    // server-side Laravel trait no client code references, and the server
    // answers a matching If-None-Match with 200 rather than 304. So v3 shipped
    // with no cache at all.
    //
    // v4 restores it with the property that justified the removal (public
    // payloads only, bounded size) and, unlike v2, something that reads it
    // back. The table must start empty: entries are written by the cache, not
    // by the migration.
    final raw = sqlite3.openInMemory();
    raw.execute('PRAGMA foreign_keys = OFF');
    // A v3 device: the v1/v2 tables exist and cached_responses does not, because
    // the v3 migration dropped it.
    raw.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT NOT NULL,
        quiz_id TEXT NULL,
        subject_slug TEXT NOT NULL DEFAULT '',
        body TEXT NOT NULL,
        options_json TEXT NOT NULL,
        correct_option_id TEXT NULL,
        explanation TEXT NULL,
        difficulty INTEGER NOT NULL DEFAULT 1,
        marks_positive INTEGER NOT NULL DEFAULT 4,
        marks_negative INTEGER NOT NULL DEFAULT 0,
        cached_at INTEGER NULL
      )''');
    raw.execute('''
      CREATE TABLE attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_attempt_id TEXT NULL,
        question_id TEXT NOT NULL,
        selected_option_id TEXT NULL,
        is_correct INTEGER NULL,
        xp_earned INTEGER NOT NULL DEFAULT 0,
        coins_earned INTEGER NOT NULL DEFAULT 0,
        sync_status INTEGER NOT NULL DEFAULT 0,
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
    raw.execute('''
      CREATE TABLE quiz_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_attempt_id TEXT NULL,
        quiz_id TEXT NOT NULL,
        question_ids_json TEXT NOT NULL,
        started_at INTEGER NOT NULL DEFAULT 0,
        server_started_at TEXT NULL,
        allowed_duration_sec INTEGER NULL,
        deadline_at INTEGER NULL,
        status TEXT NOT NULL DEFAULT 'in_progress',
        is_offline INTEGER NOT NULL DEFAULT 0,
        idempotency_key TEXT NOT NULL,
        provisional_score INTEGER NULL,
        official_score INTEGER NULL,
        sync_error TEXT NULL,
        created_at INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL DEFAULT 0
      )''');
    raw.execute('''
      CREATE TABLE downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pack_id TEXT NOT NULL,
        pack_type TEXT NOT NULL DEFAULT 'questions',
        version TEXT NOT NULL DEFAULT '1',
        total_bytes INTEGER NOT NULL DEFAULT 0,
        downloaded_bytes INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        local_path TEXT NULL,
        checksum TEXT NULL,
        created_at INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL DEFAULT 0,
        expires_at INTEGER NULL
      )''');
    raw.execute('PRAGMA user_version = 3');

    final db = AppDatabase(NativeDatabase.opened(raw));
    await db.customSelect('SELECT 1').getSingle();

    expect(db.schemaVersion, 4);

    final rows = await db.select(db.cachedResponses).get();
    expect(rows, isEmpty, reason: 'a migration must not invent cached content');

    // And the table is usable.
    await db.into(db.cachedResponses).insert(
          CachedResponsesCompanion.insert(
            cacheKey: 'GET /quiz/courses',
            body: '{"success":true}',
            cachedAt: DateTime.utc(2026, 9, 30),
            expiresAt: DateTime.utc(2026, 9, 30, 1),
            byteSize: 17,
          ),
        );
    expect(await db.select(db.cachedResponses).get(), hasLength(1));

    await db.close();
  });

  test('v4 fresh install: the table exists and starts empty', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').getSingle();

    final table = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='cached_responses'",
        )
        .get();
    expect(table, hasLength(1));
    expect(await db.select(db.cachedResponses).get(), isEmpty);

    expect(db.schemaVersion, 4);
    await db.close();
  });
}

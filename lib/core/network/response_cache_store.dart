import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../storage/database/app_database.dart';
import 'response_cache_policy.dart';

/// A cached response, and how fresh it is.
class CachedEntry {
  const CachedEntry({
    required this.body,
    required this.cachedAt,
    required this.expiresAt,
    required this.isFresh,
    required this.stale,
  });

  /// The raw JSON envelope, re-parsed on read.
  final Map<String, dynamic> body;
  final DateTime cachedAt;
  final DateTime expiresAt;

  /// Within its TTL: safe to serve without revalidating.
  final bool isFresh;

  /// Past its TTL but still the best thing we have. Served when the network is
  /// unavailable, and revalidated in the background when it is not.
  final bool stale;
}

/// Reads and writes public catalog response bodies.
///
/// Deliberately narrow: only what [ResponseCachePolicy] allows, bounded by a
/// byte budget, and versioned so a payload whose meaning changes is dropped
/// rather than misread.
class ResponseCacheStore {
  ResponseCacheStore(this._db);

  final AppDatabase _db;

  /// Total bytes currently stored. Used to enforce the budget before writing.
  ///
  /// Summed in Dart rather than SQL because Drift's expression API would need
  /// a `sum<int>` helper for a column that is already non-null, and this runs
  /// once per write on a table that holds a handful of rows.
  Future<int> _totalBytes() async {
    final rows = await _db.select(_db.cachedResponses).get();
    return rows.fold<int>(0, (sum, row) => sum + row.byteSize);
  }

  /// The cached body for [key], or null when absent, expired beyond usefulness,
  /// or written by a different payload version.
  Future<CachedEntry?> read(String key, {DateTime? now}) async {
    final query = _db.select(_db.cachedResponses)
      ..where((t) => t.cacheKey.equals(key));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    if (row.schemaVersion != ResponseCachePolicy.schemaVersion) {
      // A payload whose meaning changed. Drop it rather than reinterpret it.
      await delete(key);
      return null;
    }

    final at = now ?? DateTime.now();
    final isFresh = at.isBefore(row.expiresAt);
    // Beyond this horizon an entry is not "stale", it is misleading. A syllabus
    // tree a fortnight old can be a superseded exam structure.
    const maxStaleAge = Duration(days: 14);
    if (!isFresh && at.difference(row.cachedAt) > maxStaleAge) {
      await delete(key);
      return null;
    }

    final decoded = _tryDecode(row.body);
    if (decoded == null) {
      // Truncated or written by an older build. Not worth debugging in the
      // field; drop and refetch.
      await delete(key);
      return null;
    }

    return CachedEntry(
      body: decoded,
      cachedAt: row.cachedAt,
      expiresAt: row.expiresAt,
      isFresh: isFresh,
      stale: !isFresh,
    );
  }

  /// Stores [body] under [key] for [ttl], evicting if the budget requires it.
  Future<void> write(
    String key,
    Map<String, dynamic> body, {
    required Duration ttl,
    String? etag,
    DateTime? now,
  }) async {
    final encoded = jsonEncode(body);
    final size = encoded.length;
    if (size > ResponseCachePolicy.maxEntryBytes) {
      // One oversized payload should not evict everything else to make room.
      return;
    }

    await _evictToBudget(size);

    final at = now ?? DateTime.now();
    await _db.into(_db.cachedResponses).insertOnConflictUpdate(
          CachedResponsesCompanion.insert(
            cacheKey: key,
            body: encoded,
            etag: Value(etag),
            cachedAt: at,
            expiresAt: at.add(ttl),
            byteSize: size,
            schemaVersion: Value(ResponseCachePolicy.schemaVersion),
          ),
        );
  }

  Future<void> delete(String key) async {
    await (_db.delete(_db.cachedResponses)
          ..where((t) => t.cacheKey.equals(key)))
        .go();
  }

  /// Drops everything. Used on sign-out and on a payload-version bump.
  Future<void> clear() async {
    await _db.delete(_db.cachedResponses).go();
  }

  /// Removes expired-then-stale entries first, then oldest, until [incoming]
  /// bytes fit inside the budget.
  Future<void> _evictToBudget(int incoming) async {
    final total = await _totalBytes();
    final target = ResponseCachePolicy.maxTotalBytes - incoming;
    if (total <= target) return;

    // Oldest first: a stale entry is worth less than a fresh one, and among
    // equals the least recently written is the least likely to be read again.
    final rows = await (_db.select(_db.cachedResponses)
          ..orderBy([(t) => OrderingTerm.asc(t.cachedAt)]))
        .get();

    var running = total;
    for (final row in rows) {
      if (running <= target) break;
      await delete(row.cacheKey);
      running -= row.byteSize;
    }
  }

  Map<String, dynamic>? _tryDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException catch (error) {
      // Logged at fine rather than warning: a corrupt cache entry is expected
      // occasionally (killed mid-write) and is self-healing.
      debugPrint('response cache: dropping unreadable entry ($error)');
      return null;
    }
  }
}

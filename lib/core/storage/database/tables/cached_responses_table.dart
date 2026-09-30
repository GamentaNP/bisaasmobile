import 'package:drift/drift.dart';

/// A single cached GET body, for public catalog reads only.
///
/// ## Why this table is back
///
/// It existed under v2 with an `etag` column and was dropped in v3. The stated
/// reason was sound — it stored full GET payloads on disk unencrypted and
/// nothing ever read it back — but the replacement it was dropped *for* never
/// arrived: the comment claimed "HTTP ETag replay via ApiCacheHeaders is the
/// only cache", `ApiCacheHeaders` is a server-side Laravel trait that no client
/// code references, and the server advertises ETags but returns 200 rather than
/// 304 (verified on /syllabi, /quiz/courses, /calculators and /library/categories).
/// So the app was left with no response cache at all.
///
/// This version keeps the security property that justified the drop and adds
/// the wiring that was missing:
///
///   * **Public data only.** The writer is gated by an allowlist, not a
///     denylist (see `ResponseCachePolicy` in lib/core/network/). Anything not
///     explicitly named is never written. `/me`, wallet, attempt and purchase
///     responses contain PII and must never land here — the device database is
///     unencrypted.
///   * **Bounded.** [byteSize] plus a total budget, so a hostile or buggy
///     server cannot fill the user's storage.
///   * **Invalidatable.** [schemaVersion] lets a client release drop every entry
///     without a migration, which is what a DTO shape change needs.
class CachedResponses extends Table {
  /// `GET /path?sorted=query|Accept-Language`. Primary key: one entry per
  /// distinct request, so a changed query is a different entry rather than an
  /// overwrite.
  TextColumn get cacheKey => text()();

  /// The raw JSON envelope, stored verbatim. Re-parsed on read rather than
  /// serialised DTOs, so a DTO field rename does not invalidate the cache.
  TextColumn get body => text()();

  /// The server-advertised ETag, kept for diagnostics and for a future
  /// conditional request. Not currently used to skip a transfer, because the
  /// server does not honour `If-None-Match`.
  TextColumn get etag => text().nullable()();

  DateTimeColumn get cachedAt => dateTime()();

  /// Freshness deadline. Past this the entry is stale: still served when the
  /// network is unavailable, but revalidated in the background when it is not.
  DateTimeColumn get expiresAt => dateTime()();

  /// Length of [body], so eviction can enforce a budget without decoding it.
  IntColumn get byteSize => integer()();

  /// Bumped when a cached payload's meaning changes. Mismatched entries are
  /// treated as absent.
  TextColumn get schemaVersion => text().withDefault(const Constant('1'))();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}

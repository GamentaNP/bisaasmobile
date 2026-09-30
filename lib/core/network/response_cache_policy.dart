import 'package:dio/dio.dart';

/// Decides which responses may be written to disk, and for how long.
///
/// ## Why an allowlist and not a denylist
///
/// The device database is unencrypted. Everything written here is readable by
/// anything with the app's sandbox on a rooted device, and recoverable from a
/// backup. So the rule is the conservative one: a response is cached only if it
/// is *named here*. A denylist would need to enumerate every endpoint that
/// returns PII, and the day someone adds `GET /me/email-preferences` the
/// denylist silently misses it.
///
/// Explicitly never cached, whatever else changes:
///   * anything under `/me` — identity, wallet, streak, syllabus plan
///   * `/economy/*` — coin balances, ledger, shop
///   * `/quiz/attempts*` — attempt state and grading
///   * any purchase, claim, submission or mutation
///   * `/social/*` — referral codes and share links
///   * anything that is not a GET
///
/// ## Why the TTLs differ
///
/// A syllabus tree changes when the exam authority publishes a revision, and
/// the server already caches that payload for 24h keyed on `structure_hash`.
/// A calculator catalog changes when CivilCal ships one. Question *counts*
/// change constantly, so those get a short TTL and are treated as advisory.
///
/// None of these can be made conditional: the server advertises ETags but
/// answers a matching `If-None-Match` with 200, not 304. So freshness is a
/// client-side deadline, and the stale copy is what the user sees while a
/// background refresh runs.
abstract final class ResponseCachePolicy {
  const ResponseCachePolicy._();

  /// Bumped when the meaning of a cached payload changes. A mismatch makes the
  /// entry invalid rather than being silently reinterpreted.
  static const schemaVersion = '1';

  /// Total bytes the cache may occupy. Generous for the catalog set this app
  /// actually caches, and small enough that a runaway server cannot fill a
  /// user's storage.
  static const int maxTotalBytes = 8 * 1024 * 1024;

  /// A single response larger than this is never stored, whatever its TTL.
  /// The syllabus tree at depth 3 is the largest thing cached and sits well
  /// under this.
  static const int maxEntryBytes = 512 * 1024;

  /// Path prefix -> freshness window.
  ///
  /// Matched longest-prefix-first so `/syllabi/x/tree` can differ from
  /// `/syllabi`. Paths are relative to `/api/v1`, exactly as `ApiConfig` builds
  /// them, and are compared case-sensitively because the server's routes are.
  static const Map<String, Duration> _freshness = {
    // The exam tree is the app's centrepiece and the most expensive fetch.
    // 12h matches the server's own 24h structure cache closely enough that a
    // revision reaches the app within a day without hammering the endpoint.
    '/syllabi': Duration(hours: 12),

    // Course and calculator catalogs change rarely and are read on every tab
    // switch, so a long TTL buys the most here.
    '/quiz/courses': Duration(hours: 6),
    '/calculators': Duration(hours: 6),

    // Library categories and the trending shelf. `files` is a paginated search
    // surface with arbitrary filters, so it is not cached: the key space is
    // unbounded and every distinct query would be an entry.
    '/library/categories': Duration(hours: 12),
    '/library/trending': Duration(hours: 3),

    // Books catalog. Same reasoning as courses.
    '/books': Duration(hours: 6),
  };

  /// Freshness for [path], or null when the path must not be cached.
  static Duration? freshnessFor(String path) {
    if (_isNeverCacheable(path)) return null;
    var bestPrefix = '';
    var bestTtl = Duration.zero;
    var matched = false;
    for (final entry in _freshness.entries) {
      if (_matches(path, entry.key) && entry.key.length > bestPrefix.length) {
        bestPrefix = entry.key;
        bestTtl = entry.value;
        matched = true;
      }
    }
    return matched ? bestTtl : null;
  }

  /// Whether [options] is eligible at all, ignoring the allowlist.
  ///
  /// Split from [freshnessFor] so the interceptor can skip the work entirely
  /// for the overwhelming majority of requests that are not cacheable.
  static bool isEligible(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') return false;
    if (options.responseType == ResponseType.stream) return false;
    if (options.extra['retry_attempt'] != null) return false;
    if (options.extra['skipAuthRefresh'] == true) return false;
    // A response we could not interpret is not worth persisting.
    if (options.responseType != ResponseType.json) return false;
    return freshnessFor(options.path) != null;
  }

  /// Hard exclusions, checked before the allowlist.
  ///
  /// These are all *inside* prefixes the allowlist would otherwise accept, or
  /// are the paths most likely to be added by a future endpoint. Belt and
  /// braces: an allowlist that accidentally grows must still not capture a
  /// wallet.
  static bool _isNeverCacheable(String path) {
    const forbidden = [
      '/me',
      '/economy',
      '/store',
      '/quiz/attempts',
      '/quiz/streak',
      '/quiz/leaderboards',
      '/quiz/game',
      '/social',
      '/rewards',
      '/library/me',
      '/library/files', // paginated, arbitrary filters, unbounded key space
      '/donations',
      '/notifications',
      '/app/config', // latched in memory by AppConfigCache; a stale copy here
      // would fight it
    ];
    for (final prefix in forbidden) {
      if (_matches(path, prefix)) return true;
    }
    return false;
  }

  /// Path equality or a `/`-delimited prefix match.
  ///
  /// Deliberately not a plain `startsWith`: `/syllabiXYZ` must not match
  /// `/syllabi`, or a new endpoint would be captured by an existing entry.
  static bool _matches(String path, String prefix) {
    if (path == prefix) return true;
    if (!path.startsWith(prefix)) return false;
    final next = path[prefix.length];
    return next == '/' || prefix.endsWith('/');
  }
}

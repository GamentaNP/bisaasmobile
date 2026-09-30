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
/// ## Not all of these are actually user-invariant
///
/// Two entries below are **not** the same body for every caller:
/// `LibraryApiController::categories()` counts files through
/// `applyVisibleTo($query, $user)` and `trending()` ranks through the caller's
/// own visibility, so both are functions of the signed-in principal. They are
/// cacheable — the cache key is a hash of the bearer token, so two accounts can
/// never read each other's entry — but they get a minutes-long TTL instead of
/// hours, because an entitlement granted mid-session must show up promptly and a
/// revoked one must disappear promptly.
///
/// Every other entry is verified user-invariant on the server:
/// `SyllabusCatalogController` and `QuizCourseApiController` read no principal
/// on those paths, and `tree()` is served from a tenant-keyed cache.
///
/// ## The parameter trap
///
/// A prefix entry covers the whole subtree, so `/syllabi` also covers
/// `/syllabi/{v}/nodes/{n}/questions` — which *is* user-scoped when called with
/// `filter[exclude_seen]=true`, because it drops what the caller has already
/// answered. A path cannot express that, so the parameter is excluded by name
/// in [isEligible] instead.
abstract final class ResponseCachePolicy {
  const ResponseCachePolicy._();

  /// Bumped when the meaning of a cached payload changes, or when the key
  /// derivation changes. A mismatch makes the entry invalid rather than being
  /// silently reinterpreted.
  ///
  /// v2 adds the credential fingerprint to the key. Every v1 entry was written
  /// under a key that could not distinguish one signed-in user from another, so
  /// none of them may survive.
  static const schemaVersion = '2';

  /// Total bytes the cache may occupy. Generous for the catalog set this app
  /// actually caches, and small enough that a runaway server cannot fill a
  /// user's storage.
  static const int maxTotalBytes = 8 * 1024 * 1024;

  /// A single response larger than this is never stored, whatever its TTL.
  /// The syllabus tree at depth 3 is the largest thing cached and sits well
  /// under this.
  static const int maxEntryBytes = 512 * 1024;

  /// Path prefix -> freshness window, for bodies that are identical for every
  /// caller.
  ///
  /// Matched longest-prefix-first so a more specific entry can override a
  /// broader one. Paths are relative to `/api/v1`, exactly as `ApiConfig` builds
  /// them, and are compared case-sensitively because the server's routes are.
  ///
  /// ## Why the TTLs differ
  ///
  /// A syllabus tree changes when the exam authority publishes a revision, and
  /// the server already caches that payload for 24h keyed on `structure_hash`.
  /// A calculator catalog changes when CivilCal ships one. So these are long.
  ///
  /// Freshness here is a client-side deadline, and the stale copy is what the
  /// user sees while a background refresh runs. The server *does* answer a
  /// matching `If-None-Match` with 304 — `ApiCacheHeaders` implements it and
  /// `tests/Feature/Api/V1/ApiCacheHeadersTest.php` asserts it — so a future
  /// revision may add conditional revalidation on top of this without changing
  /// the offline behaviour these TTLs exist for.
  static const Map<String, Duration> _freshness = {
    // The exam tree is the app's centrepiece and the most expensive fetch.
    // 12h matches the server's own 24h structure cache closely enough that a
    // revision reaches the app within a day without hammering the endpoint.
    '/syllabi': Duration(hours: 12),

    // Course and calculator catalogs change rarely and are read on every tab
    // switch, so a long TTL buys the most here.
    '/quiz/courses': Duration(hours: 6),
    '/calculators': Duration(hours: 6),

    // Books catalog. Same reasoning as courses.
    '/books': Duration(hours: 6),
  };

  /// Path prefix -> freshness window, for bodies that depend on the caller.
  ///
  /// These are safe to cache only because the cache key carries a hash of the
  /// bearer token, so entry-for-account-A is unreachable by account B. Keep it
  /// that way: adding a path here without a credential-scoped key would be a
  /// cross-account disclosure.
  ///
  /// The TTLs are minutes, not hours. These bodies are functions of what the
  /// principal may see, so an unlock, a purchase or a subscription change has to
  /// reach the screen promptly — in both directions.
  static const Map<String, Duration> _userScopedFreshness = {
    // `withCount(files)` filtered through `applyVisibleTo($query, $user)`.
    '/library/categories': Duration(minutes: 5),
    // Ranked through the caller's own visibility in `searchService->trending()`.
    '/library/trending': Duration(minutes: 5),
  };

  /// Query parameters that make an otherwise-public response user-specific.
  ///
  /// `filter[exclude_seen]=true` tells the server to drop questions the caller
  /// has already answered, so the body differs per principal while the path
  /// stays under a public prefix. The path alone cannot express that, so the
  /// parameter is refused by name.
  static const Set<String> _userVaryingParams = {
    'filter[exclude_seen]',
    'exclude_seen',
  };

  /// Whether [path] resolves to a body that depends on the signed-in caller.
  static bool isUserScoped(String path) => _longestMatch(path, _userScopedFreshness) != null;

  /// Freshness for [path], or null when the path must not be cached.
  static Duration? freshnessFor(String path) {
    if (_isNeverCacheable(path)) return null;
    return _longestMatch(path, _freshness) ?? _longestMatch(path, _userScopedFreshness);
  }

  /// The TTL of the longest matching prefix across both maps.
  static Duration? _longestMatch(String path, Map<String, Duration> table) {
    var bestPrefix = '';
    Duration? bestTtl;
    for (final entry in table.entries) {
      if (_matches(path, entry.key) && entry.key.length > bestPrefix.length) {
        bestPrefix = entry.key;
        bestTtl = entry.value;
      }
    }
    return bestTtl;
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
    // A user-varying parameter makes the body per-principal even on a public
    // path, and the key cannot tell two principals apart for an anonymous
    // caller who set it. Refuse rather than guess.
    for (final param in options.queryParameters.keys) {
      if (_userVaryingParams.contains(param)) return false;
    }
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

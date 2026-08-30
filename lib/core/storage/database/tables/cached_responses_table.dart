import 'package:drift/drift.dart';

/// ETag cache for `ApiCacheHeaders` endpoints — `BCP §5.8`.
/// Stores 304-replay bodies for `GET /calculators`, `GET /quiz/courses`, etc.
class CachedResponses extends Table {
  TextColumn get cacheKey => text().named('cache_key')(); // url + sorted query
  TextColumn get etag => text().nullable()();
  TextColumn get body => text()();
  TextColumn get url => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().named('cached_at').withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime().named('expires_at').nullable()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

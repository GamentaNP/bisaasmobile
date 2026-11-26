import 'package:drift/drift.dart';

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get endpoint => text()();
  TextColumn get method => text().withDefault(const Constant('POST'))();
  TextColumn get payload => text().nullable()();
  // Unique: one queue entry per idempotent operation — server dedupes on it.
  TextColumn get idempotencyKey => text().nullable().unique()();
  /// Tenant the operation was minted under. A queued write must never be
  /// replayed after the user switches organizations — the credential's tenant
  /// assertion would silently land the write in the wrong workspace.
  IntColumn get tenantId => integer().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
}

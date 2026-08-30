import 'package:drift/drift.dart';

/// Offline pack downloads — `design-research.md:585` + master plan §6.4.
/// One row per downloadable pack (course, topic, offline quiz pack).
class Downloads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packId => text().named('pack_id').unique()();
  TextColumn get packType => text().named('pack_type').withDefault(const Constant('questions'))();
  TextColumn get version => text().withDefault(const Constant('1'))();
  IntColumn get totalBytes => integer().named('total_bytes').withDefault(const Constant(0))();
  IntColumn get downloadedBytes => integer().named('downloaded_bytes').withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending|downloading|completed|failed|paused
  TextColumn get localPath => text().named('local_path').nullable()();
  TextColumn get checksum => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime().named('expires_at').nullable()();
}

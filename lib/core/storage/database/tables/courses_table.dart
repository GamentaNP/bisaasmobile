import 'package:drift/drift.dart';

class Courses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get slug => text().unique()();
  TextColumn get payload => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().nullable()();
}

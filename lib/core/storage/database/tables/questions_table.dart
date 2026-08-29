library;

import 'package:drift/drift.dart';

class Questions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  IntColumn get difficulty => integer().withDefault(const Constant(0))();
  DateTimeColumn get cachedAt => dateTime().nullable()();
}

import 'package:drift/drift.dart';

class Calculations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get calculatorId => text()();
  TextColumn get inputs => text()();
  TextColumn get result => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

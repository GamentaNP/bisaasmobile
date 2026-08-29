library;

import 'package:drift/drift.dart';

class Attempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer()();
  IntColumn get selectedOption => integer().nullable()();
  BoolColumn get isCorrect => boolean().nullable()();
  DateTimeColumn get answeredAt => dateTime().withDefault(currentDateAndTime)();
}

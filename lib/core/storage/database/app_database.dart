library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/calculations_table.dart';
import 'tables/courses_table.dart';
import 'tables/questions_table.dart';
import 'tables/attempts_table.dart';
import 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Questions, Attempts, Courses, Calculations, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'bisaas_app'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
      );
}

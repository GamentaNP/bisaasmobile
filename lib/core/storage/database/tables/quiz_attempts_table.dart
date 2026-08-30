import 'package:drift/drift.dart';

/// Attempt-level header — `BCP §6.4` reconciliation.
/// Existing `Attempts` table is per-answer; this is per-attempt so
/// `serverAttemptId` has a stable home for the §5.12 drain flow.
class QuizAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverAttemptId => text().named('server_attempt_id').nullable().unique()();
  TextColumn get quizId => text().named('quiz_id')();
  TextColumn get questionIdsJson => text().named('question_ids_json').withDefault(const Constant('[]'))();
  DateTimeColumn get startedAt => dateTime().named('started_at').withDefault(currentDateAndTime)();
  DateTimeColumn get serverStartedAt => dateTime().named('server_started_at').nullable()();
  IntColumn get allowedDurationSec => integer().named('allowed_duration_sec').withDefault(const Constant(1200))();
  DateTimeColumn get deadlineAt => dateTime().named('deadline_at').nullable()();
  TextColumn get status => text().withDefault(const Constant('in_progress'))(); // in_progress|completed_local|syncing|synced|failed
  BoolColumn get isOffline => boolean().named('is_offline').withDefault(const Constant(false))();
  TextColumn get idempotencyKey => text().named('idempotency_key').unique()();
  IntColumn get provisionalScore => integer().named('provisional_score').nullable()();
  IntColumn get officialScore => integer().named('official_score').nullable()();
  TextColumn get syncError => text().named('sync_error').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();
}

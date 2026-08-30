import 'package:drift/drift.dart';

/// Offline quiz attempt answers cache — synced with /api/v1/quiz/attempts/{id}/answer when online.
class Attempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Remote attempt UUID from server (POST /api/v1/quiz/attempts)
  TextColumn get remoteAttemptId => text().named('remote_attempt_id').nullable()();
  // Question remote_id  
  TextColumn get questionId => text().named('question_id')();
  // Selected option id (chosen answer key)
  TextColumn get selectedOptionId => text().named('selected_option_id').nullable()();
  // Server responds with this after grading
  BoolColumn get isCorrect => boolean().named('is_correct').nullable()();
  IntColumn get xpEarned => integer().named('xp_earned').withDefault(const Constant(0))();
  IntColumn get coinsEarned => integer().named('coins_earned').withDefault(const Constant(0))();
  // 0=pending sync, 1=synced, 2=failed
  IntColumn get syncStatus => integer().named('sync_status').withDefault(const Constant(0))();
  DateTimeColumn get answeredAt => dateTime().named('answered_at').withDefault(currentDateAndTime)();
}

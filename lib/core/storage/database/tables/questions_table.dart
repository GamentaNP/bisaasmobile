import 'package:drift/drift.dart';

/// Questions cache table — stores offline quiz questions fetched from /api/v1/quiz/questions.
class Questions extends Table {
  // Server UUID stored as text
  TextColumn get remoteId => text().named('remote_id')();
  TextColumn get quizId => text().named('quiz_id').nullable()();
  TextColumn get subjectSlug => text().named('subject_slug').withDefault(const Constant(''))();
  TextColumn get body => text()();
  // JSON-encoded list of answer options [{id, text, position}]
  TextColumn get optionsJson => text().named('options_json')();
  // Correct answer id — only known after server submission
  TextColumn get correctOptionId => text().named('correct_option_id').nullable()();
  TextColumn get explanation => text().nullable()();
  IntColumn get difficulty => integer().withDefault(const Constant(1))();
  IntColumn get marksPositive => integer().named('marks_positive').withDefault(const Constant(4))();
  IntColumn get marksNegative => integer().named('marks_negative').withDefault(const Constant(0))();
  DateTimeColumn get cachedAt => dateTime().named('cached_at').nullable()();

  @override
  Set<Column> get primaryKey => {remoteId};
}

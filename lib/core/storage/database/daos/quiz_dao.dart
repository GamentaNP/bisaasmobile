import '../app_database.dart';

class QuizDao {
  QuizDao(this.db);
  final AppDatabase db;

  Future<List<Question>> all() => db.select(db.questions).get();

  Future<int> upsert(QuestionsCompanion c) =>
      db.into(db.questions).insertOnConflictUpdate(c);

  Future<int> clear() => db.delete(db.questions).go();
}

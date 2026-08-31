import 'package:drift/drift.dart';

import '../app_database.dart';

class QuizDao {
  QuizDao(this.db);
  final AppDatabase db;

  Future<List<Question>> all() => db.select(db.questions).get();

  Future<int> count() async {
    final expr = db.questions.remoteId.count();
    final query = db.selectOnly(db.questions)..addColumns([expr]);
    final row = await query.getSingle();
    return row.read(expr) ?? 0;
  }

  Future<int> upsert(QuestionsCompanion c) =>
      db.into(db.questions).insertOnConflictUpdate(c);

  Future<int> clear() => db.delete(db.questions).go();
}

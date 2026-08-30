import 'package:drift/drift.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/database/app_database.dart';
import '../../../../core/storage/database/daos/quiz_dao.dart';
import '../models/quiz_dto.dart';

/// Drift-backed offline cache for quiz questions.
///
/// Policy (research 14-18): public content = cache+refresh, authoritative
/// (XP/coins/rank) = never cache. Questions are public content — cache long,
/// refresh on next successful remote fetch.
class QuizLocalDataSource {
  QuizLocalDataSource(this._db) : _dao = QuizDao(_db);
  final AppDatabase _db;
  final QuizDao _dao;

  Future<void> cacheSession(QuizSessionDto dto) async {
    try {
      for (final q in dto.questions) {
        await _dao.upsert(
          QuestionsCompanion(
            remoteId: Value(q.id),
            quizId: Value(dto.id),
            subjectSlug: Value(q.subjectSlug),
            body: Value(q.body),
            optionsJson: Value(q.optionsToJson()),
            correctOptionId: Value(q.correctOptionId),
            explanation: Value(q.explanation),
            difficulty: Value(q.difficulty),
            marksPositive: Value(q.marksPositive),
            marksNegative: Value(q.marksNegative),
            cachedAt: Value(DateTime.now()),
          ),
        );
      }
      AppLogger.i('QuizLocal: cached ${dto.questions.length} Qs for ${dto.id}');
    } catch (e, st) {
      AppLogger.w('QuizLocal cacheSession failed: $e');
      AppLogger.d(st);
    }
  }

  Future<QuizSessionDto?> getCachedSession(String quizId) async {
    try {
      final rows = await (_db.select(_db.questions)
            ..where((t) => t.quizId.equals(quizId)))
          .get();
      if (rows.isEmpty) return null;

      final questions = rows.map((r) {
        return QuestionDto.fromJson({
          'id': r.remoteId,
          'body': r.body,
          'options': r.optionsJson, // JSON string decoded inside fromJson
          'subject_slug': r.subjectSlug,
          'difficulty': r.difficulty,
          'marks_positive': r.marksPositive,
          'marks_negative': r.marksNegative,
          'quiz_id': r.quizId,
          'explanation': r.explanation,
          'correct_option_id': r.correctOptionId,
        });
      }).toList();

      return QuizSessionDto(
        id: quizId,
        title: 'Offline Practice — ${quizId.replaceAll('-', ' ')}',
        questions: questions,
        durationSeconds: questions.length * 60, // 1 min / Q fallback
      );
    } catch (e, st) {
      AppLogger.w('QuizLocal getCachedSession $quizId failed: $e');
      AppLogger.d(st);
      return null;
    }
  }

  /// Quick check used by repository to decide fallback banner.
  Future<bool> hasCached(String quizId) async {
    final count = await (_db.selectOnly(_db.questions)
          ..addColumns([_db.questions.remoteId.count()])
          ..where(_db.questions.quizId.equals(quizId)))
        .map((r) => r.read(_db.questions.remoteId.count()) ?? 0)
        .getSingle();
    return count > 0;
  }
}

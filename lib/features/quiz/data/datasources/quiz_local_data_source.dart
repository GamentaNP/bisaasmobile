import 'dart:convert';

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

  /// Caches the daily offline pack from `GET /api/v1/mobile/daily-quiz-pack`.
  ///
  /// The pack is built server-side and deliberately **carries no answer key**
  /// (`DailyQuizService::buildOfflinePack` returns only id/body/options/image_url),
  /// so `correctOptionId` is always written as null. Offline play can therefore
  /// never grade locally — it reconciles through the server, which is the whole
  /// point of the boundary rule.
  Future<void> cacheDailyPack({
    required String quizId,
    required List<Map<String, dynamic>> questions,
    String subjectSlug = 'daily',
  }) async {
    if (questions.isEmpty) return;
    try {
      for (final raw in questions) {
        final id = raw['id'];
        if (id == null) continue;
        final options = raw['options'];
        await _dao.upsert(
          QuestionsCompanion(
            remoteId: Value(id.toString()),
            quizId: Value(quizId),
            subjectSlug: Value(subjectSlug),
            body: Value((raw['body'] ?? '').toString()),
            // Server sends [{key, text}]; store the same shape the session
            // cache uses so the offline reader can parse one format.
            optionsJson: Value(jsonEncode(options is List ? options : const [])),
            // Never populated from the pack — grading is server-side.
            correctOptionId: const Value.absent(),
            cachedAt: Value(DateTime.now()),
          ),
        );
      }
      AppLogger.i('QuizLocal: cached daily pack ${questions.length} Qs for $quizId');
    } catch (e, st) {
      AppLogger.w('QuizLocal cacheDailyPack failed: $e');
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

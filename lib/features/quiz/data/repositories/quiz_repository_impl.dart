import 'package:dio/dio.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/attempt_result.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_local_data_source.dart';
import '../datasources/quiz_remote_data_source.dart';

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl(this._remote, {QuizLocalDataSource? local}) : _local = local;
  final QuizRemoteDataSource _remote;
  final QuizLocalDataSource? _local;

  @override
  Future<List<Map<String, dynamic>>> getQuizList({String? subjectSlug}) =>
      _remote.getQuizList(subjectSlug: subjectSlug);

  @override
  Future<QuizSession> getQuizSession(String quizId) async {
    try {
      final dto = await _remote.getQuizSession(quizId);
      // Cache-then-return — keep offline fresh.
      if (_local != null) await _local.cacheSession(dto);
      return dto.toDomain();
    } on DioException catch (e) {
      final isOffline = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.response == null;
      if (!isOffline || _local == null) rethrow;
      // Offline fallback — Drift cached questions, labeled as practice.
      final cached = await _local.getCachedSession(quizId);
      if (cached == null) rethrow;
      AppLogger.w('QuizRepository: serving cached session $quizId offline (${cached.questions.length} Qs)');
      return cached.toDomain();
    }
  }

  @override
  Future<String> startAttempt({
    required String quizId,
    String? idempotencyKey,
    List<int>? questionIds,
  }) =>
      _remote.startAttempt(
        quizId: quizId,
        idempotencyKey: idempotencyKey,
        questionIds: questionIds,
      );

  @override
  Future<AttemptResult> submitAnswer({
    required String attemptId,
    required String questionId,
    required String selectedOptionId,
    String? idempotencyKey,
  }) async {
    final dto = await _remote.submitAnswer(
      attemptId: attemptId,
      questionId: questionId,
      selectedOptionId: selectedOptionId,
      idempotencyKey: idempotencyKey,
    );
    return dto.toDomain();
  }

  @override
  Future<QuizResult> finishAttempt(String attemptId) async {
    final dto = await _remote.finishAttempt(attemptId);
    return dto.toDomain();
  }
}

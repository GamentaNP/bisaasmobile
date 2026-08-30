import '../entities/question.dart';
import '../entities/attempt_result.dart';

abstract class QuizRepository {
  /// Fetch list of available quizzes/topics from /api/v1/quiz/quizzes
  Future<List<Map<String, dynamic>>> getQuizList({String? subjectSlug});

  /// Fetch questions for a quiz from /api/v1/quiz/quizzes/{id}/questions
  Future<QuizSession> getQuizSession(String quizId);

  /// Start an attempt on the server → POST /api/v1/quiz/attempts
  /// Returns the server-assigned attempt UUID
  Future<String> startAttempt({required String quizId, String? idempotencyKey});

  /// Submit a single question answer → POST /api/v1/quiz/attempts/{attemptId}/answer
  /// Server is source of truth for grading, XP, and coins
  Future<AttemptResult> submitAnswer({
    required String attemptId,
    required String questionId,
    required String selectedOptionId,
    String? idempotencyKey,
  });

  /// Finish the attempt → POST /api/v1/quiz/attempts/{attemptId}/finish
  Future<QuizResult> finishAttempt(String attemptId);
}

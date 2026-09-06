import '../entities/question.dart';
import '../entities/attempt_result.dart';

abstract class QuizRepository {
  /// Fetch list of available quizzes/topics from GET /api/v1/quiz/courses
  Future<List<Map<String, dynamic>>> getQuizList({String? subjectSlug});

  /// Fetch questions for a course from GET /api/v1/quiz/courses/{id}/questions
  /// [categoryId] narrows the pool to one course category.
  Future<QuizSession> getQuizSession(String quizId, {int? categoryId});

  /// Start an attempt on the server — POST /api/v1/quiz/attempts/start
  /// [questionIds] must be the ids fetched for this session — the server
  /// seeds its grading rows from them, so answering requires the same set.
  /// (Never delegate to the server's category_id seeding: it draws a
  /// different pool than the session on screen and every answer 404s.)
  /// Returns the server attempt id.
  Future<String> startAttempt({
    required String quizId,
    String? idempotencyKey,
    List<int>? questionIds,
  });

  /// Submit a single question answer — POST /api/v1/quiz/attempts/{attemptId}/answer
  /// Server is source of truth for grading, XP, and coins
  Future<AttemptResult> submitAnswer({
    required String attemptId,
    required String questionId,
    required String selectedOptionId,
    String? idempotencyKey,
  });

  /// Finish the attempt — POST /api/v1/quiz/attempts/{attemptId}/complete
  Future<QuizResult> finishAttempt(String attemptId);
}

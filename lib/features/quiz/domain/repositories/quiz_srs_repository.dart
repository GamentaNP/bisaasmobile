import '../entities/quiz_srs.dart';

/// Boundary for the unified quiz spaced-repetition queue.
///
/// Implementations must throw on a transport failure, a non-2xx status or
/// an unreadable body. Returning an empty list is only allowed when the
/// server genuinely published zero due cards.
abstract class QuizSrsRepository {
  Future<List<QuizSrsCard>> getDueCards();

  /// [idempotencyKey] is owned by the controller and reused across retries
  /// of the same grade intent.
  Future<QuizSrsGradeResult> gradeReview(
    String reviewId, {
    required int quality,
    String? type,
    String? idempotencyKey,
  });
}

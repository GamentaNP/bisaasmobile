import '../entities/question_report.dart';
import '../entities/review.dart';

/// Boundary for the learner-review cluster.
///
/// Implementations throw on a transport failure, a non-2xx status or an
/// unreadable body. An empty collection is only legitimate when the server
/// actually published zero rows.
abstract class ReviewRepository {
  Future<List<ReviewCard>> getDueCards();

  Future<AttemptReview> getAttemptReview(int attemptId);

  Future<ReviewGradeResult> gradeReview(
    String reviewId, {
    required int quality,
    required String type,
    String? idempotencyKey,
  });

  /// Throws on failure — a failed report is never a successful one locally.
  Future<QuestionReportResult> reportQuestion(
    int questionId, {
    required String category,
    required String description,
    String? suggestedCorrection,
    String? idempotencyKey,
  });
}

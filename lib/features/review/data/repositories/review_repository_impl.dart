import '../../domain/entities/question_report.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_data_source.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  const ReviewRepositoryImpl(this._remote);

  final ReviewRemoteDataSource _remote;

  @override
  Future<List<ReviewCard>> getDueCards() => _remote.getDueCards();

  @override
  Future<AttemptReview> getAttemptReview(int attemptId) =>
      _remote.getAttemptReview(attemptId);

  @override
  Future<ReviewGradeResult> gradeReview(
    String reviewId, {
    required int quality,
    required String type,
    String? idempotencyKey,
  }) => _remote.gradeReview(
    reviewId,
    quality: quality,
    type: type,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<QuestionReportResult> reportQuestion(
    int questionId, {
    required String category,
    required String description,
    String? suggestedCorrection,
    String? idempotencyKey,
  }) => _remote.reportQuestion(
    questionId,
    category: category,
    description: description,
    suggestedCorrection: suggestedCorrection,
    idempotencyKey: idempotencyKey,
  );
}

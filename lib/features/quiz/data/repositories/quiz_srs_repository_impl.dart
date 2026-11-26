import '../../domain/entities/quiz_srs.dart';
import '../../domain/repositories/quiz_srs_repository.dart';
import '../datasources/quiz_srs_remote_data_source.dart';

class QuizSrsRepositoryImpl implements QuizSrsRepository {
  const QuizSrsRepositoryImpl(this._remote);

  final QuizSrsRemoteDataSource _remote;

  @override
  Future<List<QuizSrsCard>> getDueCards() async {
    final dtos = await _remote.getDueCards();
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  @override
  Future<QuizSrsGradeResult> gradeReview(
    String reviewId, {
    required int quality,
    String? type,
    String? idempotencyKey,
  }) async {
    final dto = await _remote.gradeReview(
      reviewId,
      quality: quality,
      type: type,
      idempotencyKey: idempotencyKey,
    );
    return dto.toDomain();
  }
}

import '../datasources/arcade_remote_data_source.dart';
import '../../domain/entities/arcade_category.dart';
import '../../domain/entities/arcade_mode.dart';
import '../../domain/entities/arcade_result.dart';
import '../../domain/repositories/arcade_repository.dart';

/// Pass-through repository: the arcade has no local cache on purpose.
///
/// An offline arcade run would mean the client holding a question set it
/// cannot grade and a score it cannot award. The only offline path this app
/// has is the prefetched daily pack, and the arcade deliberately does not
/// join it — a run started offline would have to lie about its result.
class ArcadeRepositoryImpl implements ArcadeRepository {
  const ArcadeRepositoryImpl(this._remote);

  final ArcadeRemoteDataSource _remote;

  @override
  Future<int> start({
    required ArcadeMode mode,
    required String idempotencyKey,
    int? categoryId,
  }) =>
      _remote.start(
        mode: mode,
        idempotencyKey: idempotencyKey,
        categoryId: categoryId,
      );

  @override
  Future<ArcadeAttempt> loadAttempt(int attemptId) =>
      _remote.fetchAttempt(attemptId);

  @override
  Future<void> submitAnswer({
    required int attemptId,
    required int questionId,
    required String answer,
    required String idempotencyKey,
    required int timeTakenSeconds,
  }) =>
      _remote.submitAnswer(
        attemptId: attemptId,
        questionId: questionId,
        answer: answer,
        idempotencyKey: idempotencyKey,
        timeTakenSeconds: timeTakenSeconds,
      );

  @override
  Future<ArcadeResult> complete({
    required int attemptId,
    required String idempotencyKey,
  }) =>
      _remote.complete(attemptId: attemptId, idempotencyKey: idempotencyKey);

  @override
  Future<ArcadeResult> results(int attemptId) => _remote.results(attemptId);

  @override
  Future<void> abandon({
    required int attemptId,
    required String idempotencyKey,
  }) =>
      _remote.abandon(attemptId: attemptId, idempotencyKey: idempotencyKey);

  @override
  Future<List<ArcadeCourse>> courses() => _remote.courses();

  @override
  Future<List<ArcadeCategory>> categories({required ArcadeCourse course}) =>
      _remote.categories(course: course);
}

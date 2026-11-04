import '../entities/arcade_category.dart';
import '../entities/arcade_mode.dart';
import '../entities/arcade_question.dart';
import '../entities/arcade_result.dart';

/// The attempt as the run needs it: the server's status plus its questions.
typedef ArcadeAttempt = ({String status, List<ArcadeQuestion> questions});

/// What the arcade screen needs from the network.
///
/// Every method throws an `ApiException` or `ContractViolation` on failure —
/// there is no "empty list means something went wrong" path here, same as the
/// rest of the client.
abstract interface class ArcadeRepository {
  Future<int> start({
    required ArcadeMode mode,
    required String idempotencyKey,
    int? categoryId,
  });

  Future<ArcadeAttempt> loadAttempt(int attemptId);

  Future<void> submitAnswer({
    required int attemptId,
    required int questionId,
    required String answer,
    required String idempotencyKey,
    required int timeTakenSeconds,
  });

  Future<ArcadeResult> complete({
    required int attemptId,
    required String idempotencyKey,
  });

  Future<ArcadeResult> results(int attemptId);

  Future<void> abandon({
    required int attemptId,
    required String idempotencyKey,
  });

  Future<List<ArcadeCourse>> courses();

  Future<List<ArcadeCategory>> categories({required ArcadeCourse course});
}

import '../../domain/entities/sandbox_attempt.dart';
import '../../domain/repositories/sandbox_attempt_repository.dart';
import '../datasources/sandbox_attempt_remote_data_source.dart';

class SandboxAttemptRepositoryImpl implements SandboxAttemptRepository {
  const SandboxAttemptRepositoryImpl(this._remote);

  final SandboxAttemptRemoteDataSource _remote;

  @override
  Future<SandboxAttemptResults> getAttempt({
    required String attemptId,
    required String guestSessionId,
  }) =>
      _remote.getAttempt(attemptId: attemptId, guestSessionId: guestSessionId);
}

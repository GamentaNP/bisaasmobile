import '../entities/sandbox_attempt.dart';

/// Read boundary for a finished guest-sandbox result.
// ignore: one_member_abstracts — repository boundary per Clean Arch.
abstract class SandboxAttemptRepository {
  Future<SandboxAttemptResults> getAttempt({
    required String attemptId,
    required String guestSessionId,
  });
}

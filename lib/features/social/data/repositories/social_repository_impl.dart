import '../../domain/entities/social.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_data_source.dart';

class SocialRepositoryImpl implements SocialRepository {
  const SocialRepositoryImpl(this._remote);
  final SocialRemoteDataSource _remote;

  @override
  Future<ReferralDashboard?> getReferralDashboard() => _remote.getReferralDashboard();

  @override
  Future<ReferralClaim> claimReferralCode(String code) => _remote.claimReferralCode(code);

  @override
  Future<ShareMoment?> getMoment() => _remote.getMoment();

  @override
  Future<void> dismissMoment(String kind) => _remote.dismissMoment(kind);

  @override
  Future<void> recordShare({required String token, String? channel}) =>
      _remote.recordShare(token: token, channel: channel);

  @override
  Future<SocialProof?> getProof({required String subject, required int id}) =>
      _remote.getProof(subject: subject, id: id);

  @override
  Future<ShareLink> createShareLink({
    required String kind,
    int? subjectId,
    String? channel,
  }) async {
    final dto = await _remote.createShareLink(
      kind: kind,
      subjectId: subjectId,
      channel: channel,
    );
    return ShareLink(
      token: dto.token,
      url: dto.url,
      kind: dto.kind,
      expiresAt: dto.expiresAt,
      copyTitle: dto.copyTitle,
      copyBody: dto.copyBody,
    );
  }

  @override
  Future<SharedLink> resolveShare(String token) async {
    final dto = await _remote.resolveShare(token);
    return SharedLink(
      token: dto.token,
      kind: dto.kind,
      creatorName: dto.creatorName,
      expiresAt: dto.expiresAt,
      webLandingUrl: dto.webLandingUrl,
      sandboxAvailable: dto.sandboxAvailable,
    );
  }

  @override
  Future<SandboxAttempt> startSandbox({
    required String token,
    required String guestSessionId,
  }) async {
    final dto = await _remote.startSandbox(
      token: token,
      guestSessionId: guestSessionId,
    );
    return SandboxAttempt(
      attemptId: dto.attemptId,
      guestSessionId: dto.guestSessionId,
      questionCount: dto.questionCount,
    );
  }

  @override
  Future<SandboxAnswer> answerSandbox({
    required int attemptId,
    required int questionId,
    required String answer,
  }) async {
    final dto = await _remote.answerSandbox(
      attemptId: attemptId,
      questionId: questionId,
      answer: answer,
    );
    return SandboxAnswer(questionId: dto.questionId, isCorrect: dto.isCorrect);
  }

  @override
  Future<SandboxResult> completeSandbox(int attemptId) async {
    final dto = await _remote.completeSandbox(attemptId);
    return SandboxResult(
      score: dto.score,
      correct: dto.correct,
      wrong: dto.wrong,
      skipped: dto.skipped,
      total: dto.total,
    );
  }
}

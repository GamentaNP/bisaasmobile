import '../entities/social.dart';

/// Social growth reads and writes.
///
/// Server-authoritative: referral attribution, reward amounts, and whether a
/// share counted are all decided by the server. Nothing here grants a coin.
abstract class SocialRepository {
  /// Null when the payload was not understood, which is distinct from "you have
  /// no referrals".
  Future<ReferralDashboard?> getReferralDashboard();

  Future<ReferralClaim> claimReferralCode(String code);

  /// The share prompt the server picked for this user, or null when there is
  /// nothing to prompt.
  Future<ShareMoment?> getMoment();

  /// Tells the server the prompt was dismissed. The server validates `kind`.
  Future<void> dismissMoment(String kind);

  /// Fire-and-forget; failures are swallowed.
  ///
  /// The server identifies the share by its **token**, so the token of the
  /// link that was shared is required.
  Future<void> recordShare({required String token, String? channel});

  Future<SocialProof?> getProof({required String subject, required int id});

  /// Mints a tracked share link.
  ///
  /// [kind] is one of the server's share kinds (`achievement`, `quiz_result`,
  /// `streak`, `calculator`, `challenge`).
  Future<ShareLink> createShareLink({
    required String kind,
    int? subjectId,
    String? channel,
  });

  // ── Public share / guest sandbox ───────────────────────────────────────────

  /// Resolves an incoming share link.
  Future<SharedLink> resolveShare(String token);

  /// Starts a guest sandbox attempt bound to [guestSessionId].
  Future<SandboxAttempt> startSandbox({
    required String token,
    required String guestSessionId,
  });

  /// Answers one sandbox question.
  Future<SandboxAnswer> answerSandbox({
    required int attemptId,
    required int questionId,
    required String answer,
  });

  /// Completes the sandbox attempt and returns the server's result.
  Future<SandboxResult> completeSandbox(int attemptId);
}

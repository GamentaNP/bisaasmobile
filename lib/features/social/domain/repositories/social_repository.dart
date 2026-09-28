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

  /// Prompts the user has not dismissed.
  Future<List<ShareMoment>> getActiveMoments();

  Future<void> dismissMoment(String momentId);

  /// Fire-and-forget; failures are swallowed.
  Future<void> recordShare({String? subject, int? subjectId, String? channel});

  Future<SocialProof?> getProof({required String subject, required int id});

  /// Null when the server declined to mint a tracked link.
  Future<String?> createShareLink({String? subject, int? subjectId});
}

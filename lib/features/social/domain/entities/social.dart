/// Social growth domain entities.
///
/// Server-authoritative throughout: referral attribution, reward amounts and
/// statuses are computed by the server and rendered here. The client never
/// decides that a referral "counted", and never mints a reward.
library;

/// The user's referral dashboard.
///
/// ## Key casing
///
/// This payload is **camelCase** (`shareUrl`, `totalReferrals`,
/// `referredName`) while the rest of the API is snake_case. That is the server's
/// shape as built — `ReferralService::dashboardPayload()` returns a hand-written
/// array, not a Resource — so the DTO maps it exactly and normalises to
/// snake_case internally. Anything else here would silently read as null.
class ReferralDashboard {
  const ReferralDashboard({
    required this.code,
    required this.shareUrl,
    required this.referrerRewardCoins,
    required this.referredRewardCoins,
    required this.firstQuizRewardCoins,
    required this.stats,
    this.referrals = const [],
  });

  /// The user's own code, e.g. `BISA-7F3K`.
  final String code;

  /// Absolute share URL, already built by the server via `route('register')`.
  ///
  /// The server supplies it because the host differs per environment; building
  /// one on the client is how a share link ends up pointing at localhost.
  final String shareUrl;
  final int referrerRewardCoins;
  final int referredRewardCoins;
  final int firstQuizRewardCoins;
  final ReferralStats stats;
  final List<ReferralEntry> referrals;

  bool get hasAnyReferral => stats.totalReferrals > 0;
}

class ReferralStats {
  const ReferralStats({
    this.totalReferrals = 0,
    this.rewardedReferrals = 0,
    this.pendingReferrals = 0,
    this.firstQuizRewardedReferrals = 0,
    this.secondDegreeRewardedReferrals = 0,
    this.secondDegreeBonusCoins = 0,
    this.coinsEarned = 0,
  });

  final int totalReferrals;

  /// Referred users who have already been paid out. This is the number that
  /// means something to a user; the others are pipeline.
  final int rewardedReferrals;
  final int pendingReferrals;
  final int firstQuizRewardedReferrals;
  final int secondDegreeRewardedReferrals;
  final int secondDegreeBonusCoins;
  final int coinsEarned;
}

class ReferralEntry {
  const ReferralEntry({
    required this.id,
    this.referredName,
    required this.status,
    this.referrerRewardCoins = 0,
    this.referredRewardCoins = 0,
  });

  final int id;

  /// Absent if the referred account has since been deleted — the relation is
  /// `with('referredUser:id,name,email')`, so a null user yields a null name.
  /// Rendered as "A learner" rather than as a blank row.
  final String? referredName;
  final String status;
  final int referrerRewardCoins;
  final int referredRewardCoins;

  String get displayName {
    final n = referredName?.trim();
    return (n == null || n.isEmpty) ? 'A learner' : n;
  }

  bool get isRewarded => status.toLowerCase() == 'rewarded';
}

/// Result of `PUT /social/referral-code/claim`.
class ReferralClaim {
  const ReferralClaim({
    required this.claimed,
    required this.status,
    this.referrerRewardCoins = 0,
    this.referredRewardCoins = 0,
  });

  final bool claimed;
  final String status;
  final int referrerRewardCoins;
  final int referredRewardCoins;
}

/// A share prompt the server offers, e.g. "share your streak".
class ShareMoment {
  const ShareMoment({
    required this.id,
    required this.kind,
    required this.ctaLabel,
    this.title,
    this.rewardCoins = 0,
    this.dismissed = false,
  });

  final String id;

  /// Server enum, e.g. `streak`, `achievement`, `result`.
  final String kind;
  final String ctaLabel;
  final String? title;

  /// Only shown when the server attached one. A client-invented coin figure
  /// would be a promise the server does not make.
  final int rewardCoins;
  final bool dismissed;

  bool get hasReward => rewardCoins > 0;
}

/// A server-computed shareable proof about a subject.
class SocialProof {
  const SocialProof({
    required this.subject,
    required this.headline,
    this.statLabel,
    this.statValue,
    this.shareText,
  });

  /// `question` | `course` | `topic` | `calculator`
  final String subject;
  final String headline;
  final String? statLabel;
  final String? statValue;

  /// Server-authored copy. Preferred over anything the client composes, because
  /// the copy is what has been reviewed for accuracy.
  final String? shareText;

  bool get hasStat => statValue != null && statValue!.trim().isNotEmpty;
}

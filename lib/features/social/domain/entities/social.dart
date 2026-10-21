/// Social growth domain entities.
///
/// Server-authoritative throughout: referral attribution, reward amounts and
/// statuses are computed by the server and rendered here. The client never
/// decides that a referral "counted", and never mints a reward.
library;

import 'package:meta/meta.dart';

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
    this.priority = 0,
    this.dismissed = false,
  });

  /// The moment's identity.
  ///
  /// The server publishes `data.moment = {kind, priority}` — there is no
  /// separate id, so the kind *is* the identity. It is also what
  /// `POST /social/moments/dismissals` validates.
  final String id;

  /// Server enum, e.g. `streak`, `achievement`, `quiz_result`.
  final String kind;
  final String ctaLabel;
  final String? title;

  /// Only shown when the server attached one. A client-invented coin figure
  /// would be a promise the server does not make.
  final int rewardCoins;

  /// The server's priority tier — 1 wins the slot when the user has reached
  /// their prompt cap.
  final int priority;
  final bool dismissed;

  bool get hasReward => rewardCoins > 0;
}

/// A tracked share link the server minted.
class ShareLink {
  const ShareLink({
    required this.token,
    required this.url,
    this.kind,
    this.expiresAt,
    this.copyTitle,
    this.copyBody,
  });

  /// The opaque token. `POST /social/share-recorded` identifies the share by
  /// this token, and `GET /public/social/share/{token}` resolves it.
  final String token;

  /// The absolute URL the server built. The client never builds share URLs
  /// itself — the host differs per environment.
  final String url;
  final String? kind;
  final String? expiresAt;

  /// Server-authored copy. Preferred over anything the client composes,
  /// because the copy is what has been reviewed for accuracy.
  final String? copyTitle;
  final String? copyBody;

  /// The text to put in front of the share sheet.
  String get shareText {
    final title = copyTitle;
    final body = copyBody;
    if (title != null && body != null) return '$title\n$body';
    if (body != null) return body;
    if (title != null) return title;
    return 'Try this on CivilCal';
  }
}

/// An incoming share link, resolved from its token.
class SharedLink {
  const SharedLink({
    required this.token,
    this.kind,
    this.creatorName,
    this.expiresAt,
    this.webLandingUrl,
    this.sandboxAvailable = false,
  });

  final String token;
  final String? kind;

  /// The display name of the person who shared it.
  final String? creatorName;
  final String? expiresAt;
  final String? webLandingUrl;

  /// Whether the server will let a guest play the sandbox for this link.
  final bool sandboxAvailable;

  bool get isExpired {
    final raw = expiresAt;
    if (raw == null) return false;
    final at = DateTime.tryParse(raw);
    if (at == null) return false;
    return at.isBefore(DateTime.now());
  }
}

/// One answer choice of a sandbox question.
@immutable
class SandboxOption {
  const SandboxOption({required this.key, required this.text});

  final String key;
  final String text;
}

/// A question the guest is asked to answer.
@immutable
class SandboxQuestion {
  const SandboxQuestion({
    required this.id,
    required this.questionText,
    this.type,
    this.options = const [],
    this.difficulty,
    this.points = 0,
  });

  final int id;
  final String questionText;
  final String? type;
  final List<SandboxOption> options;
  final String? difficulty;
  final int points;

  bool get hasOptions => options.isNotEmpty;
}

/// A guest sandbox attempt — a playable attempt for a visitor with no account.
class SandboxAttempt {
  const SandboxAttempt({
    required this.attemptId,
    required this.guestSessionId,
    this.questionCount = 0,
    this.questions = const [],
  });

  final int attemptId;

  /// The client-generated session id the attempt is bound to.
  final String guestSessionId;
  final int questionCount;

  /// The questions the server picked, in the order it picked them.
  final List<SandboxQuestion> questions;

  bool get isPlayable => questions.isNotEmpty;
}

/// The server's verdict on one sandbox answer.
class SandboxAnswer {
  const SandboxAnswer({required this.questionId, this.isCorrect});

  final int questionId;

  /// Null means the question was skipped — the server publishes null rather
  /// than false, so null must not be rendered as "wrong".
  final bool? isCorrect;
}

/// The server's result for a completed sandbox attempt.
///
/// A sandbox attempt grants **zero** progression: no coins, no XP, no streak.
class SandboxResult {
  const SandboxResult({
    this.score = 0,
    this.correct = 0,
    this.wrong = 0,
    this.skipped = 0,
    this.total = 0,
  });

  final double score;
  final int correct;
  final int wrong;
  final int skipped;
  final int total;

  int get answered => correct + wrong;
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

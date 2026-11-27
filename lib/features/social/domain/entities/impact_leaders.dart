/// Pure Dart models for the bounded `GET /social/impact-leaders` snapshot.
///
/// The server ranks only qualified-and-retained referrals and hides users who
/// declined visibility. Score and rank are never recomputed on-device.
library;

class ImpactLeader {
  const ImpactLeader({
    required this.userId,
    required this.name,
    required this.score,
    required this.qualifiedReferrals,
  });

  final int userId;
  final String name;
  final int score;
  final int qualifiedReferrals;
}

class ImpactLeadersSnapshot {
  const ImpactLeadersSnapshot({
    required this.leaders,
    this.viewerRank,
  });

  final List<ImpactLeader> leaders;
  final int? viewerRank;
}

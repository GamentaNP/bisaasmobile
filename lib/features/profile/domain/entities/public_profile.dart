/// Pure Dart models for the two public-profile reads (§9.5).
///
/// The server owns every aggregate and the privacy gate; this module only
/// renders what it receives. A GET must not record a profile view locally.
library;

class ProfileCardData {
  const ProfileCardData({
    required this.username,
    required this.name,
    this.headline,
    this.bio,
    this.avatarUrl,
    this.level = 1,
    this.isOwner = false,
    this.isPublic = true,
  });

  final String username;
  final String name;
  final String? headline;
  final String? bio;
  final String? avatarUrl;
  final int level;
  final bool isOwner;
  final bool isPublic;
}

class ProfileStatsData {
  const ProfileStatsData({
    this.totalQuizzes = 0,
    this.completedQuizzes = 0,
    this.totalBattles = 0,
    this.averageScore = 0,
    this.accuracyPercent = 0,
  });

  final num totalQuizzes;
  final num completedQuizzes;
  final num totalBattles;
  final num averageScore;
  final num accuracyPercent;
}

class ProfileAchievementData {
  const ProfileAchievementData({
    required this.name,
    this.iconUrl,
    this.rarity,
    this.rewardCoins = 0,
    this.completedAt,
  });

  final String name;
  final String? iconUrl;
  final String? rarity;
  final int rewardCoins;
  final String? completedAt;
}

class PublicProfileSnapshot {
  const PublicProfileSnapshot({
    required this.profile,
    required this.stats,
    this.reputationScore,
    this.reputationTier,
    this.recentAchievements = const <ProfileAchievementData>[],
  });

  final ProfileCardData profile;
  final ProfileStatsData stats;
  final num? reputationScore;
  final String? reputationTier;
  final List<ProfileAchievementData> recentAchievements;
}

class CompactProfile {
  const CompactProfile({
    required this.username,
    required this.name,
    this.avatarUrl,
    this.level = 1,
    this.totalXp = 0,
  });

  final String username;
  final String name;
  final String? avatarUrl;
  final int level;
  final num totalXp;
}

class ComparisonRow {
  const ComparisonRow({
    required this.label,
    required this.viewer,
    required this.target,
    this.suffix,
  });

  final String label;
  final Object? viewer;
  final Object? target;
  final String? suffix;
}

class ProfileComparison {
  const ProfileComparison({
    required this.viewer,
    required this.target,
    required this.rows,
  });

  final CompactProfile viewer;
  final CompactProfile target;
  final List<ComparisonRow> rows;
}

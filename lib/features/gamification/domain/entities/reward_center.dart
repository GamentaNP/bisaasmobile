/// Pure Dart models for the bounded `GET /reward-center` snapshot (§9.5).
///
/// Coin balance, check-in state, spin eligibility and achievements are all
/// server-computed. This module renders statuses — it never computes a
/// balance, streak, prize or reward locally.
library;

class CheckInStatusData {
  const CheckInStatusData({
    this.claimedToday = false,
    this.streakDay = 0,
    this.todayReward = 0,
    this.nextReward = 0,
  });

  final bool claimedToday;
  final int streakDay;
  final int todayReward;
  final int nextReward;
}

class SpinPrizeData {
  const SpinPrizeData({
    required this.label,
    this.type,
    this.coins = 0,
    this.xp = 0,
    this.lifelineSlug,
    this.lifelineQuantity = 0,
    this.colorHex,
    this.rarity,
  });

  final String label;
  final String? type;
  final int coins;
  final int xp;
  final String? lifelineSlug;
  final int lifelineQuantity;
  final String? colorHex;
  final String? rarity;
}

class SpinStatusData {
  const SpinStatusData({
    this.canSpin = false,
    this.prizes = const <SpinPrizeData>[],
    this.nextSpinAt,
  });

  final bool canSpin;
  final List<SpinPrizeData> prizes;
  final String? nextSpinAt;
}

class RewardAchievementData {
  const RewardAchievementData({
    required this.key,
    required this.name,
    this.iconUrl,
    this.rarity,
    this.rewardCoins = 0,
    this.completedAt,
  });

  final String key;
  final String name;
  final String? iconUrl;
  final String? rarity;
  final int rewardCoins;
  final String? completedAt;
}

class RewardCenterSnapshot {
  const RewardCenterSnapshot({
    required this.checkIn,
    required this.spin,
    required this.balance,
    this.recentAchievements = const <RewardAchievementData>[],
  });

  final CheckInStatusData checkIn;
  final SpinStatusData spin;
  final int balance;
  final List<RewardAchievementData> recentAchievements;
}

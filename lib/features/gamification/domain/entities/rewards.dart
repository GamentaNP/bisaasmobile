/// Daily check-in and spin-wheel read models.
///
/// Pure Dart: colours are wire strings here and become a `Color` only in the
/// widget. Every reward amount, prize and eligibility flag comes from the
/// server - the client never decides what a spin or a check-in is worth.
library;

class CheckInStatus {
  const CheckInStatus({
    required this.claimedToday,
    required this.streakDay,
    required this.todayReward,
    required this.nextReward,
  });

  final bool claimedToday;
  final int streakDay;
  final int todayReward;

  /// Tomorrow's reward, so the UI can show the ladder without inventing it.
  final int nextReward;

  bool get canClaim => !claimedToday && todayReward > 0;
}

class CheckInResult {
  const CheckInResult({
    required this.credited,
    required this.amount,
    required this.newBalance,
    required this.streakDay,
    this.reason,
  });

  final bool credited;
  final int amount;
  final int newBalance;
  final int streakDay;
  final String? reason;
}

class SpinPrize {
  const SpinPrize({
    required this.type,
    required this.coins,
    required this.xp,
    required this.lifelineSlug,
    required this.lifelineQuantity,
    required this.label,
    required this.colorHex,
    required this.rarity,
  });

  final String type;
  final int coins;
  final int xp;
  final String? lifelineSlug;
  final int lifelineQuantity;
  final String label;

  /// `#RRGGBB` as published by the server. Presentation parses it.
  final String colorHex;
  final String rarity;
}

class SpinStatus {
  const SpinStatus({
    required this.canSpin,
    required this.prizes,
    this.nextSpinAt,
  });

  final bool canSpin;
  final List<SpinPrize> prizes;
  final DateTime? nextSpinAt;
}

class SpinResult {
  const SpinResult({
    required this.spun,
    required this.type,
    required this.coins,
    required this.xp,
    required this.lifelineSlug,
    required this.lifelineQuantity,
    required this.label,
    this.prizeIndex,
    this.newBalance,
    this.reason,
  });

  final bool spun;
  final String type;
  final int coins;
  final int xp;
  final String? lifelineSlug;
  final int lifelineQuantity;
  final String label;
  final int? prizeIndex;
  final int? newBalance;
  final String? reason;
}

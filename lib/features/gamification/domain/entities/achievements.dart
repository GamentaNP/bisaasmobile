/// Server-authored achievement catalog row, merged with this user's progress.
///
/// Neither completion nor progress is computed on the device: the bucket comes
/// from `GET /economy/achievements` and the counters from
/// `GET /me/achievements/progress`. Pure Dart — the rarity colour is a
/// presentation concern and lives on the screen.
class AchievementEntry {
  const AchievementEntry({
    required this.id,
    required this.key,
    required this.name,
    required this.rarity,
    required this.isCompleted,
    required this.progressCurrent,
    required this.progressTarget,
    this.completedAt,
  });

  final int id;
  final String key;
  final String name;
  final String rarity;
  final bool isCompleted;
  final int progressCurrent;
  final int progressTarget;
  final String? completedAt;
}

class AchievementsData {
  const AchievementsData({
    required this.achievements,
    required this.recentCount,
  });

  final List<AchievementEntry> achievements;

  /// Number of server-published recent unlocks. Shown as-is, never derived.
  final int recentCount;
}

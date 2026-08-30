import 'package:meta/meta.dart';

@immutable
class Streak {
  const Streak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
    this.streakMultiplier = 1.0,
    this.freezeCount = 0,
    this.freezeUsedAt,
    this.frozenUntil,
  });

  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final double streakMultiplier;
  final int freezeCount;
  final DateTime? freezeUsedAt;
  final DateTime? frozenUntil;

  bool get isActiveToday {
    if (lastActivityDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(lastActivityDate!.year, lastActivityDate!.month, lastActivityDate!.day);
    return today.difference(last).inDays == 0;
  }

  bool get isAtRisk {
    if (lastActivityDate == null) return currentStreak == 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(lastActivityDate!.year, lastActivityDate!.month, lastActivityDate!.day);
    final diff = today.difference(last).inDays;
    return diff == 1 && !isActiveToday;
  }

  Streak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    double? streakMultiplier,
    int? freezeCount,
    DateTime? freezeUsedAt,
    DateTime? frozenUntil,
  }) =>
      Streak(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastActivityDate: lastActivityDate ?? this.lastActivityDate,
        streakMultiplier: streakMultiplier ?? this.streakMultiplier,
        freezeCount: freezeCount ?? this.freezeCount,
        freezeUsedAt: freezeUsedAt ?? this.freezeUsedAt,
        frozenUntil: frozenUntil ?? this.frozenUntil,
      );
}

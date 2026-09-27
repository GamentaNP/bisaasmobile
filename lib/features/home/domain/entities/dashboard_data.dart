import 'package:meta/meta.dart';

/// Aggregated home dashboard, merged from `GET /me`, `/quiz/streak`,
/// `/quiz/daily` and `/learning/today`.
///
/// The daily-quiz reward fields are **nullable on purpose**: `GET /quiz/daily`
/// returns the schedule row and `has_completed`, and that row carries no XP or
/// coin figure. The UI must therefore be able to say "we do not know the
/// reward" and hide the number, rather than print a plausible-looking one.
@immutable
class DashboardData {
  const DashboardData({
    required this.streakDays,
    required this.isDailyCompleted,
    required this.dailyQuizScheduled,
    required this.dailyQuizTitle,
    required this.dailyQuizQuestionsCount,
    required this.dailyQuizXpReward,
    required this.dailyQuizCoinsReward,
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
    required this.coinsBalance,
    required this.activeCourseTitle,
    required this.activeCourseProgress,
  });

  final int streakDays;
  final bool isDailyCompleted;

  /// The server has a daily quiz scheduled for today. `false` means the card
  /// must say so — not imply a quiz exists.
  final bool dailyQuizScheduled;

  final String? dailyQuizTitle;
  final int dailyQuizQuestionsCount;

  /// `null` = the server did not state a reward; render nothing.
  final int? dailyQuizXpReward;

  /// `null` = the server did not state a reward; render nothing.
  final int? dailyQuizCoinsReward;

  final int level;
  final int currentXp;

  /// `null` = the server did not publish a threshold; render no progress bar
  /// rather than an invented one.
  final int? nextLevelXp;

  final int coinsBalance;
  final String? activeCourseTitle;
  final double activeCourseProgress;
}

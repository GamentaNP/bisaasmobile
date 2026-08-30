import 'package:meta/meta.dart';

@immutable
class DashboardData {
  const DashboardData({
    required this.streakDays,
    required this.isDailyCompleted,
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
  final String dailyQuizTitle;
  final int dailyQuizQuestionsCount;
  final int dailyQuizXpReward;
  final int dailyQuizCoinsReward;
  final int level;
  final int currentXp;
  final int nextLevelXp;
  final int coinsBalance;
  final String? activeCourseTitle;
  final double activeCourseProgress;
}

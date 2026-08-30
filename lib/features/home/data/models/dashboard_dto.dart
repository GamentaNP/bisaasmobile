import '../../domain/entities/dashboard_data.dart';

class DashboardDto {
  const DashboardDto({
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
    this.activeCourseTitle,
    this.activeCourseProgress = 0.0,
  });

  factory DashboardDto.fromJson(Map<String, dynamic> json) {
    final streak = json['streak'] as Map<String, dynamic>?;
    final daily = json['daily_quiz'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    final course = json['active_course'] as Map<String, dynamic>?;

    return DashboardDto(
      streakDays: (streak?['current_streak'] as int?) ?? (json['streak_days'] as int?) ?? 0,
      isDailyCompleted: (daily?['completed'] as bool?) ?? (json['is_daily_completed'] as bool?) ?? false,
      dailyQuizTitle: (daily?['title'] as String?) ?? 'Civil Engineering Daily Sprint',
      dailyQuizQuestionsCount: (daily?['questions_count'] as int?) ?? 10,
      dailyQuizXpReward: (daily?['xp_reward'] as int?) ?? 150,
      dailyQuizCoinsReward: (daily?['coins_reward'] as int?) ?? 25,
      level: (user?['level'] as int?) ?? (json['level'] as int?) ?? 1,
      currentXp: (user?['xp'] as int?) ?? (json['current_xp'] as int?) ?? 0,
      nextLevelXp: (user?['next_level_xp'] as int?) ?? (json['next_level_xp'] as int?) ?? 1000,
      coinsBalance: (user?['coins'] as int?) ?? (json['coins_balance'] as int?) ?? 0,
      activeCourseTitle: (course?['title'] as String?) ?? 'Structural Analysis & Design',
      activeCourseProgress: (course?['progress'] as num?)?.toDouble() ?? 0.35,
    );
  }

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

  DashboardData toDomain() => DashboardData(
        streakDays: streakDays,
        isDailyCompleted: isDailyCompleted,
        dailyQuizTitle: dailyQuizTitle,
        dailyQuizQuestionsCount: dailyQuizQuestionsCount,
        dailyQuizXpReward: dailyQuizXpReward,
        dailyQuizCoinsReward: dailyQuizCoinsReward,
        level: level,
        currentXp: currentXp,
        nextLevelXp: nextLevelXp,
        coinsBalance: coinsBalance,
        activeCourseTitle: activeCourseTitle,
        activeCourseProgress: activeCourseProgress,
      );
}

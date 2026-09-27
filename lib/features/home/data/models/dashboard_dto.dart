import '../../domain/entities/dashboard_data.dart';

/// Single mapper for the merged home payload.
///
/// Honesty rules encoded here, because this is the one DTO that used to invent
/// values on the error path:
///  * No fabricated daily title. `GET /quiz/daily` returns the schedule row
///    under `schedule` and may return `null`; when there is no schedule the
///    title stays `null` and the UI says so.
///  * `isDailyCompleted` comes from the server's real `has_completed` flag.
///  * Daily XP/coin rewards are nullable — the server does not publish them, so
///    the UI hides the figure instead of showing a made-up one.
///  * `nextLevelXp` is nullable for the same reason (it was hardcoded to 1000
///    here and 100 in the offline fallback, contradicting itself).
class DashboardDto {
  const DashboardDto({
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
    this.activeCourseTitle,
    this.activeCourseProgress = 0.0,
  });

  factory DashboardDto.fromJson(Map<String, dynamic> json) {
    final streak = json['streak'] as Map<String, dynamic>?;
    final daily = json['daily_quiz'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    final course = json['active_course'] as Map<String, dynamic>?;

    return DashboardDto(
      streakDays: _int(streak?['current_streak']) ?? _int(json['streak_days']) ?? 0,
      isDailyCompleted:
          _bool(daily?['completed']) ?? _bool(json['is_daily_completed']) ?? false,
      dailyQuizScheduled: _bool(daily?['scheduled']) ?? daily != null,
      dailyQuizTitle: daily?['title'] as String? ?? json['daily_quiz_title'] as String?,
      dailyQuizQuestionsCount:
          _int(daily?['questions_count']) ?? _int(json['daily_quiz_questions_count']) ?? 0,
      dailyQuizXpReward: _int(daily?['xp_reward']) ?? _int(json['daily_quiz_xp_reward']),
      dailyQuizCoinsReward: _int(daily?['coins_reward']) ?? _int(json['daily_quiz_coin_reward']),
      level: _int(user?['level']) ?? _int(json['level']) ?? 1,
      currentXp: _int(user?['xp']) ?? _int(json['current_xp']) ?? 0,
      nextLevelXp: _int(user?['next_level_xp']) ?? _int(json['next_level_xp']),
      coinsBalance: _int(user?['coins']) ?? _int(json['coins_balance']) ?? 0,
      activeCourseTitle: course?['title'] as String? ?? json['active_course_title'] as String?,
      activeCourseProgress:
          _double(course?['progress']) ?? _double(json['active_course_progress']) ?? 0.0,
    );
  }

  static int? _int(Object? v) => v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);
  static double? _double(Object? v) => v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
  static bool? _bool(Object? v) => v is bool ? v : (v == 1 || v == '1' ? true : null);

  final int streakDays;
  final bool isDailyCompleted;
  final bool dailyQuizScheduled;
  final String? dailyQuizTitle;
  final int dailyQuizQuestionsCount;
  final int? dailyQuizXpReward;
  final int? dailyQuizCoinsReward;
  final int level;
  final int currentXp;
  final int? nextLevelXp;
  final int coinsBalance;
  final String? activeCourseTitle;
  final double activeCourseProgress;

  DashboardData toDomain() => DashboardData(
        streakDays: streakDays,
        isDailyCompleted: isDailyCompleted,
        dailyQuizScheduled: dailyQuizScheduled,
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

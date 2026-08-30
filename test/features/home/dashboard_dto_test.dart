import 'package:bisaasmobile/features/home/data/models/dashboard_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DashboardDto fromJson merges streak/daily/user', () {
    final dto = DashboardDto.fromJson({
      'streak': {'current_streak': 7},
      'daily_quiz': {'title': 'Daily', 'questions_count': 12, 'xp_reward': 200, 'coins_reward': 30, 'completed': false},
      'user': {'level': 5, 'xp': 420, 'coins': 150, 'next_level_xp': 600},
      'active_course': {'title': 'Soil', 'progress': 0.5},
    });
    expect(dto.streakDays, 7);
    expect(dto.dailyQuizTitle, 'Daily');
    expect(dto.level, 5);
    expect(dto.coinsBalance, 150);
    expect(dto.activeCourseProgress, 0.5);
    expect(dto.toDomain().streakDays, 7);
  });

  test('DashboardDto fallback defaults when empty', () {
    final dto = DashboardDto.fromJson({});
    expect(dto.streakDays, 0);
    expect(dto.level, 1);
    expect(dto.coinsBalance, 0);
  });

  test('DashboardDto handles flat keys', () {
    final dto = DashboardDto.fromJson({
      'streak_days': 3,
      'is_daily_completed': true,
      'level': 2,
      'current_xp': 100,
      'next_level_xp': 300,
      'coins_balance': 20,
    });
    expect(dto.streakDays, 3);
    expect(dto.isDailyCompleted, true);
  });
}

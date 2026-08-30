import 'package:bisaasmobile/features/streak/data/models/streak_dto.dart';
import 'package:bisaasmobile/features/streak/domain/entities/streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StreakDto', () {
    test('fromJson tolerant minimal', () {
      final dto = StreakDto.fromJson({'current_streak': 5, 'longest_streak': 10});
      expect(dto.currentStreak, 5);
      expect(dto.longestStreak, 10);
      expect(dto.streakMultiplier, 1.0);
      expect(dto.lastActivityDate, isNull);
      expect(dto.toDomain(), isA<Streak>());
    });

    test('fromJson full with dates and multiplier', () {
      final dto = StreakDto.fromJson({
        'current_streak': 7,
        'longest_streak': 30,
        'last_activity_date': '2026-08-30T00:00:00Z',
        'streak_multiplier': 1.5,
        'streak_freeze_count': 2,
        'streak_frozen_until': '2026-09-30T00:00:00Z',
      });
      expect(dto.currentStreak, 7);
      expect(dto.streakMultiplier, 1.5);
      expect(dto.lastActivityDate, isNotNull);
      expect(dto.freezeCount, 2);
      expect(dto.frozenUntil, isNotNull);
      expect(dto.toDomain().streakMultiplier, 1.5);
    });

    test('fromJson handles string numbers tolerant', () {
      final dto = StreakDto.fromJson({'current_streak': '12', 'longest_streak': '15', 'streak_multiplier': '2.0'});
      expect(dto.currentStreak, 12);
      expect(dto.longestStreak, 15);
      expect(dto.streakMultiplier, 2.0);
    });

    test('additive tolerant ignores unknown fields', () {
      final dto = StreakDto.fromJson({'current_streak': 3, 'longest_streak': 3, 'new_future_field': {'nested': true}, 'extra': 123});
      expect(dto.currentStreak, 3);
    });

    test('handles camelCase fallback', () {
      final dto = StreakDto.fromJson({'currentStreak': 9, 'longestStreak': 20, 'lastActivityDate': '2026-08-29T00:00:00Z'});
      expect(dto.currentStreak, 9);
      expect(dto.longestStreak, 20);
    });

    test('FreezeStreakDto fromJson tolerant', () {
      final dto = FreezeStreakDto.fromJson({'frozen': true, 'frozen_until': '2026-09-30T00:00:00Z'});
      expect(dto.frozen, true);
      expect(dto.frozenUntil, isNotNull);
      final dto2 = FreezeStreakDto.fromJson({'data': {'frozen': true}});
      expect(dto2.frozen, true);
    });

    test('isActiveToday and isAtRisk logic', () {
      final now = DateTime.now();
      final todayStr = DateTime(now.year, now.month, now.day).toIso8601String();
      final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      final dtoToday = StreakDto.fromJson({'current_streak': 5, 'longest_streak': 10, 'last_activity_date': todayStr});
      expect(dtoToday.toDomain().isActiveToday, isTrue);
      final dtoYesterday = StreakDto.fromJson({'current_streak': 5, 'longest_streak': 10, 'last_activity_date': yesterday.toIso8601String()});
      expect(dtoYesterday.toDomain().isAtRisk, isTrue);
    });
  });
}

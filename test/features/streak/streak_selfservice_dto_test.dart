import 'package:bisaasmobile/features/streak/data/models/streak_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// DTO coverage for the streak self-service cluster
/// (`/quiz/streak/repair`, `/quiz/streak/insurance`, `/quiz/streak/wager`).
///
/// The server is inconsistent on casing here, exactly as documented in
/// `bisaas/routes/api/v1/quiz.php:264-295`:
///   * `GET /quiz/streak`            -> snake_case
///   * `GET /quiz/streak/repair`     -> camelCase
///   * `GET /quiz/streak/insurance`  -> camelCase
///   * `POST .../repair`             -> snake_case (`cost_coins`, `coin_balance`)
///   * `POST .../insurance`          -> snake_case (`active_insurance_count`)
void main() {
  group('StreakInsuranceStatusDto', () {
    test('parses GET /quiz/streak/insurance (camelCase)', () {
      final dto = StreakInsuranceStatusDto.fromJson(const {
        'activeCount': 1,
        'maxActive': 3,
        'costCoins': 200,
        'canPurchase': true,
      });
      expect(dto.activeCount, 1);
      expect(dto.maxActive, 3);
      expect(dto.costCoins, 200);
      expect(dto.canPurchase, isTrue);
    });

    test('also accepts the snake_case spelling', () {
      final dto = StreakInsuranceStatusDto.fromJson(const {
        'active_count': 0,
        'max_active': 3,
        'cost_coins': 200,
        'can_purchase': false,
      });
      expect(dto.activeCount, 0);
      expect(dto.maxActive, 3);
      expect(dto.costCoins, 200);
    });

    test('defaults to cannot-purchase rather than assuming funds', () {
      final dto = StreakInsuranceStatusDto.fromJson(const {});
      expect(dto.activeCount, 0);
      expect(dto.costCoins, 0);
      expect(dto.canPurchase, isFalse);
    });
  });

  group('StreakInsuranceResultDto', () {
    test('parses POST /quiz/streak/insurance (snake_case)', () {
      final dto = StreakInsuranceResultDto.fromJson(const {
        'active_insurance_count': 2,
        'cost_coins': 200,
        'coin_balance': 340,
      });
      expect(dto.activeInsuranceCount, 2);
      expect(dto.coinBalance, 340);
    });
  });

  group('StreakInsuranceUsedDto', () {
    test('parses POST /quiz/streak/insurance/use', () {
      final dto = StreakInsuranceUsedDto.fromJson(const {
        'streak': {'current_streak': 9, 'longest_streak': 21},
        'active_insurance_count': 0,
      });
      expect(dto.used, isTrue);
      expect(dto.streak, isNotNull);
      expect(dto.streak!.currentStreak, 9);
      expect(dto.streak!.longestStreak, 21);
      expect(dto.activeInsuranceCount, 0);
    });

    test('reports not-used when the server omits the streak object', () {
      final dto = StreakInsuranceUsedDto.fromJson(const {'active_insurance_count': 2});
      expect(dto.used, isFalse);
      expect(dto.activeInsuranceCount, 2);
    });
  });

  group('StreakRepairEligibilityDto', () {
    test('parses GET /quiz/streak/repair (camelCase)', () {
      final dto = StreakRepairEligibilityDto.fromJson(const {
        'eligible': true,
        'missedDate': '2026-09-20',
        'expiresAt': '2026-09-22T00:00:00+05:45',
        'repairsUsedThisMonth': 1,
      });
      expect(dto.eligible, isTrue);
      expect(dto.missedDate, isNotNull);
      expect(dto.expiresAt, isNotNull);
      expect(dto.repairsUsedThisMonth, 1);
    });

    test('carries the refusal reason the server gives', () {
      final dto = StreakRepairEligibilityDto.fromJson(const {
        'eligible': false,
        'reason': 'monthly_repair_limit_reached',
        'repairsUsedThisMonth': 3,
      });
      expect(dto.eligible, isFalse);
      expect(dto.reason, 'monthly_repair_limit_reached');
      expect(dto.repairsUsedThisMonth, 3);
    });

    test('not-eligible is the safe default', () {
      expect(StreakRepairEligibilityDto.fromJson(const {}).eligible, isFalse);
    });
  });

  group('StreakRepairResultDto', () {
    test('parses a successful repair with the refreshed streak', () {
      final dto = StreakRepairResultDto.fromJson(const {
        'streak': {'current_streak': 12, 'longest_streak': 30},
        'cost_coins': 50,
        'coin_balance': 90,
      });
      expect(dto.repaired, isTrue);
      expect(dto.currentStreak, 12);
      expect(dto.coinBalance, 90);
    });
  });

  group('StreakWagerStatusDto', () {
    test('parses an active wager (camelCase aggregate + progressPercent)', () {
      final dto = StreakWagerStatusDto.fromJson(const {
        'wager': {
          'status': 'active',
          'coins': 250,
          'days': 7,
          'target': 7,
          'current': 3,
          'progressPercent': 43,
          'reward': 500,
        },
        'currentStreak': 3,
      });
      expect(dto.currentStreak, 3);
      final wager = dto.wager!;
      expect(wager.coins, 250);
      expect(wager.days, 7);
      expect(wager.current, 3);
      expect(wager.progressPercent, 43);
      expect(wager.reward, 500);
    });

    test('null wager when none is active', () {
      final dto = StreakWagerStatusDto.fromJson(const {'wager': null, 'currentStreak': 4});
      expect(dto.wager, isNull);
      expect(dto.currentStreak, 4);
    });
  });

  group('StreakWagerOpenedDto', () {
    test('parses the POST result (snake_case balance + nested wager)', () {
      final dto = StreakWagerOpenedDto.fromJson(const {
        'wager': {'coins': 100, 'days': 7, 'target': 7, 'current': 0, 'reward': 200},
        'coin_balance': 400,
      });
      expect(dto.opened, isTrue);
      expect(dto.coinBalance, 400);
      expect(dto.wager!.coins, 100);
    });
  });
}

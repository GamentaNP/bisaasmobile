import 'package:bisaasmobile/features/contests/data/models/contest_dto.dart';
import 'package:bisaasmobile/features/contests/domain/entities/contest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContestDto', () {
    test('fromJson minimal', () {
      final dto = ContestDto.fromJson({'id': 1, 'title': 'Weekly Clash', 'status': 'active', 'entry_fee_coins': 10, 'prize_pool_coins': 100});
      expect(dto.id, 1);
      expect(dto.title, 'Weekly Clash');
      expect(dto.status, 'active');
      expect(dto.entryFeeCoins, 10);
      expect(dto.prizePoolCoins, 100);
      expect(dto.toDomain(), isA<Contest>());
      expect(dto.toDomain().isActive, isTrue);
      expect(dto.toDomain().isFree, isFalse);
    });

    test('fromJson with dates and free', () {
      final dto = ContestDto.fromJson({
        'id': 2,
        'title': 'Free Contest',
        'status': 'upcoming',
        'entry_fee_coins': 0,
        'prize_pool_coins': 500,
        'starts_at': '2026-09-01T10:00:00Z',
        'ends_at': '2026-09-02T10:00:00Z',
        'max_participants': 100,
      });
      expect(dto.toDomain().isFree, isTrue);
      expect(dto.toDomain().isUpcoming, isTrue);
      expect(dto.startsAt, isNotNull);
      expect(dto.maxParticipants, 100);
    });

    test('handles string numbers', () {
      final dto = ContestDto.fromJson({'id': '3', 'title': 'T', 'status': 'ended', 'entry_fee_coins': '50', 'prize_pool_coins': '200'});
      expect(dto.id, 3);
      expect(dto.entryFeeCoins, 50);
      expect(dto.toDomain().isEnded, isTrue);
    });

    test('additive tolerant ignores unknown', () {
      final dto = ContestDto.fromJson({'id': 7, 'title': 'T', 'status': 'active', 'entry_fee_coins': 10, 'prize_pool_coins': 0, 'future_field': 123, 'extra': {'nested': true}});
      expect(dto.id, 7);
    });
  });

  group('ContestEntryDto', () {
    test('fromJson flat', () {
      final dto = ContestEntryDto.fromJson({'id': 5, 'quiz_contest_id': 1, 'user_id': 42, 'score': 85.5, 'completed': true, 'rank': 2, 'display_name': 'Ram'});
      expect(dto.id, 5);
      expect(dto.score, 85.5);
      expect(dto.rank, 2);
      expect(dto.toDomain(), isA<ContestEntry>());
    });

    test('fromJson with nested user', () {
      final dto = ContestEntryDto.fromJson({'id': 6, 'quiz_contest_id': 1, 'user_id': 7, 'score': 90, 'user': {'name': 'Sita'}});
      expect(dto.displayName, 'Sita');
    });
  });

  group('ContestDetailDto', () {
    test('fromJson with contest and leaderboard', () {
      final dto = ContestDetailDto.fromJson({
        'contest': {'id': 10, 'title': 'Final', 'status': 'active', 'entry_fee_coins': 10, 'prize_pool_coins': 1000},
        'is_registered': true,
        'leaderboard': [
          {'id': 1, 'quiz_contest_id': 10, 'user_id': 1, 'score': 100, 'completed': true},
        ],
        'leaderboard_meta': {'cached': true, 'refreshed': false, 'generated_at': '2026-08-30T10:00:00Z', 'refresh_budget_remaining': 5},
      });
      expect(dto.contest.title, 'Final');
      expect(dto.isRegistered, isTrue);
      expect(dto.leaderboard.length, 1);
      expect(dto.leaderboardMeta?.cached, isTrue);
      expect(dto.toDomain().isRegistered, isTrue);
    });

    test('tolerant when contest is flat', () {
      final dto = ContestDetailDto.fromJson({'id': 11, 'title': 'Flat', 'status': 'upcoming', 'entry_fee_coins': 0, 'prize_pool_coins': 0});
      expect(dto.contest.id, 11);
    });
  });

  group('ContestAttemptDto', () {
    test('fromJson', () {
      final dto = ContestAttemptDto.fromJson({'attempt_id': 99, 'expires_at': '2026-09-01T12:00:00Z', 'server_now': '2026-09-01T10:00:00Z'});
      expect(dto.attemptId, 99);
      expect(dto.expiresAt, isNotNull);
      expect(dto.toDomain(), isA<ContestAttempt>());
    });

    test('handles string attempt_id', () {
      final dto = ContestAttemptDto.fromJson({'attempt_id': '123'});
      expect(dto.attemptId, 123);
    });
  });

  group('ContestRecapDto', () {
    test('fromJson tolerant', () {
      final dto = ContestRecapDto.fromJson({'title': 'Recap', 'summary': 'Great contest', 'winners': []});
      expect(dto.toDomain().title, 'Recap');
      expect(dto.toDomain().summary, 'Great contest');
    });
  });
}

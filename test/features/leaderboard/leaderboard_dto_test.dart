import 'package:bisaasmobile/features/leaderboard/data/models/leaderboard_dto.dart';
import 'package:bisaasmobile/features/leaderboard/domain/entities/leaderboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LeaderboardDto', () {
    test('fromJson minimal', () {
      final dto = LeaderboardDto.fromJson({'id': 1, 'name': 'Global Weekly'});
      expect(dto.id, 1);
      expect(dto.name, 'Global Weekly');
      expect(dto.period, 'all_time');
      expect(dto.scope, 'global');
      expect(dto.toDomain(), isA<Leaderboard>());
    });

    test('fromJson full with period/scope', () {
      final dto = LeaderboardDto.fromJson({'id': 2, 'name': 'Friends', 'period': 'weekly', 'scope': 'friends', 'scope_id': 5, 'is_active': true});
      expect(dto.period, 'weekly');
      expect(dto.scope, 'friends');
      expect(dto.scopeId, 5);
    });

    test('additive tolerant ignores unknown', () {
      final dto = LeaderboardDto.fromJson({'id': 3, 'name': 'X', 'new_field': 123, 'extra': {'nested': true}});
      expect(dto.id, 3);
    });
  });

  group('LeaderboardEntryDto', () {
    test('fromJson flat', () {
      final dto = LeaderboardEntryDto.fromJson({'rank': 1, 'score': 950, 'user_id': 42, 'display_name': 'Ram'});
      expect(dto.rank, 1);
      expect(dto.score, 950);
      expect(dto.userId, 42);
      expect(dto.displayName, 'Ram');
      expect(dto.toDomain().isMe, isFalse);
    });

    test('fromJson with nested user', () {
      final dto = LeaderboardEntryDto.fromJson({'rank': 2, 'score': 800, 'user': {'id': 7, 'name': 'Sita', 'avatar': 'url'}});
      expect(dto.userId, 7);
      expect(dto.displayName, 'Sita');
      expect(dto.avatar, 'url');
    });

    test('handles string score/int', () {
      final dto = LeaderboardEntryDto.fromJson({'rank': '3', 'score': '750.5', 'user_id': '9'});
      expect(dto.rank, 3);
      expect(dto.score, 750.5);
      expect(dto.userId, 9);
    });
  });

  group('MyRankDto', () {
    test('listFromJson my-rank shape', () {
      final list = MyRankDto.listFromJson([
        {'id': 1, 'name': 'Global', 'period': 'all_time', 'scope': 'global', 'entries': [{'rank': 42, 'score': 1234}]},
        {'id': 2, 'name': 'Weekly', 'period': 'weekly', 'scope': 'global', 'entries': []},
      ]);
      expect(list.length, 2);
      expect(list.first.rank, 42);
      expect(list.first.score, 1234);
      expect(list.first.leaderboard.name, 'Global');
      expect(list.last.rank, isNull);
    });

    test('handles empty list', () {
      final list = MyRankDto.listFromJson([]);
      expect(list, isEmpty);
    });
  });

  group('DonorLeaderboardEntryDto', () {
    test('fromJson minimal', () {
      final dto = DonorLeaderboardEntryDto.fromJson({'donorName': 'Hari', 'badge': 'gold', 'badgeLabel': 'Gold', 'badgeColor': '#FFD700', 'totalDonatedFormatted': r'$25.00'});
      expect(dto.donorName, 'Hari');
      expect(dto.totalDonatedFormatted, r'$25.00');
      expect(dto.toDomain(), isA<DonorLeaderboardEntry>());
    });

    test('fromJson snake_case tolerant', () {
      final dto = DonorLeaderboardEntryDto.fromJson({'donor_name': 'Gita', 'badge': 'silver', 'badge_label': 'Silver', 'badge_color': '#C0C0C0', 'total_donated_formatted': r'$10.00', 'streak_months': 3});
      expect(dto.donorName, 'Gita');
      expect(dto.streakMonths, 3);
    });

    test('additive ignores unknown', () {
      final dto = DonorLeaderboardEntryDto.fromJson({'donorName': 'X', 'badge': 'bronze', 'badgeLabel': 'Bronze', 'badgeColor': '#CD7F32', 'totalDonatedFormatted': r'$1.00', 'new_field': 123});
      expect(dto.donorName, 'X');
    });
  });
}

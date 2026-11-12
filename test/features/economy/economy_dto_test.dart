import 'package:bisaasmobile/features/economy/data/models/economy_dto.dart';
import 'package:bisaasmobile/features/economy/domain/entities/economy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WalletDto & LedgerEntryDto', () {
    test('WalletDto fromJson minimal tolerant', () {
      final dto = WalletDto.fromJson({'coins': 250});
      expect(dto.coins, 250);
      expect(dto.toDomain().coins, 250);
    });

    test('WalletDto handles string coins and extra field', () {
      final dto = WalletDto.fromJson({'coins': '300', 'extra': 'ignored'});
      expect(dto.coins, 300);
    });

    test(
      'LedgerEntryDto fromJson uses description as sourceLabel per AGENTS 155',
      () {
        final dto = LedgerEntryDto.fromJson({
          'amount': 10,
          'description': 'quiz_correct',
          'created_at': '2026-08-30T10:00:00Z',
          'metadata': {'source': 'should_be_ignored'},
        });
        expect(dto.sourceLabel, 'quiz_correct');
        expect(dto.amount, 10);
        expect(dto.direction, 'credit');
        expect(dto.toDomain(), isA<LedgerEntry>());
        // Verify we did NOT read metadata.source
        expect(dto.metadata?['source'], 'should_be_ignored');
        expect(dto.sourceLabel, isNot('should_be_ignored'));
      },
    );

    test('LedgerEntryDto handles debit via negative string amount', () {
      final dto = LedgerEntryDto.fromJson({
        'amount': '-25',
        'description': 'store_purchase',
        'created_at': '2026-08-30T10:00:00Z',
      });
      expect(dto.amount, 25); // abs
      expect(dto.direction, 'debit');
    });

    test('LedgerEntryDto additive ignores new fields', () {
      final dto = LedgerEntryDto.fromJson({
        'amount': 5,
        'description': 'x',
        'new_field': 123,
        'bonus': true,
      });
      expect(dto.amount, 5);
    });
  });

  group('WalletCategoriesDto', () {
    test('parses the keyed category map and totals', () {
      final dto = WalletCategoriesDto.fromJson({
        'period': {'days': 30},
        'categories': {
          'daily_checkin': {
            'label': 'Daily check-in',
            'coins': 120,
            'entries': 4,
          },
          'quiz_achievement': {
            'label': 'Quiz rewards',
            'coins': -50,
            'entries': 1,
          },
        },
        'totals': {'earned': 120, 'spent': -50},
      });
      expect(dto.categories.length, 2);
      expect(dto.earned, 120);
      expect(dto.spent, -50);
      expect(dto.periodDays, 30);
      final domain = dto.toDomain();
      expect(domain.categories.first.label, 'Daily check-in');
      expect(domain.spentAbsolute, 50);
    });
  });

  group('Donation DTOs', () {
    test('DonorLeaderboardEntryDto tolerant snake/camel', () {
      final dto = DonorLeaderboardEntryDto.fromJson({
        'donorName': 'Ram',
        'badge': 'gold',
        'totalDonatedFormatted': '\$10.00',
        'streakMonths': 3,
      });
      expect(dto.donorName, 'Ram');
      expect(dto.toDomain(), isA<DonorLeaderboardEntry>());
      final dto2 = DonorLeaderboardEntryDto.fromJson({
        'donor_name': 'Sita',
        'badge': 'silver',
        'total_donated_formatted': '\$5.00',
      });
      expect(dto2.donorName, 'Sita');
    });

    test('DonationFeedEntryDto minimal', () {
      final dto = DonationFeedEntryDto.fromJson({
        'id': 1,
        'displayName': 'A',
        'amountFormatted': '\$2.00',
      });
      expect(dto.id, 1);
      expect(dto.toDomain(), isA<DonationFeedEntry>());
    });

    test('FreezeStreakResultDto fromJson', () {
      final dto = FreezeStreakResultDto.fromJson({
        'frozen': true,
        'message': 'ok',
      });
      expect(dto.frozen, true);
      expect(dto.toDomain().frozen, true);
    });

    test('additive fields never crash', () {
      final dto = DonorLeaderboardEntryDto.fromJson({
        'donorName': 'X',
        'badge': 'b',
        'new_future': 'ignored',
        'anotherNested': {'a': 1},
      });
      expect(dto.donorName, 'X');
      final feed = DonationFeedEntryDto.fromJson({
        'id': 9,
        'displayName': 'Y',
        'future': 123,
      });
      expect(feed.displayName, 'Y');
    });
  });

  group('WalletLedger grouping', () {
    test('groupedByDay works across days', () {
      final ledger = WalletLedger(
        entries: [
          LedgerEntry(
            amount: 10,
            direction: 'credit',
            sourceLabel: 'quiz',
            description: 'quiz',
            createdAt: DateTime(2026, 8, 30),
          ),
          LedgerEntry(
            amount: 5,
            direction: 'credit',
            sourceLabel: 'quiz',
            description: 'quiz',
            createdAt: DateTime(2026, 8, 30, 12),
          ),
          LedgerEntry(
            amount: 20,
            direction: 'debit',
            sourceLabel: 'shop',
            description: 'shop',
            createdAt: DateTime(2026, 8, 29),
          ),
        ],
      );
      expect(ledger.groupedByDay.length, 2);
      expect(ledger.groupedByDay['2026-08-30']!.length, 2);
      expect(ledger.groupedByDay['2026-08-29']!.length, 1);
    });
  });

  group('LedgerEntryDto (live WO-1 shape)', () {
    test('parses server row: balance-delta amount, deposit direction, projection label', () {
      final dto = LedgerEntryDto.fromJson({
        'id': 44,
        'event_key': 'quiz_achievement:abc',
        'coins': 5,
        'balance_before': 10,
        'balance_after': 15,
        'meta': {
          'economy_idempotency_key': 'quiz_achievement:494:first_correct',
          'projection_source': 'bavix_wallet_transaction',
          'projection_label': 'quiz_achievement',
          'bavix_transaction_type': 'deposit',
        },
        'created_at': '2026-08-31T05:10:26+05:45',
      });
      expect(dto.amount, 5);
      expect(dto.direction, 'credit');
      expect(dto.sourceLabel, 'quiz_achievement');
      expect(dto.id, '44');
    });

    test('debit derived from negative balance movement', () {
      final dto = LedgerEntryDto.fromJson({
        'id': 45,
        'coins': 30,
        'balance_before': 15,
        'balance_after': -15,
        'meta': {
          'projection_label': 'shop_purchase',
          'bavix_transaction_type': 'withdraw',
        },
        'created_at': '2026-08-31T05:12:00+05:45',
      });
      expect(dto.amount, 30);
      expect(dto.direction, 'debit');
      expect(dto.sourceLabel, 'shop_purchase');
    });
  });
}

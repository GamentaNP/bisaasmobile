import 'package:bisaasmobile/features/economy/data/models/economy_dto.dart';
import 'package:bisaasmobile/features/economy/domain/entities/economy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EconomyInventoryItemDto', () {
    test('fromJson tolerant — minimal', () {
      final dto = EconomyInventoryItemDto.fromJson({'id': 1, 'key': 'brick', 'name': 'Brick', 'quantity': 5});
      expect(dto.id, 1);
      expect(dto.key, 'brick');
      expect(dto.name, 'Brick');
      expect(dto.quantity, 5);
      expect(dto.toDomain(), isA<EconomyInventoryItem>());
    });

    test('fromJson with all fields and additive extra ignored', () {
      final dto = EconomyInventoryItemDto.fromJson({
        'id': 10,
        'key': 'cement',
        'name': 'Cement',
        'icon': 'cement_icon',
        'category': 'material',
        'quantity': 12,
        'base_price_coins': 100,
        'sell_price_coins': 80,
        'updated_at': '2026-08-30T10:00:00Z',
        'extra_future_field': {'nested': true},
        'another': 123,
      });
      expect(dto.icon, 'cement_icon');
      expect(dto.quantity, 12);
      expect(dto.basePriceCoins, 100);
      expect(dto.updatedAt, isNotNull);
      expect(dto.toDomain().quantity, 12);
    });

    test('handles quantity as string gracefully', () {
      final dto = EconomyInventoryItemDto.fromJson({'id': '5', 'key': 'sand', 'name': 'Sand', 'quantity': '7'});
      expect(dto.id, 5);
      expect(dto.quantity, 7);
    });

    test('handles missing quantity default 0', () {
      final dto = EconomyInventoryItemDto.fromJson({'id': 1, 'key': 'wood', 'name': 'Wood'});
      expect(dto.quantity, 0);
    });
  });

  group('EconomyCatalogItemDto', () {
    test('fromJson minimal tolerant', () {
      final dto = EconomyCatalogItemDto.fromJson({'id': 1, 'key': 'steel', 'name': 'Steel'});
      expect(dto.key, 'steel');
      expect(dto.sortOrder, isNull);
      expect(dto.toDomain(), isA<EconomyCatalogItem>());
    });

    test('additive unknown fields ignored', () {
      final dto = EconomyCatalogItemDto.fromJson({'id': 99, 'key': 'glass', 'name': 'Glass', 'new_field': 123, 'rarity': 'epic'});
      expect(dto.id, 99);
    });
  });

  group('EconomyResourceLogDto', () {
    test('fromJson with nested resource', () {
      final dto = EconomyResourceLogDto.fromJson({
        'id': 1,
        'resource': {'id': 2, 'key': 'tile', 'name': 'Tile', 'icon': 'tile_icon'},
        'delta': 5,
        'balance_after': 15,
        'reason': 'quiz_reward',
        'source_type': 'quiz_attempt',
        'occurred_at': '2026-08-30T12:00:00Z',
        'metadata': {'quiz_id': 'abc'},
      });
      expect(dto.resourceKey, 'tile');
      expect(dto.delta, 5);
      expect(dto.balanceAfter, 15);
      expect(dto.metadata['quiz_id'], 'abc');
      expect(dto.toDomain(), isA<EconomyResourceLogEntry>());
    });

    test('additive ignores new fields', () {
      final dto = EconomyResourceLogDto.fromJson({'id': 7, 'delta': -3, 'balance_after': 10, 'new_server_field': 'x'});
      expect(dto.id, 7);
      expect(dto.delta, -3);
    });

    test('flat fallback without nested resource', () {
      final dto = EconomyResourceLogDto.fromJson({'id': 3, 'delta': 2, 'balance_after': 5, 'occurred_at': '2026-08-30T00:00:00Z'});
      expect(dto.resourceId, 0); // defaults when no resource block
    });
  });

  group('EconomyInventoryBundleDto', () {
    test('fromJson composite tolerant with empty', () {
      final dto = EconomyInventoryBundleDto.fromJson({});
      expect(dto.inventory, isEmpty);
      expect(dto.catalog, isEmpty);
      expect(dto.recentActivity, isEmpty);
      expect(dto.toDomain(), isA<EconomyInventoryBundle>());
    });

    test('fromJson composite with lists and extra fields', () {
      final dto = EconomyInventoryBundleDto.fromJson({
        'inventory': [
          {'id': 1, 'key': 'brick', 'name': 'Brick', 'quantity': 10},
          {'id': 2, 'key': 'cement', 'name': 'Cement', 'quantity': 3},
        ],
        'catalog': [
          {'id': 1, 'key': 'brick', 'name': 'Brick'},
        ],
        'recent_activity': [
          {'id': 99, 'delta': 1, 'balance_after': 11, 'occurred_at': '2026-08-30T00:00:00Z', 'resource': {'id': 1, 'key': 'brick', 'name': 'Brick'}},
        ],
        'inventory_count': 2, // meta extra ignored
      });
      expect(dto.inventory.length, 2);
      expect(dto.catalog.length, 1);
      expect(dto.recentActivity.length, 1);
      expect(dto.toDomain(isDegraded: false).inventory.first.quantity, 10);
    });
  });

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

    test('LedgerEntryDto fromJson uses description as sourceLabel per AGENTS 155', () {
      final dto = LedgerEntryDto.fromJson({'amount': 10, 'description': 'quiz_correct', 'created_at': '2026-08-30T10:00:00Z', 'metadata': {'source': 'should_be_ignored'}});
      expect(dto.sourceLabel, 'quiz_correct');
      expect(dto.amount, 10);
      expect(dto.direction, 'credit');
      expect(dto.toDomain(), isA<LedgerEntry>());
      // Verify we did NOT read metadata.source
      expect(dto.metadata?['source'], 'should_be_ignored');
      expect(dto.sourceLabel, isNot('should_be_ignored'));
    });

    test('LedgerEntryDto handles debit via negative string amount', () {
      final dto = LedgerEntryDto.fromJson({'amount': '-25', 'description': 'store_purchase', 'created_at': '2026-08-30T10:00:00Z'});
      expect(dto.amount, 25); // abs
      expect(dto.direction, 'debit');
    });

    test('LedgerEntryDto additive ignores new fields', () {
      final dto = LedgerEntryDto.fromJson({'amount': 5, 'description': 'x', 'new_field': 123, 'bonus': true});
      expect(dto.amount, 5);
    });
  });

  group('ShopItemDto', () {
    test('fromJson a server resource row', () {
      // The server publishes an integer id, a key and `base_price_coins`.
      final dto = ShopItemDto.fromJson(
        {
          'id': 7,
          'key': 'cement_bag',
          'name': 'Cement Bag',
          'category': 'material',
          'base_price_coins': 120,
          'sell_price_coins': 60,
          'sort_order': 3,
        },
        type: ShopItemType.resource,
      );
      expect(dto.id, 7);
      expect(dto.key, 'cement_bag');
      expect(dto.priceCoins, 120);
      expect(dto.sellPriceCoins, 60);
      expect(dto.type, ShopItemType.resource);
      expect(dto.toDomain(), isA<ShopItem>());
      expect(dto.toDomain().isBundle, isFalse);
    });

    test('fromJson a server bundle row', () {
      final dto = ShopItemDto.fromJson(
        {
          'id': 2,
          'key': 'starter_bundle',
          'name': 'Starter Bundle',
          'description': 'A head start',
          'price_coins': 500,
          'original_price_coins': 700,
          'contents': {'cement_bag': 4},
        },
        type: ShopItemType.bundle,
      );
      expect(dto.priceCoins, 500);
      expect(dto.originalPriceCoins, 700);
      expect(dto.contents['cement_bag'], 4);
      expect(dto.toDomain().isBundle, isTrue);
      expect(dto.toDomain().discountCoins, 200);
    });

    test('an integer id does not throw', () {
      // Regression: the previous parser read `id` as a String and threw a
      // TypeError on every row, which the data source swallowed — so the
      // whole catalogue rendered as empty.
      expect(
        () => ShopItemDto.fromJson({'id': 5, 'key': 'k', 'name': 'n'}, type: ShopItemType.resource),
        returnsNormally,
      );
    });

    test('ShopItemType wire values match the server contract', () {
      expect(ShopItemType.resource.wireValue, 'resource');
      expect(ShopItemType.bundle.wireValue, 'bundle');
      expect(ShopItemType.fromWire('bundle'), ShopItemType.bundle);
      expect(ShopItemType.fromWire('resource'), ShopItemType.resource);
    });
  });

  group('WalletCategoriesDto', () {
    test('parses the keyed category map and totals', () {
      final dto = WalletCategoriesDto.fromJson({
        'period': {'days': 30},
        'categories': {
          'daily_checkin': {'label': 'Daily check-in', 'coins': 120, 'entries': 4},
          'quiz_achievement': {'label': 'Quiz rewards', 'coins': -50, 'entries': 1},
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

  group('ShopPurchaseResultDto', () {
    test('parses the server purchase payload', () {
      final dto = ShopPurchaseResultDto.fromJson({
        'type': 'bundle',
        'key': 'starter_bundle',
        'quantity': 2,
        'coins_spent': 1000,
        'coin_balance': 4200,
      });
      expect(dto.success, isTrue);
      expect(dto.itemType, ShopItemType.bundle);
      expect(dto.itemKey, 'starter_bundle');
      expect(dto.coinsSpent, 1000);
      expect(dto.coinBalance, 4200);
    });
  });

  group('Donation DTOs', () {
    test('DonorLeaderboardEntryDto tolerant snake/camel', () {
      final dto = DonorLeaderboardEntryDto.fromJson({'donorName': 'Ram', 'badge': 'gold', 'totalDonatedFormatted': '\$10.00', 'streakMonths': 3});
      expect(dto.donorName, 'Ram');
      expect(dto.toDomain(), isA<DonorLeaderboardEntry>());
      final dto2 = DonorLeaderboardEntryDto.fromJson({'donor_name': 'Sita', 'badge': 'silver', 'total_donated_formatted': '\$5.00'});
      expect(dto2.donorName, 'Sita');
    });

    test('DonationFeedEntryDto minimal', () {
      final dto = DonationFeedEntryDto.fromJson({'id': 1, 'displayName': 'A', 'amountFormatted': '\$2.00'});
      expect(dto.id, 1);
      expect(dto.toDomain(), isA<DonationFeedEntry>());
    });

    test('FreezeStreakResultDto fromJson', () {
      final dto = FreezeStreakResultDto.fromJson({'frozen': true, 'message': 'ok'});
      expect(dto.frozen, true);
      expect(dto.toDomain().frozen, true);
    });

    test('additive fields never crash', () {
      final dto = DonorLeaderboardEntryDto.fromJson({'donorName': 'X', 'badge': 'b', 'new_future': 'ignored', 'anotherNested': {'a': 1}});
      expect(dto.donorName, 'X');
      final feed = DonationFeedEntryDto.fromJson({'id': 9, 'displayName': 'Y', 'future': 123});
      expect(feed.displayName, 'Y');
    });
  });

  group('WalletLedger grouping', () {
    test('groupedByDay works across days', () {
      final ledger = WalletLedger(entries: [
        LedgerEntry(amount: 10, direction: 'credit', sourceLabel: 'quiz', description: 'quiz', createdAt: DateTime(2026, 8, 30)),
        LedgerEntry(amount: 5, direction: 'credit', sourceLabel: 'quiz', description: 'quiz', createdAt: DateTime(2026, 8, 30, 12)),
        LedgerEntry(amount: 20, direction: 'debit', sourceLabel: 'shop', description: 'shop', createdAt: DateTime(2026, 8, 29)),
      ]);
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

/// Cross-layer integration tests for the economy and the premium store.
///
/// Both surfaces used to swallow failures into an empty list, and both used
/// to model a server shape the server never sent — the shop modelled USD
/// coin packs the server does not sell, and the store's DTO read an integer
/// id as a string and threw on every row. These tests pin the corrected
/// contract end to end.
library;

import 'package:bisaasmobile/features/economy/data/datasources/economy_remote_data_source.dart';
import 'package:bisaasmobile/features/economy/data/repositories/economy_repository_impl.dart';
import 'package:bisaasmobile/features/economy/domain/entities/economy.dart';
import 'package:bisaasmobile/features/economy/domain/repositories/economy_repository.dart';
import 'package:bisaasmobile/features/store/data/datasources/store_remote_data_source.dart';
import 'package:bisaasmobile/features/store/data/repositories/store_repository_impl.dart';
import 'package:bisaasmobile/features/store/domain/repositories/store_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  group('the coin shop', () {
    late FakeApi api;
    late EconomyRepository repository;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      repository = EconomyRepositoryImpl(EconomyRemoteDataSource(dioFor(api)));
    });

    test('the catalogue is the resources and bundles, priced in coins',
        () async {
      api.on(
        'GET',
        '/economy/shop',
        FakeRoute.ok(<String, dynamic>{
          'resources': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 7,
              'key': 'cement_bag',
              'name': 'Cement Bag',
              'category': 'material',
              'base_price_coins': 120,
              'sell_price_coins': 60,
            },
          ],
          'bundles': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 2,
              'key': 'starter_bundle',
              'name': 'Starter Bundle',
              'price_coins': 500,
              'original_price_coins': 700,
            },
          ],
        }),
      );

      final items = await repository.getShopItems();

      expect(items, hasLength(2));
      final resource = items.firstWhere((i) => i.type == ShopItemType.resource);
      final bundle = items.firstWhere((i) => i.type == ShopItemType.bundle);
      expect(resource.id, 7);
      expect(resource.key, 'cement_bag');
      expect(resource.priceCoins, 120);
      expect(bundle.key, 'starter_bundle');
      expect(bundle.priceCoins, 500);
      expect(bundle.discountCoins, 200);
    });

    test('a purchase sends the body the server validates', () async {
      api.on(
        'POST',
        '/economy/shop/purchase',
        FakeRoute.ok(<String, dynamic>{
          'type': 'bundle',
          'key': 'starter_bundle',
          'quantity': 2,
          'coins_spent': 1000,
          'coin_balance': 4200,
        }),
      );

      final result = await repository.purchaseShopItem(
        type: ShopItemType.bundle,
        key: 'starter_bundle',
        quantity: 2,
        idempotencyKey: 'idem-1',
      );

      expect(result.success, isTrue);
      expect(result.coinsSpent, 1000);
      expect(result.coinBalance, 4200);

      final body = api.jsonBodyOf(0);
      expect(body['type'], 'bundle');
      expect(body['key'], 'starter_bundle');
      expect(body['quantity'], 2);
      expect(body.containsKey('pack_id'), isFalse);
      expect(api.requests.single.headers['Idempotency-Key'], 'idem-1');
    });

    test('the ledger is walked with a cursor, never a page number', () async {
      api.on(
        'GET',
        '/economy/wallet/ledger',
        FakeRoute.envelope(<String, dynamic>{
          'success': true,
          'data': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 55,
                'coins': -100,
                'balance_before': 500,
                'balance_after': 400,
                'created_at': '2026-10-19T10:00:00+00:00',
                'meta': <String, dynamic>{'projection_label': 'shop_purchase'},
              },
            ],
          },
          'pagination': <String, dynamic>{
            'type': 'cursor',
            'per_page': 20,
            'count': 1,
            'has_more': true,
            'next_cursor': 55,
          },
        }),
      );

      final ledger = await repository.getLedger(cursor: '55');

      expect(ledger.entries, hasLength(1));
      expect(ledger.entries.first.amount, 100);
      expect(ledger.entries.first.isDebit, isTrue);
      expect(ledger.entries.first.sourceLabel, 'shop_purchase');
      expect(ledger.hasMore, isTrue);
      expect(ledger.nextCursor, '55');

      final query = api.queryOf(0);
      expect(query['cursor'], '55');
      expect(query.containsKey('page'), isFalse);
    });

    test('own spending by category is read from the keyed map', () async {
      api.on(
        'GET',
        '/economy/wallet/categories',
        FakeRoute.ok(<String, dynamic>{
          'period': <String, dynamic>{'days': 30},
          'categories': <String, dynamic>{
            'daily_checkin': <String, dynamic>{
              'label': 'Daily check-in',
              'coins': 120,
              'entries': 4,
            },
            'quiz_achievement': <String, dynamic>{
              'label': 'Quiz rewards',
              'coins': -50,
              'entries': 1,
            },
          },
          'totals': <String, dynamic>{'earned': 120, 'spent': -50},
        }),
      );

      final categories = await repository.getWalletCategories(period: '30d');

      expect(categories.categories, hasLength(2));
      expect(categories.earned, 120);
      expect(categories.spentAbsolute, 50);
      expect(categories.categories.last.isSpending, isTrue);
    });
  });

  group('the premium store', () {
    late FakeApi api;
    late StoreRepository repository;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      repository = StoreRepositoryImpl(StoreRemoteDataSource(dioFor(api)));
    });

    test('an integer id from the server does not break the catalogue', () async {
      api.on(
        'GET',
        '/store/assets',
        FakeRoute.envelope(<String, dynamic>{
          'success': true,
          'data': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 5,
                'slug': 'frame_gold',
                'name': 'Golden Frame',
                'category': 'avatar_frame',
                'rarity': 'rare',
                'price_coins': 500,
              },
            ],
          },
          'pagination': <String, dynamic>{
            'type': 'cursor',
            'per_page': 25,
            'count': 1,
            'has_more': false,
          },
        }),
      );

      final catalog = await repository.getAssets();

      expect(catalog.assets, hasLength(1));
      expect(catalog.assets.first.id, '5');
      expect(catalog.assets.first.slug, 'frame_gold');
      expect(catalog.assets.first.priceCoins, 500);
    });

    test('equipping targets a slot the server accepts', () async {
      api.on(
        'PUT',
        '/store/wardrobe/equipment',
        FakeRoute.ok(<String, dynamic>{'equipped': true}),
      );

      final ok = await repository.equip('avatar_frame', '5');

      expect(ok, isTrue);
      final body = api.jsonBodyOf(0);
      expect(body['slot'], 'avatar_frame');
      expect(body['asset_id'], 5);
    });

    test('the slot names are the ones the client offers', () {
      expect(
        StoreRemoteDataSource.wardrobeSlots,
        <String>[
          'avatar_frame',
          'avatar',
          'quiz_theme',
          'sound_pack',
          'mascot',
        ],
      );
    });
  });

  group('failures are failures', () {
    test('a 500 on the shop surfaces as an error, not an empty catalogue',
        () async {
      final api = FakeApi(<String, FakeRoute>{
        'GET /economy/shop': FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
      });
      final repository =
          EconomyRepositoryImpl(EconomyRemoteDataSource(dioFor(api)));

      await expectLater(
        repository.getShopItems(),
        throwsA(isA<Exception>()),
      );
    });

    test('a 500 on the store surfaces as an error, not an empty catalogue',
        () async {
      final api = FakeApi(<String, FakeRoute>{
        'GET /store/assets': FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
      });
      final repository =
          StoreRepositoryImpl(StoreRemoteDataSource(dioFor(api)));

      await expectLater(repository.getAssets(), throwsA(isA<Exception>()));
    });
  });
}

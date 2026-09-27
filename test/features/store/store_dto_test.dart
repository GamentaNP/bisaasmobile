import 'package:bisaasmobile/features/store/data/models/store_dto.dart';
import 'package:bisaasmobile/features/store/domain/entities/store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoreAssetDto', () {
    test('fromJson minimal tolerant', () {
      final dto = StoreAssetDto.fromJson({'id': '1', 'slug': 'frame_gold', 'name': 'Golden Frame', 'price_coins': 500});
      expect(dto.id, '1');
      expect(dto.slug, 'frame_gold');
      expect(dto.priceCoins, 500);
      expect(dto.rarity, 'common');
      expect(dto.toDomain(), isA<StoreAsset>());
      expect(dto.toDomain().isFree, isFalse);
    });

    test('fromJson handles all fields with rarity and category', () {
      final dto = StoreAssetDto.fromJson({
        'id': 'badge_master',
        'slug': 'badge_master',
        'name': 'Master Badge',
        'description': 'Top 1%',
        'price_coins': 1200,
        'rarity': 'legendary',
        'category': 'badge',
        'is_owned': true,
        'is_equipped': false,
        'is_featured': true,
        'image_url': 'https://cdn.test/badge.png',
      });
      expect(dto.rarity, 'legendary');
      expect(dto.isOwned, true);
      expect(dto.isFeatured, true);
      expect(dto.toDomain().rarityRank, 3);
    });

    test('handles price as string and alternative keys', () {
      final dto = StoreAssetDto.fromJson({'id': 'x', 'slug': 'x', 'name': 'X', 'price': '0', 'coin_price': 0});
      expect(dto.priceCoins, 0);
      expect(dto.toDomain().isFree, isTrue);
    });

    test('additive tolerant — ignores unknown server fields', () {
      final dto = StoreAssetDto.fromJson({
        'id': 't',
        'slug': 't',
        'name': 'T',
        'price_coins': 100,
        'metadata': {'weight': 10},
        'future_array': [1, 2, 3],
        'split_brain_price': 999,
      });
      expect(dto.id, 't');
      expect(dto.priceCoins, 100);
    });

    test('the hardcoded 6-asset mock catalogue is gone', () {
      // Removed 2026-09-27: those slugs and prices were invented and none of
      // them exist on the server, so every "buy" would have 404'd. There is
      // deliberately no mock fallback any more.
      expect(StoreAssetDto.fromJson({}).id, '');
    });

    test('fallback for missing required defaults', () {
      final dto = StoreAssetDto.fromJson({});
      expect(dto.id, '');
      expect(dto.slug, '');
      expect(dto.priceCoins, 0);
      expect(dto.rarity, 'common');
    });
  });

  group('WardrobeDto', () {
    test('fromJson list shape tolerant', () {
      final dto = WardrobeDto.fromJson({
        'slots': [
          {'slot': 'frame', 'asset': {'id': 'f1', 'slug': 'frame_gold', 'name': 'Gold', 'price_coins': 100}},
          {'slot': 'badge', 'asset': null},
        ],
      });
      expect(dto.slots.length, 2);
      expect(dto.slots.first.slot, 'frame');
      expect(dto.slots.first.equippedAsset?.name, 'Gold');
      expect(dto.toDomain(), isA<Wardrobe>());
    });

    test('fromJson map shape tolerant — server may send object', () {
      final dto = WardrobeDto.fromJson({
        'wardrobe': {
          'frame': {'id': 'f1', 'slug': 'frame_gold', 'name': 'Gold', 'price_coins': 100},
          'badge': null,
        },
      });
      expect(dto.slots.length, 2);
    });

    test('additive ignores new fields', () {
      final dto = WardrobeDto.fromJson({'slots': [], 'new_field': 'ignored', 'another': 123});
      expect(dto.slots, isEmpty);
    });

    test('localMockDegraded returns 4 slots isDegraded true', () {
      final dto = WardrobeDto.localMockDegraded();
      expect(dto.isDegraded, isTrue);
      expect(dto.slots.length, 4);
      expect(dto.toDomain().isDegraded, isTrue);
    });
  });

  group('MarketListingDto', () {
    test('fromJson minimal', () {
      final dto = MarketListingDto.fromJson({
        'asset': {'id': '1', 'slug': 'theme_midnight', 'name': 'Midnight', 'price_coins': 300},
        'seller_name': 'Ram',
        'price_coins': 250,
      });
      expect(dto.sellerName, 'Ram');
      expect(dto.priceCoins, 250);
      expect(dto.toDomain(), isA<MarketListing>());
    });

    test('additive tolerant', () {
      final dto = MarketListingDto.fromJson({'id': 'x', 'name': 'X', 'price_coins': 10, 'extra': 'ignored'});
      expect(dto.priceCoins, 10);
    });
  });

  group('StorePurchaseResultDto', () {
    test('fromJson success', () {
      final dto = StorePurchaseResultDto.fromJson({'success': true, 'asset_id': 'frame_gold', 'coins_spent': 500});
      expect(dto.success, isTrue);
      expect(dto.coinsSpent, 500);
      expect(dto.toDomain().success, isTrue);
    });

    test('fromJson degraded true on 404 placeholder', () {
      final dto = StorePurchaseResultDto.fromJson({'success': false, 'message': 'Store not available yet (beta)', 'is_degraded': true});
      expect(dto.isDegraded, isTrue);
      expect(dto.toDomain().isDegraded, isTrue);
    });

    test('handles string coins_spent', () {
      final dto = StorePurchaseResultDto.fromJson({'success': true, 'coins_spent': '100'});
      expect(dto.coinsSpent, 100);
    });
  });

  group('StoreCatalog entity', () {
    // Real server-shaped assets, replacing the deleted localMocks() fixtures.
    List<StoreAsset> storeAssets() => [
          const StoreAssetDto(id: 'frame_gold', slug: 'frame_gold', name: 'Golden Frame', description: 'd', priceCoins: 500, rarity: 'rare', category: 'frame', isFeatured: true).toDomain(),
          const StoreAssetDto(id: 'badge_master', slug: 'badge_master', name: 'Master Badge', description: 'd', priceCoins: 1200, rarity: 'legendary', category: 'badge', isFeatured: true).toDomain(),
          const StoreAssetDto(id: 'theme_midnight', slug: 'theme_midnight', name: 'Midnight Theme', description: 'd', priceCoins: 300, rarity: 'common', category: 'theme').toDomain(),
        ];

    test('isDegraded and featured filter', () {
      final catalog = StoreCatalog(assets: storeAssets(), isDegraded: true);
      expect(catalog.isDegraded, isTrue);
      expect(catalog.featured, hasLength(2));
      expect(catalog.byCategory('frame'), hasLength(1));
      expect(catalog.isEmpty, isFalse);
    });

    test('rarity ordering', () {
      final assets = storeAssets();
      assets.sort((a, b) => b.rarityRank.compareTo(a.rarityRank));
      expect(assets.first.rarity, 'legendary');
    });

    test('an empty catalogue is empty, not fabricated', () {
      final catalog = StoreCatalog(assets: const [], isDegraded: false);
      expect(catalog.isEmpty, isTrue);
      expect(catalog.featured, isEmpty);
    });
  });
}

import 'package:meta/meta.dart';

/// Pure Dart store entities — premium assets, wardrobe, market.
/// All price/ownership is server-authoritative; the client never invents.
///
/// The store endpoints are live: `GET /store/assets` is cursor-paginated and
/// every row is a real premium asset. The "local mock + beta placeholder" mode
/// this file used to describe was removed on 2026-10-20 — it was hiding a
/// working catalogue behind a fake degraded state.
@immutable
class StoreAsset {
  const StoreAsset({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.priceCoins,
    this.rarity = 'common',
    this.imageUrl,
    this.category,
    this.isOwned = false,
    this.isEquipped = false,
    this.isFeatured = false,
  });

  final String id;
  final String slug;
  final String name;
  final String? description;
  final int priceCoins;
  final String rarity; // common | rare | epic | legendary
  final String? imageUrl;
  final String? category;
  final bool isOwned;
  final bool isEquipped;
  final bool isFeatured;

  bool get isFree => priceCoins == 0;

  static const rarityOrder = {'common': 0, 'rare': 1, 'epic': 2, 'legendary': 3};
  int get rarityRank => rarityOrder[rarity.toLowerCase()] ?? 0;
}

@immutable
class WardrobeSlot {
  const WardrobeSlot({required this.slot, this.equippedAsset});

  final String slot; // e.g. avatar_frame, badge, theme, title
  final StoreAsset? equippedAsset;
}

@immutable
class Wardrobe {
  const Wardrobe({required this.slots});

  final List<WardrobeSlot> slots;

  StoreAsset? equippedIn(String slot) =>
      slots.where((s) => s.slot == slot).map((s) => s.equippedAsset).firstOrNull;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

@immutable
class MarketListing {
  const MarketListing({
    required this.asset,
    required this.sellerName,
    required this.priceCoins,
    this.listedAt,
  });

  final StoreAsset asset;
  final String sellerName;
  final int priceCoins;
  final DateTime? listedAt;
}

@immutable
class StorePurchaseResult {
  const StorePurchaseResult({
    required this.success,
    this.assetId,
    this.coinsSpent = 0,
    this.newBalance,
    this.message,
  });

  final bool success;
  final String? assetId;
  final int coinsSpent;
  final int? newBalance;
  final String? message;
}

/// A page of the catalogue.
@immutable
class StoreCatalog {
  const StoreCatalog({
    required this.assets,
    this.hasMore = false,
    this.nextCursor,
  });

  final List<StoreAsset> assets;

  /// Whether the server has more pages after this one.
  final bool hasMore;

  /// The opaque cursor for the next page.
  final String? nextCursor;

  bool get isEmpty => assets.isEmpty;

  List<StoreAsset> get featured => assets.where((a) => a.isFeatured).toList();
  List<StoreAsset> byCategory(String cat) =>
      assets.where((a) => a.category?.toLowerCase() == cat.toLowerCase()).toList();
}

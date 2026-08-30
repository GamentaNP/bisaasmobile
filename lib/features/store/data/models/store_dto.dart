// ignore_for_file: avoid_dynamic_calls, omit_local_variable_types, unnecessary_cast, prefer_constructors_over_static_methods
import '../../domain/entities/store.dart';

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  if (v is num) return v.toInt();
  return null;
}

DateTime? _asDate(Object? v) => v is String ? DateTime.tryParse(v) : null;

// ── Premium asset (WO-3 — mock tolerant) ─────────────────────────────────────

class StoreAssetDto {
  const StoreAssetDto({
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

  factory StoreAssetDto.fromJson(Map<String, dynamic> j) {
    return StoreAssetDto(
      id: (j['id'] as String?) ?? j['id']?.toString() ?? '',
      slug: (j['slug'] as String?) ?? (j['key'] as String?) ?? '',
      name: (j['name'] as String?) ?? (j['title'] as String?) ?? '',
      description: j['description'] as String?,
      priceCoins: _asInt(j['price_coins'] ?? j['priceCoins'] ?? j['price'] ?? j['coin_price']) ?? 0,
      rarity: (j['rarity'] as String?) ?? 'common',
      imageUrl: (j['image_url'] as String?) ?? (j['imageUrl'] as String?) ?? j['icon'] as String?,
      category: j['category'] as String?,
      isOwned: (j['is_owned'] as bool?) ?? (j['owned'] as bool?) ?? false,
      isEquipped: (j['is_equipped'] as bool?) ?? (j['equipped'] as bool?) ?? false,
      isFeatured: (j['is_featured'] as bool?) ?? (j['featured'] as bool?) ?? false,
    );
  }

  final String id;
  final String slug;
  final String name;
  final String? description;
  final int priceCoins;
  final String rarity;
  final String? imageUrl;
  final String? category;
  final bool isOwned;
  final bool isEquipped;
  final bool isFeatured;

  StoreAsset toDomain() => StoreAsset(
        id: id,
        slug: slug,
        name: name,
        description: description,
        priceCoins: priceCoins,
        rarity: rarity,
        imageUrl: imageUrl,
        category: category,
        isOwned: isOwned,
        isEquipped: isEquipped,
        isFeatured: isFeatured,
      );

  /// Local mock catalog — 6 items covering 4 rarities for beta placeholder.
  static List<StoreAssetDto> localMocks() => const [
        StoreAssetDto(id: 'frame_gold', slug: 'frame_gold', name: 'Golden Frame', description: 'Shine on the leaderboard', priceCoins: 500, rarity: 'rare', category: 'frame', isFeatured: true),
        StoreAssetDto(id: 'badge_master', slug: 'badge_master', name: 'Master Badge', description: 'Awarded to top 1%', priceCoins: 1200, rarity: 'legendary', category: 'badge', isFeatured: true),
        StoreAssetDto(id: 'theme_midnight', slug: 'theme_midnight', name: 'Midnight Theme', description: 'Dark academia for night owls', priceCoins: 300, rarity: 'common', category: 'theme'),
        StoreAssetDto(id: 'title_sage', slug: 'title_sage', name: 'Sage Title', description: 'Display “Sage” under your name', priceCoins: 800, rarity: 'epic', category: 'title'),
        StoreAssetDto(id: 'avatar_astronaut', slug: 'avatar_astronaut', name: 'Astronaut Avatar', description: 'For dreamers of structures', priceCoins: 450, rarity: 'rare', category: 'avatar'),
        StoreAssetDto(id: 'effect_confetti', slug: 'effect_confetti', name: 'Confetti Effect', description: 'Celebration on achievement unlock', priceCoins: 200, rarity: 'common', category: 'effect'),
      ];
}

class WardrobeSlotDto {
  const WardrobeSlotDto({required this.slot, this.equippedAsset});

  factory WardrobeSlotDto.fromJson(Map<String, dynamic> j) {
    final rawAsset = j['asset'] ?? j['equipped_asset'];
    StoreAssetDto? asset;
    if (rawAsset is Map<String, dynamic>) asset = StoreAssetDto.fromJson(rawAsset);
    return WardrobeSlotDto(
      slot: (j['slot'] as String?) ?? (j['key'] as String?) ?? '',
      equippedAsset: asset,
    );
  }

  final String slot;
  final StoreAssetDto? equippedAsset;

  WardrobeSlot toDomain() => WardrobeSlot(slot: slot, equippedAsset: equippedAsset?.toDomain());
}

class WardrobeDto {
  const WardrobeDto({required this.slots, this.isDegraded = false});

  factory WardrobeDto.fromJson(Map<String, dynamic> j) {
    final raw = j['slots'] ?? j['wardrobe'] ?? j['items'];
    List<WardrobeSlotDto> slots = [];
    if (raw is List) {
      slots = raw.whereType<Map<String, dynamic>>().map(WardrobeSlotDto.fromJson).toList();
    } else if (raw is Map<String, dynamic>) {
      // Map form: {frame: asset, badge: asset}
      slots = raw.entries.map((e) {
        final v = e.value;
        StoreAssetDto? asset;
        if (v is Map<String, dynamic>) asset = StoreAssetDto.fromJson(v);
        return WardrobeSlotDto(slot: e.key, equippedAsset: asset);
      }).toList();
    }
    return WardrobeDto(
      slots: slots,
      isDegraded: (j['is_degraded'] as bool?) ?? false,
    );
  }

  final List<WardrobeSlotDto> slots;
  final bool isDegraded;

  Wardrobe toDomain() => Wardrobe(
        slots: slots.map((s) => s.toDomain()).toList(),
        isDegraded: isDegraded,
      );

  static WardrobeDto localMockDegraded() => WardrobeDto(
        slots: [
          WardrobeSlotDto(slot: 'frame', equippedAsset: StoreAssetDto.localMocks().first),
          const WardrobeSlotDto(slot: 'badge', equippedAsset: null),
          const WardrobeSlotDto(slot: 'theme', equippedAsset: null),
          const WardrobeSlotDto(slot: 'title', equippedAsset: null),
        ],
        isDegraded: true,
      );
}

class MarketListingDto {
  const MarketListingDto({required this.asset, required this.sellerName, required this.priceCoins, this.listedAt});

  factory MarketListingDto.fromJson(Map<String, dynamic> j) {
    final rawAsset = j['asset'] ?? j['file'] ?? j;
    final assetDto = rawAsset is Map<String, dynamic> ? StoreAssetDto.fromJson(rawAsset) : StoreAssetDto.fromJson(j);
    return MarketListingDto(
      asset: assetDto,
      sellerName: (j['seller_name'] as String?) ?? (j['sellerName'] as String?) ?? 'Anonymous',
      priceCoins: _asInt(j['price_coins'] ?? j['price']) ?? assetDto.priceCoins,
      listedAt: _asDate(j['listed_at'] ?? j['created_at']),
    );
  }

  final StoreAssetDto asset;
  final String sellerName;
  final int priceCoins;
  final DateTime? listedAt;

  MarketListing toDomain() => MarketListing(asset: asset.toDomain(), sellerName: sellerName, priceCoins: priceCoins, listedAt: listedAt);
}

class StorePurchaseResultDto {
  const StorePurchaseResultDto({required this.success, this.assetId, this.coinsSpent = 0, this.newBalance, this.message, this.isDegraded = false});

  factory StorePurchaseResultDto.fromJson(Map<String, dynamic> j) => StorePurchaseResultDto(
        success: (j['success'] as bool?) ?? (j['purchased'] as bool?) ?? false,
        assetId: (j['asset_id'] as String?) ?? (j['assetId'] as String?) ?? j['id']?.toString(),
        coinsSpent: _asInt(j['coins_spent'] ?? j['coinsSpent'] ?? j['price_coins']) ?? 0,
        newBalance: _asInt(j['new_balance'] ?? j['balance'] ?? j['coins']),
        message: j['message'] as String?,
        isDegraded: (j['is_degraded'] as bool?) ?? false,
      );

  final bool success;
  final String? assetId;
  final int coinsSpent;
  final int? newBalance;
  final String? message;
  final bool isDegraded;

  StorePurchaseResult toDomain() => StorePurchaseResult(
        success: success,
        assetId: assetId,
        coinsSpent: coinsSpent,
        newBalance: newBalance,
        message: message,
        isDegraded: isDegraded,
      );
}

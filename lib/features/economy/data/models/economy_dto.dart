// ignore_for_file: avoid_dynamic_calls, omit_local_variable_types, unnecessary_cast, dead_code, unnecessary_type_check, prefer_final_locals, prefer_constructors_over_static_methods
import '../../domain/entities/economy.dart';

/// Tolerant DTOs — additive parsing, never throws on missing/extra fields.
/// Verified live: GET /economy/resources/inventory, GET /donations/*, POST /donations/freeze-streak
/// Missing (WO-1/WO-2): wallet, ledger, shop — tolerant mock fallback, isDegraded flag.

// ── helpers ───────────────────────────────────────────────────────────────────

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  if (v is num) return v.toInt();
  return null;
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  if (v is num) return v.toDouble();
  return null;
}

DateTime? _asDate(Object? v) {
  if (v is String) return DateTime.tryParse(v);
  return null;
}

// ── Resource inventory (live) ─────────────────────────────────────────────────

class EconomyInventoryItemDto {
  const EconomyInventoryItemDto({
    required this.id,
    required this.key,
    required this.name,
    this.icon,
    this.category,
    required this.quantity,
    this.basePriceCoins,
    this.sellPriceCoins,
    this.updatedAt,
  });

  factory EconomyInventoryItemDto.fromJson(Map<String, dynamic> j) {
    // Tolerant: server may rename or add fields like rarity, weight, etc.
    return EconomyInventoryItemDto(
      id: _asInt(j['id']) ?? 0,
      key: (j['key'] as String?) ?? (j['slug'] as String?) ?? '',
      name: (j['name'] as String?) ?? (j['title'] as String?) ?? '',
      icon: j['icon'] as String?,
      category: j['category'] as String?,
      quantity: _asInt(j['quantity'] ?? j['qty'] ?? j['balance']) ?? 0,
      basePriceCoins: _asInt(j['base_price_coins']),
      sellPriceCoins: _asInt(j['sell_price_coins']),
      updatedAt: _asDate(j['updated_at'] ?? j['updatedAt']),
    );
  }

  final int id;
  final String key;
  final String name;
  final String? icon;
  final String? category;
  final int quantity;
  final int? basePriceCoins;
  final int? sellPriceCoins;
  final DateTime? updatedAt;

  EconomyInventoryItem toDomain() => EconomyInventoryItem(
        id: id,
        key: key,
        name: name,
        icon: icon,
        category: category,
        quantity: quantity,
        basePriceCoins: basePriceCoins,
        sellPriceCoins: sellPriceCoins,
        updatedAt: updatedAt,
      );
}

class EconomyCatalogItemDto {
  const EconomyCatalogItemDto({
    required this.id,
    required this.key,
    required this.name,
    this.icon,
    this.category,
    this.basePriceCoins,
    this.sellPriceCoins,
    this.sortOrder,
  });

  factory EconomyCatalogItemDto.fromJson(Map<String, dynamic> j) {
    return EconomyCatalogItemDto(
      id: _asInt(j['id']) ?? 0,
      key: (j['key'] as String?) ?? (j['slug'] as String?) ?? '',
      name: (j['name'] as String?) ?? '',
      icon: j['icon'] as String?,
      category: j['category'] as String?,
      basePriceCoins: _asInt(j['base_price_coins']),
      sellPriceCoins: _asInt(j['sell_price_coins']),
      sortOrder: _asInt(j['sort_order']),
    );
  }

  final int id;
  final String key;
  final String name;
  final String? icon;
  final String? category;
  final int? basePriceCoins;
  final int? sellPriceCoins;
  final int? sortOrder;

  EconomyCatalogItem toDomain() => EconomyCatalogItem(
        id: id,
        key: key,
        name: name,
        icon: icon,
        category: category,
        basePriceCoins: basePriceCoins,
        sellPriceCoins: sellPriceCoins,
        sortOrder: sortOrder,
      );
}

class EconomyResourceLogDto {
  const EconomyResourceLogDto({
    required this.id,
    required this.resourceId,
    required this.resourceKey,
    required this.resourceName,
    this.resourceIcon,
    required this.delta,
    required this.balanceAfter,
    this.reason,
    this.sourceType,
    this.sourceId,
    this.metadata = const {},
    required this.occurredAt,
  });

  factory EconomyResourceLogDto.fromJson(Map<String, dynamic> j) {
    final resRaw = j['resource'];
    int resId = 0;
    String resKey = '';
    String resName = '';
    String? resIcon;
    if (resRaw is Map<String, dynamic>) {
      resId = _asInt(resRaw['id']) ?? 0;
      resKey = (resRaw['key'] as String?) ?? '';
      resName = (resRaw['name'] as String?) ?? '';
      resIcon = resRaw['icon'] as String?;
    } else {
      // Flat fallback for tests where resource is inlined
      resId = _asInt(j['resource_id']) ?? 0;
      resKey = (j['resource_key'] as String?) ?? '';
      resName = (j['resource_name'] as String?) ?? '';
    }

    final metaRaw = j['metadata'];
    Map<String, dynamic> meta = {};
    if (metaRaw is Map<String, dynamic>) meta = metaRaw;
    if (metaRaw is Map) meta = metaRaw.cast<String, dynamic>();

    DateTime occurred = _asDate(j['occurred_at'] ?? j['created_at']) ?? DateTime.now();

    return EconomyResourceLogDto(
      id: _asInt(j['id']) ?? 0,
      resourceId: resId,
      resourceKey: resKey,
      resourceName: resName,
      resourceIcon: resIcon,
      delta: _asInt(j['delta']) ?? 0,
      balanceAfter: _asInt(j['balance_after']) ?? 0,
      reason: j['reason'] as String?,
      sourceType: j['source_type'] as String?,
      sourceId: j['source_id'],
      metadata: meta,
      occurredAt: occurred,
    );
  }

  final int id;
  final int resourceId;
  final String resourceKey;
  final String resourceName;
  final String? resourceIcon;
  final int delta;
  final int balanceAfter;
  final String? reason;
  final String? sourceType;
  final dynamic sourceId;
  final Map<String, dynamic> metadata;
  final DateTime occurredAt;

  EconomyResourceLogEntry toDomain() => EconomyResourceLogEntry(
        id: id,
        resourceId: resourceId,
        resourceKey: resourceKey,
        resourceName: resourceName,
        resourceIcon: resourceIcon,
        delta: delta,
        balanceAfter: balanceAfter,
        reason: reason,
        sourceType: sourceType,
        sourceId: sourceId,
        metadata: metadata,
        occurredAt: occurredAt,
      );
}

class EconomyInventoryBundleDto {
  const EconomyInventoryBundleDto({
    required this.inventory,
    required this.catalog,
    required this.recentActivity,
  });

  factory EconomyInventoryBundleDto.fromJson(Map<String, dynamic> j) {
    // data shape from controller: {inventory: [], catalog: [], recent_activity: []}
    // Tolerant: any missing key → empty list; extra keys ignored.
    List<EconomyInventoryItemDto> inv = [];
    final invRaw = j['inventory'];
    if (invRaw is List) {
      inv = invRaw.whereType<Map<String, dynamic>>().map(EconomyInventoryItemDto.fromJson).toList();
    }
    List<EconomyCatalogItemDto> cat = [];
    final catRaw = j['catalog'];
    if (catRaw is List) {
      cat = catRaw.whereType<Map<String, dynamic>>().map(EconomyCatalogItemDto.fromJson).toList();
    }
    List<EconomyResourceLogDto> act = [];
    final actRaw = j['recent_activity'] ?? j['recentActivity'] ?? j['activity'];
    if (actRaw is List) {
      act = actRaw.whereType<Map<String, dynamic>>().map(EconomyResourceLogDto.fromJson).toList();
    }
    return EconomyInventoryBundleDto(inventory: inv, catalog: cat, recentActivity: act);
  }

  final List<EconomyInventoryItemDto> inventory;
  final List<EconomyCatalogItemDto> catalog;
  final List<EconomyResourceLogDto> recentActivity;

  EconomyInventoryBundle toDomain({bool isDegraded = false}) => EconomyInventoryBundle(
        inventory: inventory.map((e) => e.toDomain()).toList(),
        catalog: catalog.map((e) => e.toDomain()).toList(),
        recentActivity: recentActivity.map((e) => e.toDomain()).toList(),
        isDegraded: isDegraded,
      );
}

// ── Wallet / Ledger (WO-1 mocks, tolerant) ───────────────────────────────────

class WalletDto {
  const WalletDto({required this.coins, this.updatedAt, this.isDegraded = false});

  factory WalletDto.fromJson(Map<String, dynamic> j) {
    return WalletDto(
      coins: _asInt(j['coins'] ?? j['balance'] ?? j['coins_balance']) ?? 0,
      updatedAt: _asDate(j['updated_at'] ?? j['updatedAt']),
      isDegraded: (j['is_degraded'] as bool?) ?? false,
    );
  }

  final int coins;
  final DateTime? updatedAt;
  final bool isDegraded;

  Wallet toDomain() => Wallet(coins: coins, updatedAt: updatedAt, isDegraded: isDegraded);

  static WalletDto degradedFallback(int coins) => WalletDto(coins: coins, isDegraded: true);
}

class LedgerEntryDto {
  const LedgerEntryDto({
    required this.amount,
    required this.direction,
    required this.sourceLabel,
    required this.description,
    required this.createdAt,
    this.id,
    this.metadata,
  });

  factory LedgerEntryDto.fromJson(Map<String, dynamic> j) {
    // Live WO-1 contract (GET /economy/wallet/ledger): rows are
    // {id, event_key, coins, balance_before, balance_after, meta{...,
    // projection_label, bavix_transaction_type}, created_at}.
    // Direction derives from the balance movement — most robust across
    // projections; falls back to legacy `direction`/`amount` shapes.
    final before = (j['balance_before'] as num?)?.toInt();
    final after = (j['balance_after'] as num?)?.toInt();
    Map<String, dynamic>? meta =
        (j['meta'] is Map ? (j['meta'] as Map).cast<String, dynamic>() : null);
    // Balance movement is authoritative; bavix type normalized as fallback.
    String? dirHint;
    if (before != null && after != null) {
      dirHint = after < before ? 'debit' : 'credit';
    } else {
      dirHint = j['direction'] as String?;
      if (dirHint == null) {
        final bavix = meta?['bavix_transaction_type'] as String?;
        if (bavix != null) {
          dirHint = (bavix == 'withdraw' || bavix == 'withdrawal') ? 'debit' : 'credit';
        }
      }
    }
    if (dirHint == null) {
      final amtRaw = j['amount'] ?? j['coins'];
      bool isNeg = false;
      if (amtRaw is num) isNeg = amtRaw < 0;
      if (amtRaw is String) isNeg = amtRaw.trim().startsWith('-');
      dirHint = isNeg ? 'debit' : 'credit';
    }
    final dirRaw = dirHint;

    // Amount: prefer the balance delta, then signed coins, then legacy amount.
    final coinsRaw = j['coins'] ?? j['amount'];
    int amt = 0;
    if (before != null && after != null) {
      amt = (after - before).abs();
    } else if (coinsRaw is num) {
      amt = coinsRaw.abs().toInt();
    } else if (coinsRaw is String) {
      amt = (int.tryParse(coinsRaw) ?? 0).abs();
    }

    // Label: server projection_label ("quiz_achievement") beats absent desc.
    final projLabel = meta?['projection_label'] as String?;
    final desc = (j['description'] as String?) ??
        (j['source_label'] as String?) ??
        (j['reason'] as String?) ??
        (projLabel ?? '');
    final srcLabel = projLabel ?? (j['source_label'] as String?) ?? desc;
    final created = _asDate(j['created_at'] ?? j['occurred_at'] ?? j['timestamp']) ?? DateTime.now();

    // Legacy `metadata` key fallback for non-WO-1 shapes.
    meta ??= () {
      if (j['metadata'] is Map<String, dynamic>) return j['metadata'] as Map<String, dynamic>;
      if (j['metadata'] is Map) return (j['metadata'] as Map).cast<String, dynamic>();
      return null;
    }();

    return LedgerEntryDto(
      amount: amt,
      direction: dirRaw.toLowerCase() == 'debit' ? 'debit' : 'credit',
      sourceLabel: srcLabel,
      description: desc,
      createdAt: created,
      id: j['id']?.toString(),
      metadata: meta,
    );
  }

  final int amount;
  final String direction;
  final String sourceLabel;
  final String description;
  final DateTime createdAt;
  final String? id;
  final Map<String, dynamic>? metadata;

  LedgerEntry toDomain() => LedgerEntry(
        amount: amount,
        direction: direction,
        sourceLabel: sourceLabel,
        description: description,
        createdAt: createdAt,
        id: id,
        metadata: metadata,
      );
}

// ── Shop packs (WO-2) ─────────────────────────────────────────────────────────

/// Paginated ledger page with an explicit degraded flag — the data source
/// knows whether the WO-1 endpoint 404'd (degraded) vs. a legitimately empty
/// account, so the UI never shows the beta banner for a real empty ledger.
class LedgerPageDto {
  const LedgerPageDto({required this.entries, this.isDegraded = false});
  final List<LedgerEntryDto> entries;
  final bool isDegraded;
}

class CoinPackDto {
  const CoinPackDto({
    required this.id,
    required this.coins,
    required this.price,
    this.currency = 'USD',
    this.bonusCoins = 0,
    this.label,
    this.isPopular = false,
    this.isBestValue = false,
  });

  factory CoinPackDto.fromJson(Map<String, dynamic> j) {
    // price may be direct double/string or cents int; tolerant.
    double? rawPrice = _asDouble(j['price']);
    if (rawPrice == null && j['price_cents'] != null) {
      final cents = _asInt(j['price_cents']);
      if (cents != null) rawPrice = cents / 100.0;
    }
    return CoinPackDto(
      id: (j['id'] as String?) ?? (j['slug'] as String?) ?? j['pack_id']?.toString() ?? '',
      coins: _asInt(j['coins'] ?? j['amount']) ?? 0,
      price: rawPrice ?? 0.0,
      currency: (j['currency'] as String?) ?? 'USD',
      bonusCoins: _asInt(j['bonus_coins'] ?? j['bonus']) ?? 0,
      label: j['label'] as String? ?? j['name'] as String?,
      isPopular: (j['is_popular'] as bool?) ?? (j['popular'] as bool?) ?? false,
      isBestValue: (j['is_best_value'] as bool?) ?? (j['best_value'] as bool?) ?? false,
    );
  }

  final String id;
  final int coins;
  final double price;
  final String currency;
  final int bonusCoins;
  final String? label;
  final bool isPopular;
  final bool isBestValue;

  CoinPack toDomain() => CoinPack(
        id: id,
        coins: coins,
        price: price,
        currency: currency,
        bonusCoins: bonusCoins,
        label: label,
        isPopular: isPopular,
        isBestValue: isBestValue,
      );
}

// ── Donations (live) ──────────────────────────────────────────────────────────

class DonorLeaderboardEntryDto {
  const DonorLeaderboardEntryDto({
    required this.donorName,
    required this.badge,
    required this.badgeLabel,
    required this.badgeColor,
    required this.totalDonatedFormatted,
    required this.streakMonths,
  });

  factory DonorLeaderboardEntryDto.fromJson(Map<String, dynamic> j) {
    return DonorLeaderboardEntryDto(
      donorName: (j['donorName'] as String?) ?? (j['donor_name'] as String?) ?? 'Anonymous',
      badge: (j['badge'] as String?) ?? '',
      badgeLabel: (j['badgeLabel'] as String?) ?? (j['badge_label'] as String?) ?? '',
      badgeColor: (j['badgeColor'] as String?) ?? (j['badge_color'] as String?) ?? '#94A3B8',
      totalDonatedFormatted: (j['totalDonatedFormatted'] as String?) ?? (j['total_donated_formatted'] as String?) ?? '\$0.00',
      streakMonths: _asInt(j['streakMonths'] ?? j['streak_months']) ?? 0,
    );
  }

  final String donorName;
  final String badge;
  final String badgeLabel;
  final String badgeColor;
  final String totalDonatedFormatted;
  final int streakMonths;

  DonorLeaderboardEntry toDomain() => DonorLeaderboardEntry(
        donorName: donorName,
        badge: badge,
        badgeLabel: badgeLabel,
        badgeColor: badgeColor,
        totalDonatedFormatted: totalDonatedFormatted,
        streakMonths: streakMonths,
      );
}

class DonationFeedEntryDto {
  const DonationFeedEntryDto({
    required this.id,
    required this.displayName,
    required this.amountFormatted,
    this.message,
    required this.timeAgo,
    required this.isRecurring,
  });

  factory DonationFeedEntryDto.fromJson(Map<String, dynamic> j) {
    return DonationFeedEntryDto(
      id: _asInt(j['id']) ?? 0,
      displayName: (j['displayName'] as String?) ?? (j['display_name'] as String?) ?? 'Supporter',
      amountFormatted: (j['amountFormatted'] as String?) ?? (j['amount_formatted'] as String?) ?? '\$0.00',
      message: j['message'] as String? ?? j['donor_message'] as String?,
      timeAgo: (j['timeAgo'] as String?) ?? (j['time_ago'] as String?) ?? 'Just now',
      isRecurring: (j['isRecurring'] as bool?) ?? (j['is_recurring'] as bool?) ?? false,
    );
  }

  final int id;
  final String displayName;
  final String amountFormatted;
  final String? message;
  final String timeAgo;
  final bool isRecurring;

  DonationFeedEntry toDomain() => DonationFeedEntry(
        id: id,
        displayName: displayName,
        amountFormatted: amountFormatted,
        message: message,
        timeAgo: timeAgo,
        isRecurring: isRecurring,
      );
}

class FreezeStreakResultDto {
  const FreezeStreakResultDto({required this.frozen, this.message, this.isDegraded = false});

  factory FreezeStreakResultDto.fromJson(Map<String, dynamic> j) {
    return FreezeStreakResultDto(
      frozen: (j['frozen'] as bool?) ?? (j['success'] as bool?) ?? false,
      message: j['message'] as String?,
      isDegraded: (j['is_degraded'] as bool?) ?? false,
    );
  }

  final bool frozen;
  final String? message;
  final bool isDegraded;

  FreezeStreakResult toDomain() => FreezeStreakResult(frozen: frozen, message: message, isDegraded: isDegraded);
}

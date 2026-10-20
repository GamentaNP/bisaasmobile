// ignore_for_file: omit_local_variable_types, prefer_final_locals, prefer_constructors_over_static_methods
import '../../../../core/network/api_response.dart';
import '../../domain/entities/economy.dart';

/// Tolerant DTOs — additive parsing, never throws on missing/extra fields.
/// Verified live: GET /economy/resources/inventory, GET /economy/wallet,
/// GET /economy/wallet/ledger, GET /economy/shop, GET /donations/*,
/// POST /donations/freeze-streak, POST /economy/shop/purchase.

// ── helpers ───────────────────────────────────────────────────────────────────

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  if (v is num) return v.toInt();
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

// ── Coin shop (GET /economy/shop) ─────────────────────────────────────────────

/// Paginated ledger page.
///
/// The ledger endpoint is cursor-paginated: the `cursor` parameter is the id
/// of the last-seen entry (`EconomyWalletController::ledger`), and the
/// canonical pagination block is published at the top level of the envelope.
class LedgerPageDto {
  const LedgerPageDto({
    required this.entries,
    this.pagination,
  });

  final List<LedgerEntryDto> entries;
  final Pagination? pagination;

  bool get hasMore => pagination?.hasMore ?? false;
  String? get nextCursor => pagination?.nextCursor;
}

/// One row of the coin shop.
///
/// The server publishes resources and bundles under separate keys
/// (`data.resources`, `data.bundles`) plus a merged `data.packs` alias. The
/// split keys are read because the merged alias loses the `type` that
/// `POST /economy/shop/purchase` validates.
class ShopItemDto {
  const ShopItemDto({
    required this.id,
    required this.type,
    required this.key,
    required this.name,
    required this.priceCoins,
    this.description,
    this.icon,
    this.category,
    this.sellPriceCoins,
    this.originalPriceCoins,
    this.contents = const {},
    this.sortOrder = 0,
  });

  factory ShopItemDto.fromJson(
    Map<String, dynamic> j, {
    required ShopItemType type,
  }) {
    return ShopItemDto(
      // `id` is an integer on the wire. The previous parser read it as a
      // String and threw a TypeError on every row, which the data source
      // swallowed — so the whole catalogue silently rendered as empty.
      id: _asInt(j['id']) ?? 0,
      type: type,
      key: (j['key'] as String?) ?? (j['slug'] as String?) ?? '',
      name: (j['name'] as String?) ?? (j['title'] as String?) ?? '',
      priceCoins: _asInt(
            j['price_coins'] ??
                j['base_price_coins'] ??
                j['priceCoins'] ??
                j['price'],
          ) ??
          0,
      description: j['description'] as String?,
      icon: j['icon'] as String?,
      category: j['category'] as String?,
      sellPriceCoins: _asInt(j['sell_price_coins']),
      originalPriceCoins: _asInt(j['original_price_coins']),
      contents: j['contents'] is Map
          ? (j['contents'] as Map).cast<String, dynamic>()
          : const {},
      sortOrder: _asInt(j['sort_order']) ?? 0,
    );
  }

  final int id;
  final ShopItemType type;
  final String key;
  final String name;
  final int priceCoins;
  final String? description;
  final String? icon;
  final String? category;
  final int? sellPriceCoins;
  final int? originalPriceCoins;
  final Map<String, dynamic> contents;
  final int sortOrder;

  ShopItem toDomain() => ShopItem(
        id: id,
        type: type,
        key: key,
        name: name,
        priceCoins: priceCoins,
        description: description,
        icon: icon,
        category: category,
        sellPriceCoins: sellPriceCoins,
        originalPriceCoins: originalPriceCoins,
        contents: contents,
        sortOrder: sortOrder,
      );
}

/// Own coin spending grouped by category.
///
/// `GET /economy/wallet/categories` returns an object, not a list:
/// `data.categories` is a keyed map of `{label, coins, entries}` and
/// `data.totals` carries `{earned, spent}`.
class WalletCategoriesDto {
  const WalletCategoriesDto({
    required this.categories,
    required this.earned,
    required this.spent,
    this.periodDays = 30,
  });

  factory WalletCategoriesDto.fromJson(Map<String, dynamic> j) {
    final categories = <WalletCategoryDto>[];
    final raw = j['categories'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final value = entry.value;
        if (value is Map) {
          categories.add(
            WalletCategoryDto.fromJson(
              entry.key.toString(),
              value.cast<String, dynamic>(),
            ),
          );
        }
      }
    } else if (raw is List) {
      categories.addAll(
        raw.whereType<Map<String, dynamic>>().map((e) {
          final key = (e['key'] ?? e['category'] ?? '').toString();
          return WalletCategoryDto.fromJson(key, e);
        }),
      );
    }

    final totals = j['totals'];
    final totalsMap = totals is Map ? totals.cast<String, dynamic>() : const <String, dynamic>{};
    final period = j['period'];
    final periodMap = period is Map ? period.cast<String, dynamic>() : const <String, dynamic>{};

    return WalletCategoriesDto(
      categories: categories,
      earned: _asInt(totalsMap['earned']) ?? 0,
      spent: _asInt(totalsMap['spent']) ?? 0,
      periodDays: _asInt(periodMap['days']) ?? 30,
    );
  }

  final List<WalletCategoryDto> categories;
  final int earned;
  final int spent;
  final int periodDays;

  WalletCategories toDomain() => WalletCategories(
        categories: categories.map((c) => c.toDomain()).toList(),
        earned: earned,
        spent: spent,
        periodDays: periodDays,
      );
}

class WalletCategoryDto {
  const WalletCategoryDto({
    required this.key,
    required this.label,
    required this.coins,
    required this.entries,
  });

  factory WalletCategoryDto.fromJson(String key, Map<String, dynamic> j) {
    return WalletCategoryDto(
      key: key,
      label: (j['label'] as String?) ?? key,
      coins: _asInt(j['coins'] ?? j['amount']) ?? 0,
      entries: _asInt(j['entries'] ?? j['count']) ?? 0,
    );
  }

  final String key;
  final String label;
  final int coins;
  final int entries;

  WalletCategory toDomain() => WalletCategory(
        key: key,
        label: label,
        coins: coins,
        entries: entries,
      );
}

/// The outcome of a coin purchase.
class ShopPurchaseResultDto {
  const ShopPurchaseResultDto({
    required this.success,
    this.itemKey,
    this.itemType,
    this.quantity = 0,
    this.coinsSpent = 0,
    this.coinBalance,
    this.message,
  });

  factory ShopPurchaseResultDto.fromJson(Map<String, dynamic> j) {
    final type = j['type'] as String?;
    return ShopPurchaseResultDto(
      success: (j['success'] as bool?) ?? true,
      itemKey: j['key'] as String? ?? (j['resource_key'] as String?),
      itemType: type == null ? null : ShopItemType.fromWire(type),
      quantity: _asInt(j['quantity']) ?? 0,
      coinsSpent: _asInt(j['coins_spent'] ?? j['spent_coins'] ?? j['cost']) ?? 0,
      coinBalance: _asInt(j['coin_balance'] ?? j['balance'] ?? j['coins']),
      message: j['message'] as String?,
    );
  }

  final bool success;
  final String? itemKey;
  final ShopItemType? itemType;
  final int quantity;
  final int coinsSpent;
  final int? coinBalance;
  final String? message;
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

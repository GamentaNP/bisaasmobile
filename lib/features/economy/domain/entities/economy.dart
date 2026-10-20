import 'package:meta/meta.dart';

/// Pure Dart economy entities — no Flutter, additive-tolerant.
/// Server never mints locally; EconomyService::debit is truth.
@immutable
class EconomyInventoryItem {
  const EconomyInventoryItem({
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

  final int id;
  final String key;
  final String name;
  final String? icon;
  final String? category;
  final int quantity;
  final int? basePriceCoins;
  final int? sellPriceCoins;
  final DateTime? updatedAt;
}

@immutable
class EconomyCatalogItem {
  const EconomyCatalogItem({
    required this.id,
    required this.key,
    required this.name,
    this.icon,
    this.category,
    this.basePriceCoins,
    this.sellPriceCoins,
    this.sortOrder,
  });

  final int id;
  final String key;
  final String name;
  final String? icon;
  final String? category;
  final int? basePriceCoins;
  final int? sellPriceCoins;
  final int? sortOrder;
}

@immutable
class EconomyResourceLogEntry {
  const EconomyResourceLogEntry({
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
}

@immutable
class EconomyInventoryBundle {
  const EconomyInventoryBundle({
    required this.inventory,
    required this.catalog,
    required this.recentActivity,
    this.isDegraded = false,
  });

  final List<EconomyInventoryItem> inventory;
  final List<EconomyCatalogItem> catalog;
  final List<EconomyResourceLogEntry> recentActivity;
  final bool isDegraded;

  bool get isEmpty => inventory.isEmpty && catalog.isEmpty;
}

// ── Wallet / Ledger (WO-1 — no API yet, tolerant mocks) ─────────────────────

@immutable
class Wallet {
  const Wallet({
    required this.coins,
    this.updatedAt,
    this.isDegraded = false,
  });

  final int coins;
  final DateTime? updatedAt;
  final bool isDegraded;
}

@immutable
class LedgerEntry {
  const LedgerEntry({
    required this.amount,
    required this.direction,
    required this.sourceLabel,
    required this.description,
    required this.createdAt,
    this.id,
    this.metadata,
  });

  final int amount;
  final String direction; // credit | debit
  final String sourceLabel;
  final String description;
  final DateTime createdAt;
  final String? id;
  final Map<String, dynamic>? metadata;

  bool get isCredit => direction == 'credit';
  bool get isDebit => direction == 'debit';
}

@immutable
class WalletLedger {
  const WalletLedger({
    required this.entries,
    this.hasMore = false,
    this.nextCursor,
  });

  final List<LedgerEntry> entries;
  final bool hasMore;

  /// The opaque cursor for the next page of the ledger.
  final String? nextCursor;

  /// Grouped by day (yyyy-MM-dd) descending.
  Map<String, List<LedgerEntry>> get groupedByDay {
    final m = <String, List<LedgerEntry>>{};
    for (final e in entries) {
      final k =
          '${e.createdAt.year.toString().padLeft(4, '0')}-${e.createdAt.month.toString().padLeft(2, '0')}-${e.createdAt.day.toString().padLeft(2, '0')}';
      m.putIfAbsent(k, () => []).add(e);
    }
    return m;
  }
}

// ── Coin shop (GET /economy/shop) ─────────────────────────────────────────────

/// What kind of shop row this is.
///
/// The server sells **materials and bundles for coins** — not USD coin packs.
/// `POST /economy/shop/purchase` validates `type ∈ {resource, bundle}` and
/// `key`, so the distinction is part of the contract, not a UI detail.
enum ShopItemType {
  resource,
  bundle;

  /// The wire value the server validates against.
  String get wireValue => name;

  static ShopItemType fromWire(String? raw) =>
      raw == 'bundle' ? ShopItemType.bundle : ShopItemType.resource;
}

/// One purchasable row of the coin shop.
///
/// Rows are priced in **coins** (`base_price_coins` for resources,
/// `price_coins` for bundles). The previous model in this file described USD
/// coin packs (`price`, `currency`, `bonusCoins`), which the server has never
/// served — every field rendered as `0` / `$0.00` on top of a catalogue that
/// could not even be parsed.
@immutable
class ShopItem {
  const ShopItem({
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

  final int id;
  final ShopItemType type;

  /// The server's purchase key — what `POST /economy/shop/purchase` sends.
  final String key;
  final String name;
  final String? description;
  final String? icon;
  final String? category;

  /// What it costs, in coins.
  final int priceCoins;

  /// What it sells back for, in coins (resources only).
  final int? sellPriceCoins;

  /// The bundle's undiscounted price, when the server published one.
  final int? originalPriceCoins;

  /// What is inside a bundle. Empty for resources.
  final Map<String, dynamic> contents;
  final int sortOrder;

  bool get isBundle => type == ShopItemType.bundle;

  /// How much the bundle saves, in coins. Zero when there is no discount.
  int get discountCoins {
    final original = originalPriceCoins;
    if (original == null || original <= priceCoins) return 0;
    return original - priceCoins;
  }
}

// ── Own coin spending by category (GET /economy/wallet/categories) ────────────

/// One source category of coin spending.
///
/// The server groups the caller's own ledger by the event-key prefix
/// (`quiz_achievement`, `daily_checkin`, …) and publishes the group as
/// `{label, coins, entries}` where `coins` is signed — negative for spending.
@immutable
class WalletCategory {
  const WalletCategory({
    required this.key,
    required this.label,
    required this.coins,
    required this.entries,
  });

  final String key;
  final String label;

  /// Signed total for the period. Negative means the user spent coins.
  final int coins;
  final int entries;

  bool get isSpending => coins < 0;
}

/// Own coin spending, grouped by category.
///
/// `GET /economy/wallet/categories?period=7d|30d|90d` — an object-shaped
/// aggregate with no pagination.
@immutable
class WalletCategories {
  const WalletCategories({
    required this.categories,
    required this.earned,
    required this.spent,
    this.periodDays = 30,
  });

  final List<WalletCategory> categories;

  /// Coins earned in the period (positive).
  final int earned;

  /// Coins spent in the period (negative on the wire).
  final int spent;
  final int periodDays;

  int get spentAbsolute => spent.abs();
}

/// The result of a coin purchase.
@immutable
class ShopPurchaseResult {
  const ShopPurchaseResult({
    required this.success,
    this.itemKey,
    this.itemType,
    this.quantity = 0,
    this.coinsSpent = 0,
    this.coinBalance,
    this.message,
  });

  final bool success;
  final String? itemKey;
  final ShopItemType? itemType;
  final int quantity;
  final int coinsSpent;
  final int? coinBalance;
  final String? message;
}

// ── Donations (verified live routes) ────────────────────────────────────────

@immutable
class DonorLeaderboardEntry {
  const DonorLeaderboardEntry({
    required this.donorName,
    required this.badge,
    required this.badgeLabel,
    required this.badgeColor,
    required this.totalDonatedFormatted,
    required this.streakMonths,
  });

  final String donorName;
  final String badge;
  final String badgeLabel;
  final String badgeColor;
  final String totalDonatedFormatted;
  final int streakMonths;
}

@immutable
class DonationFeedEntry {
  const DonationFeedEntry({
    required this.id,
    required this.displayName,
    required this.amountFormatted,
    this.message,
    required this.timeAgo,
    required this.isRecurring,
  });

  final int id;
  final String displayName;
  final String amountFormatted;
  final String? message;
  final String timeAgo;
  final bool isRecurring;
}

@immutable
class FreezeStreakResult {
  const FreezeStreakResult({required this.frozen, this.message, this.isDegraded = false});

  final bool frozen;
  final String? message;
  final bool isDegraded;
}

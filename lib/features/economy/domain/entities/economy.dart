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
    this.isDegraded = false,
    this.hasMore = false,
  });

  final List<LedgerEntry> entries;
  final bool isDegraded;
  final bool hasMore;

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

// ── Shop packs (WO-2 — no API yet) ──────────────────────────────────────────

@immutable
class CoinPack {
  const CoinPack({
    required this.id,
    required this.coins,
    required this.price,
    this.currency = 'USD',
    this.bonusCoins = 0,
    this.label,
    this.isPopular = false,
    this.isBestValue = false,
  });

  final String id;
  final int coins;
  final double price;
  final String currency;
  final int bonusCoins;
  final String? label;
  final bool isPopular;
  final bool isBestValue;

  int get totalCoins => coins + bonusCoins;
  String get displayPrice => '\$${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}';
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

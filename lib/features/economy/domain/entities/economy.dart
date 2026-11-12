import 'package:meta/meta.dart';

/// Pure Dart economy entities — no Flutter, additive-tolerant.
/// Server never mints locally; EconomyService::debit is truth.
// ── Wallet / Ledger (WO-1 — no API yet, tolerant mocks) ─────────────────────

@immutable
class Wallet {
  const Wallet({required this.coins, this.updatedAt, this.isDegraded = false});

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
  const FreezeStreakResult({
    required this.frozen,
    this.message,
    this.isDegraded = false,
  });

  final bool frozen;
  final String? message;
  final bool isDegraded;
}

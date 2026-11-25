// ignore_for_file: omit_local_variable_types, prefer_constructors_over_static_methods
import 'package:bisaasmobile/shared/utils/wire_coercion.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/economy.dart';

/// Tolerant DTOs — additive parsing, never throws on missing/extra fields.
/// Verified live: GET /economy/wallet, GET /economy/wallet/ledger,
/// GET /economy/wallet/categories, GET /donations/*,
/// POST /donations/freeze-streak.

// ── helpers ───────────────────────────────────────────────────────────────────

// ── Wallet / Ledger (WO-1 mocks, tolerant) ───────────────────────────────────

class WalletDto {
  const WalletDto({
    required this.coins,
    this.updatedAt,
    this.isDegraded = false,
  });

  factory WalletDto.fromJson(Map<String, dynamic> j) {
    return WalletDto(
      coins: wireInt(j['coins'] ?? j['balance'] ?? j['coins_balance']) ?? 0,
      updatedAt: wireDate(j['updated_at'] ?? j['updatedAt']),
      isDegraded: (j['is_degraded'] as bool?) ?? false,
    );
  }

  final int coins;
  final DateTime? updatedAt;
  final bool isDegraded;

  Wallet toDomain() =>
      Wallet(coins: coins, updatedAt: updatedAt, isDegraded: isDegraded);

  static WalletDto degradedFallback(int coins) =>
      WalletDto(coins: coins, isDegraded: true);
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
    Map<String, dynamic>? meta = (j['meta'] is Map
        ? (j['meta'] as Map).cast<String, dynamic>()
        : null);
    // Balance movement is authoritative; bavix type normalized as fallback.
    String? dirHint;
    if (before != null && after != null) {
      dirHint = after < before ? 'debit' : 'credit';
    } else {
      dirHint = j['direction'] as String?;
      if (dirHint == null) {
        final bavix = meta?['bavix_transaction_type'] as String?;
        if (bavix != null) {
          dirHint = (bavix == 'withdraw' || bavix == 'withdrawal')
              ? 'debit'
              : 'credit';
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
    final desc =
        (j['description'] as String?) ??
        (j['source_label'] as String?) ??
        (j['reason'] as String?) ??
        (projLabel ?? '');
    final srcLabel = projLabel ?? (j['source_label'] as String?) ?? desc;
    final created =
        wireDate(j['created_at'] ?? j['occurred_at'] ?? j['timestamp']) ??
        DateTime.now();

    // Legacy `metadata` key fallback for non-WO-1 shapes.
    meta ??= () {
      if (j['metadata'] is Map<String, dynamic>)
        return j['metadata'] as Map<String, dynamic>;
      if (j['metadata'] is Map)
        return (j['metadata'] as Map).cast<String, dynamic>();
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

// ── Ledger ────────────────────────────────────────────────────────────────────

/// Paginated ledger page.
///
/// The ledger endpoint is cursor-paginated: the `cursor` parameter is the id
/// of the last-seen entry (`EconomyWalletController::ledger`), and the
/// canonical pagination block is published at the top level of the envelope.
class LedgerPageDto {
  const LedgerPageDto({required this.entries, this.pagination});

  final List<LedgerEntryDto> entries;
  final Pagination? pagination;

  bool get hasMore => pagination?.hasMore ?? false;
  String? get nextCursor => pagination?.nextCursor;
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
    final totalsMap = totals is Map
        ? totals.cast<String, dynamic>()
        : const <String, dynamic>{};
    final period = j['period'];
    final periodMap = period is Map
        ? period.cast<String, dynamic>()
        : const <String, dynamic>{};

    return WalletCategoriesDto(
      categories: categories,
      earned: wireInt(totalsMap['earned']) ?? 0,
      spent: wireInt(totalsMap['spent']) ?? 0,
      periodDays: wireInt(periodMap['days']) ?? 30,
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
      coins: wireInt(j['coins'] ?? j['amount']) ?? 0,
      entries: wireInt(j['entries'] ?? j['count']) ?? 0,
    );
  }

  final String key;
  final String label;
  final int coins;
  final int entries;

  WalletCategory toDomain() =>
      WalletCategory(key: key, label: label, coins: coins, entries: entries);
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
      donorName:
          (j['donorName'] as String?) ??
          (j['donor_name'] as String?) ??
          'Anonymous',
      badge: (j['badge'] as String?) ?? '',
      badgeLabel:
          (j['badgeLabel'] as String?) ?? (j['badge_label'] as String?) ?? '',
      badgeColor:
          (j['badgeColor'] as String?) ??
          (j['badge_color'] as String?) ??
          '#94A3B8',
      totalDonatedFormatted:
          (j['totalDonatedFormatted'] as String?) ??
          (j['total_donated_formatted'] as String?) ??
          '\$0.00',
      streakMonths: wireInt(j['streakMonths'] ?? j['streak_months']) ?? 0,
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
      id: wireInt(j['id']) ?? 0,
      displayName:
          (j['displayName'] as String?) ??
          (j['display_name'] as String?) ??
          'Supporter',
      amountFormatted:
          (j['amountFormatted'] as String?) ??
          (j['amount_formatted'] as String?) ??
          '\$0.00',
      message: j['message'] as String? ?? j['donor_message'] as String?,
      timeAgo:
          (j['timeAgo'] as String?) ?? (j['time_ago'] as String?) ?? 'Just now',
      isRecurring:
          (j['isRecurring'] as bool?) ?? (j['is_recurring'] as bool?) ?? false,
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
  const FreezeStreakResultDto({
    required this.frozen,
    this.message,
    this.isDegraded = false,
  });

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

  FreezeStreakResult toDomain() => FreezeStreakResult(
    frozen: frozen,
    message: message,
    isDegraded: isDegraded,
  );
}

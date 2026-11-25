import 'package:meta/meta.dart';

/// Pure-Dart views of the server-authoritative streak self-service payloads.
///
/// These carry only what the app actually reads; wire parsing and additive
/// tolerance stay in `data/models/streak_dto.dart`. The server decides all of
/// these values — the client never computes eligibility, cost or progress.

/// `GET /quiz/streak/repair` — can a missed day be repaired right now?
@immutable
class StreakRepairEligibility {
  const StreakRepairEligibility({
    required this.eligible,
    this.reason,
    this.missedDate,
    this.repairsUsedThisMonth = 0,
  });

  final bool eligible;
  final String? reason;
  final DateTime? missedDate;
  final int repairsUsedThisMonth;
}

/// `POST /quiz/streak/repair` — outcome of spending coins on a missed day.
@immutable
class StreakRepairResult {
  const StreakRepairResult({
    required this.repaired,
    this.message,
    this.reason,
  });

  final bool repaired;
  final String? message;

  /// `error.details.reason` on a 422, e.g. `insufficient_balance`.
  final String? reason;
}

/// `GET /quiz/streak/insurance` — banked tokens, cost and purchase eligibility.
@immutable
class StreakInsuranceStatus {
  const StreakInsuranceStatus({
    required this.activeCount,
    required this.maxActive,
    required this.costCoins,
    required this.canPurchase,
  });

  final int activeCount;
  final int maxActive;
  final int costCoins;
  final bool canPurchase;
}

/// `POST /quiz/streak/insurance` — outcome of buying an auto-repair token.
@immutable
class StreakInsuranceResult {
  const StreakInsuranceResult({required this.purchased, this.message});

  final bool purchased;
  final String? message;
}

/// `POST /quiz/streak/insurance/use` — whether a banked token repaired the streak.
@immutable
class StreakInsuranceUsed {
  const StreakInsuranceUsed({required this.used});

  final bool used;
}

/// Active wager payload (nested in `GET /quiz/streak/wager`).
@immutable
class StreakWager {
  const StreakWager({
    required this.coins,
    required this.days,
    required this.current,
    required this.progressPercent,
    required this.reward,
  });

  final int coins;
  final int days;
  final int current;
  final int progressPercent;
  final int reward;
}

/// `GET /quiz/streak/wager` — the active wager, if any.
@immutable
class StreakWagerStatus {
  const StreakWagerStatus({required this.wager, required this.currentStreak});

  final StreakWager? wager;
  final int currentStreak;
}

/// `POST /quiz/streak/wager` — outcome of committing coins to N days.
@immutable
class StreakWagerOpened {
  const StreakWagerOpened({
    required this.opened,
    this.message,
    this.reason,
  });

  final bool opened;
  final String? message;

  /// `error.details.reason` on a 422, e.g. `active_wager`.
  final String? reason;
}

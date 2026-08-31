// ignore_for_file: avoid_dynamic_calls, omit_local_variable_types

import '../../domain/entities/streak.dart';

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _asDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// Tolerant DTO — additive parsing, never throws on missing/extra fields.
/// Maps `GET /quiz/streak` → `{current_streak, longest_streak, last_activity_date, streak_multiplier}`
/// plus future additive fields like `streak_freeze_count`, `streak_frozen_until`.
class StreakDto {
  const StreakDto({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
    this.streakMultiplier = 1.0,
    this.freezeCount = 0,
    this.freezeUsedAt,
    this.frozenUntil,
  });

  factory StreakDto.fromJson(Map<String, dynamic> j) {
    // Handle both flat and nested under `streak` key for tolerance.
    final src = j['streak'] is Map<String, dynamic> ? j['streak'] as Map<String, dynamic> : j;
    return StreakDto(
      currentStreak: _asInt(src['current_streak'] ?? src['currentStreak']) ?? 0,
      longestStreak: _asInt(src['longest_streak'] ?? src['longestStreak']) ?? 0,
      lastActivityDate: _asDate(src['last_activity_date'] ?? src['lastActivityDate'] ?? src['last_active'] ?? src['last_activity']),
      streakMultiplier: _asDouble(src['streak_multiplier'] ?? src['streakMultiplier'] ?? src['multiplier']) ?? 1.0,
      freezeCount: _asInt(src['streak_freeze_count'] ?? src['freeze_count'] ?? src['freezes']) ?? 0,
      freezeUsedAt: _asDate(src['streak_freeze_used_at'] ?? src['freeze_used_at']),
      frozenUntil: _asDate(src['streak_frozen_until'] ?? src['frozen_until'] ?? src['freeze_until']),
    );
  }

  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final double streakMultiplier;
  final int freezeCount;
  final DateTime? freezeUsedAt;
  final DateTime? frozenUntil;

  Streak toDomain() => Streak(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastActivityDate: lastActivityDate,
        streakMultiplier: streakMultiplier,
        freezeCount: freezeCount,
        freezeUsedAt: freezeUsedAt,
        frozenUntil: frozenUntil,
      );

  Map<String, dynamic> toJson() => {
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_activity_date': lastActivityDate?.toIso8601String(),
        'streak_multiplier': streakMultiplier,
        'streak_freeze_count': freezeCount,
        'streak_freeze_used_at': freezeUsedAt?.toIso8601String(),
        'streak_frozen_until': frozenUntil?.toIso8601String(),
      };
}

/// Result from `POST /donations/freeze-streak`
class FreezeStreakDto {
  const FreezeStreakDto({required this.frozen, this.message, this.frozenUntil});

  factory FreezeStreakDto.fromJson(Map<String, dynamic> j) {
    final src = j['data'] is Map<String, dynamic> ? j['data'] as Map<String, dynamic> : j;
    return FreezeStreakDto(
      frozen: (src['frozen'] as bool?) ?? (src['success'] as bool?) ?? false,
      message: src['message'] as String? ?? j['message'] as String?,
      frozenUntil: _asDate(src['frozen_until'] ?? src['streak_frozen_until'] ?? src['frozenUntil']),
    );
  }

  final bool frozen;
  final String? message;
  final DateTime? frozenUntil;
}


// ── WO-6 Streak self-service DTOs ─────────────────────────────────────────

/// GET /quiz/streak/repair — eligibility before showing purchase UI.
class StreakRepairEligibilityDto {
  const StreakRepairEligibilityDto({
    required this.eligible,
    this.reason,
    this.missedDate,
    this.expiresAt,
    this.repairsUsedThisMonth = 0,
  });

  factory StreakRepairEligibilityDto.fromJson(Map<String, dynamic> j) =>
      StreakRepairEligibilityDto(
        eligible: (j['eligible'] as bool?) ?? false,
        reason: j['reason'] as String?,
        missedDate: _asDate(j['missedDate'] ?? j['missed_date']),
        expiresAt: _asDate(j['expiresAt'] ?? j['expires_at']),
        repairsUsedThisMonth: _asInt(j['repairsUsedThisMonth'] ?? j['repairs_used_this_month']) ?? 0,
      );

  final bool eligible;
  final String? reason;
  final DateTime? missedDate;
  final DateTime? expiresAt;
  final int repairsUsedThisMonth;
}

/// POST /quiz/streak/repair result.
class StreakRepairResultDto {
  const StreakRepairResultDto({
    required this.repaired,
    this.message,
    this.currentStreak,
    this.coinBalance,
  });

  factory StreakRepairResultDto.fromJson(Map<String, dynamic> j) {
    final streakMap = j['streak'] as Map<String, dynamic>?;
    return StreakRepairResultDto(
      repaired: (j['repaired'] as bool?) ?? (j['success'] as bool?) ?? false,
      message: j['message'] as String?,
      currentStreak: _asInt(streakMap?['current_streak'] ?? j['current_streak']),
      coinBalance: _asInt(j['coin_balance']),
    );
  }

  final bool repaired;
  final String? message;
  final int? currentStreak;
  final int? coinBalance;
}

/// POST /quiz/streak/insurance result.
class StreakInsuranceResultDto {
  const StreakInsuranceResultDto({
    required this.purchased,
    this.message,
    this.activeInsuranceCount,
    this.coinBalance,
  });

  factory StreakInsuranceResultDto.fromJson(Map<String, dynamic> j) =>
      StreakInsuranceResultDto(
        purchased: (j['purchased'] as bool?) ?? (j['success'] as bool?) ?? false,
        message: j['message'] as String?,
        activeInsuranceCount: _asInt(j['active_insurance_count']),
        coinBalance: _asInt(j['coin_balance']),
      );

  final bool purchased;
  final String? message;
  final int? activeInsuranceCount;
  final int? coinBalance;
}

/// Active wager payload (nested in GET /quiz/streak/wager).
class StreakWagerDto {
  const StreakWagerDto({
    required this.status,
    required this.coins,
    required this.days,
    required this.target,
    required this.current,
    required this.progressPercent,
    required this.reward,
    this.won,
    this.lost,
  });

  factory StreakWagerDto.fromJson(Map<String, dynamic> j) => StreakWagerDto(
        status: (j['status'] as String?) ?? 'active',
        coins: _asInt(j['coins']) ?? 0,
        days: _asInt(j['days']) ?? 0,
        target: _asInt(j['target']) ?? 0,
        current: _asInt(j['current']) ?? 0,
        progressPercent: _asInt(j['progressPercent'] ?? j['progress_percent']) ?? 0,
        reward: _asInt(j['reward']) ?? 0,
        won: _asDate(j['won']),
        lost: _asDate(j['lost']),
      );

  final String status;
  final int coins;
  final int days;
  final int target;
  final int current;
  final int progressPercent;
  final int reward;
  final DateTime? won;
  final DateTime? lost;
}

/// GET /quiz/streak/wager envelope.
class StreakWagerStatusDto {
  const StreakWagerStatusDto({required this.wager, required this.currentStreak});

  factory StreakWagerStatusDto.fromJson(Map<String, dynamic> j) => StreakWagerStatusDto(
        wager: j['wager'] is Map<String, dynamic>
            ? StreakWagerDto.fromJson(j['wager'] as Map<String, dynamic>)
            : null,
        currentStreak: _asInt(j['currentStreak'] ?? j['current_streak']) ?? 0,
      );

  final StreakWagerDto? wager;
  final int currentStreak;
}

/// POST /quiz/streak/wager result.
class StreakWagerOpenedDto {
  const StreakWagerOpenedDto({required this.opened, this.message, this.wager, this.coinBalance});

  factory StreakWagerOpenedDto.fromJson(Map<String, dynamic> j) => StreakWagerOpenedDto(
        opened: (j['opened'] as bool?) ?? (j['success'] as bool?) ?? false,
        message: j['message'] as String?,
        wager: j['wager'] is Map<String, dynamic>
            ? StreakWagerDto.fromJson(j['wager'] as Map<String, dynamic>)
            : null,
        coinBalance: _asInt(j['coin_balance']),
      );

  final bool opened;
  final String? message;
  final StreakWagerDto? wager;
  final int? coinBalance;
}

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

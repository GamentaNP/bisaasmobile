// ignore_for_file: avoid_dynamic_calls, cast_nullable_to_non_nullable

import 'dart:ui' show Color;

/// Daily check-in and spin-wheel DTOs.
///
/// Verified live 2026-09-27 against the monetization routes
/// (`bisaas/routes/api/monetization.php:58-71`).
///
/// **Envelope inconsistency, deliberately handled here:**
///   * `GET  /rewards/daily-checkin/status` → normal envelope
///     `{data: {claimedToday, streakDay, todayReward, nextReward}}` (camelCase)
///   * `GET  /rewards/spin/status`          → **raw JSON, no envelope**
///     `{canSpin, prizes: [...], nextSpinAt}`
///   * `POST /rewards/spin`                 → **raw JSON, no envelope**
///     `{spun, type, coins, xp, lifelineSlug, lifelineQuantity, label,
///       prizeIndex, newBalance, nextSpinAt, signature, reason}`
///
/// The spin pair also answers 422 with a *raw* body when no spin is available,
/// so the failure case must be parsed the same way as success.
class CheckInStatusDto {
  const CheckInStatusDto({
    required this.claimedToday,
    required this.streakDay,
    required this.todayReward,
    required this.nextReward,
  });

  factory CheckInStatusDto.fromJson(Map<String, dynamic> j) => CheckInStatusDto(
        claimedToday: (j['claimedToday'] as bool?) ?? (j['claimed_today'] as bool?) ?? false,
        streakDay: _asInt(j['streakDay'] ?? j['streak_day']) ?? 0,
        todayReward: _asInt(j['todayReward'] ?? j['today_reward']) ?? 0,
        nextReward: _asInt(j['nextReward'] ?? j['next_reward']) ?? 0,
      );

  final bool claimedToday;
  final int streakDay;
  final int todayReward;

  /// Tomorrow's reward, so the UI can show the ladder without inventing it.
  final int nextReward;

  bool get canClaim => !claimedToday && todayReward > 0;
}

/// Result of `POST /rewards/daily-checkin`.
///
/// A 409 (already claimed) answers with the same payload shape plus a `reason`,
/// so `credited` is the real signal — not the HTTP status.
class CheckInResultDto {
  const CheckInResultDto({
    required this.credited,
    required this.amount,
    required this.newBalance,
    required this.streakDay,
    this.reason,
  });

  factory CheckInResultDto.fromJson(Map<String, dynamic> j) => CheckInResultDto(
        credited: (j['credited'] as bool?) ?? false,
        amount: _asInt(j['amount']) ?? 0,
        newBalance: _asInt(j['newBalance'] ?? j['new_balance']) ?? 0,
        streakDay: _asInt(j['streakDay'] ?? j['streak_day']) ?? 0,
        reason: j['reason'] as String?,
      );

  final bool credited;
  final int amount;
  final int newBalance;
  final int streakDay;
  final String? reason;
}

/// One prize slice on the spin wheel.
class SpinPrizeDto {
  const SpinPrizeDto({
    required this.type,
    required this.coins,
    required this.xp,
    required this.lifelineSlug,
    required this.lifelineQuantity,
    required this.label,
    required this.colorHex,
    required this.rarity,
  });

  factory SpinPrizeDto.fromJson(Map<String, dynamic> j) => SpinPrizeDto(
        type: (j['type'] ?? 'coins').toString(),
        coins: _asInt(j['coins']) ?? 0,
        xp: _asInt(j['xp']) ?? 0,
        lifelineSlug: j['lifelineSlug'] as String? ?? j['lifeline_slug'] as String?,
        lifelineQuantity: _asInt(j['lifelineQuantity'] ?? j['lifeline_quantity']) ?? 0,
        label: (j['label'] ?? '').toString(),
        colorHex: (j['colorHex'] ?? j['color_hex'] ?? '#94A3B8').toString(),
        rarity: (j['rarity'] ?? 'common').toString(),
      );

  /// `coins` | `lifeline`
  final String type;
  final int coins;
  final int xp;
  final String? lifelineSlug;
  final int lifelineQuantity;
  final String label;
  final String colorHex;
  final String rarity;

  /// `#RRGGBB` as sent by the server; falls back to the app's slate tone.
  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return const Color(0xFF94A3B8);
    return Color(hex.length == 6 ? 0xFF000000 | value : value);
  }
}

/// `GET /rewards/spin/status` — raw body, no envelope.
class SpinStatusDto {
  const SpinStatusDto({required this.canSpin, required this.prizes, this.nextSpinAt});

  factory SpinStatusDto.fromJson(Map<String, dynamic> j) => SpinStatusDto(
        canSpin: (j['canSpin'] as bool?) ?? (j['can_spin'] as bool?) ?? false,
        prizes: (j['prizes'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SpinPrizeDto.fromJson)
            .toList(),
        nextSpinAt: DateTime.tryParse((j['nextSpinAt'] ?? j['next_spin_at'])?.toString() ?? ''),
      );

  final bool canSpin;
  final List<SpinPrizeDto> prizes;
  final DateTime? nextSpinAt;
}

/// `POST /rewards/spin` — raw body, no envelope. `spun: false` + `reason` is a
/// normal response, not an exception.
class SpinResultDto {
  const SpinResultDto({
    required this.spun,
    required this.type,
    required this.coins,
    required this.xp,
    required this.lifelineSlug,
    required this.lifelineQuantity,
    required this.label,
    this.prizeIndex,
    this.newBalance,
    this.reason,
  });

  factory SpinResultDto.fromJson(Map<String, dynamic> j) => SpinResultDto(
        spun: (j['spun'] as bool?) ?? false,
        type: (j['type'] ?? '').toString(),
        coins: _asInt(j['coins']) ?? 0,
        xp: _asInt(j['xp']) ?? 0,
        lifelineSlug: j['lifelineSlug'] as String? ?? j['lifeline_slug'] as String?,
        lifelineQuantity: _asInt(j['lifelineQuantity'] ?? j['lifeline_quantity']) ?? 0,
        label: (j['label'] ?? '').toString(),
        prizeIndex: _asInt(j['prizeIndex'] ?? j['prize_index']),
        newBalance: _asInt(j['newBalance'] ?? j['new_balance']),
        reason: j['reason'] as String?,
      );

  final bool spun;
  final String type;
  final int coins;
  final int xp;
  final String? lifelineSlug;
  final int lifelineQuantity;
  final String label;
  final int? prizeIndex;
  final int? newBalance;
  final String? reason;
}

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}



/// Game mission DTOs.
///
/// Verified against `GameMissionsController::dashboard` (bisaas,
/// `routes/api/v1/quiz.php:911-929`, probed 2026-09-27).
///
/// **The dashboard returns a bare JSON array in `data`**, not `{items: [...]}`
/// — 49 missions for the QA account, split daily / weekly / campaign. Keys are
/// camelCase.
class MissionDto {
  const MissionDto({
    required this.id,
    required this.key,
    required this.title,
    required this.cadence,
    required this.targetAction,
    required this.targetCount,
    required this.currentCount,
    required this.progressPercent,
    required this.completed,
    required this.claimed,
    required this.rewardCoins,
    required this.rewardXp,
    this.description,
    this.tier,
    this.autoClaim = false,
    this.scope,
    this.progressId,
    this.gameWorldId,
    this.quizPortalLevelId,
    this.expiresAt,
  });

  factory MissionDto.fromJson(Map<String, dynamic> j) => MissionDto(
        id: _asInt(j['id']) ?? 0,
        key: (j['key'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: j['description'] as String?,
        cadence: (j['cadence'] ?? '').toString(),
        targetAction: (j['targetAction'] ?? j['target_action'] ?? '').toString(),
        targetCount: _asInt(j['targetCount'] ?? j['target_count']) ?? 0,
        currentCount: _asInt(j['currentCount'] ?? j['current_count']) ?? 0,
        progressPercent: _asInt(j['progressPercent'] ?? j['progress_percent']) ?? 0,
        completed: (j['completed'] as bool?) ?? false,
        claimed: (j['claimed'] as bool?) ?? false,
        rewardCoins: _asInt(j['rewardCoins'] ?? j['reward_coins']) ?? 0,
        rewardXp: _asInt(j['rewardXp'] ?? j['reward_xp']) ?? 0,
        tier: j['tier'] as String?,
        autoClaim: (j['autoClaim'] as bool?) ?? (j['auto_claim'] as bool?) ?? false,
        scope: j['scope'] as String?,
        progressId: j['progressId'] as int? ?? (j['progress_id'] as num?)?.toInt(),
        gameWorldId: (j['gameWorldId'] ?? j['game_world_id']) as int?,
        quizPortalLevelId: (j['quizPortalLevelId'] ?? j['quiz_portal_level_id']) as int?,
        expiresAt: DateTime.tryParse((j['expiresAt'] ?? j['expires_at'])?.toString() ?? ''),
      );

  final int id;
  final String key;
  final String title;
  final String? description;

  /// `daily` | `weekly` | `campaign`
  final String cadence;
  final String targetAction;
  final int targetCount;
  final int currentCount;
  final int progressPercent;
  final bool completed;
  final bool claimed;
  final int rewardCoins;
  final int rewardXp;
  final String? tier;
  final bool autoClaim;
  final String? scope;
  final int? progressId;
  final int? gameWorldId;
  final int? quizPortalLevelId;
  final DateTime? expiresAt;

  /// The server decides this — the UI never infers it from `completed`.
  bool get isClaimable => completed && !claimed && !autoClaim;

  double get progressFraction {
    if (targetCount <= 0) return progressPercent / 100;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }
}

/// Result of `PUT /quiz/game/missions/{mission}/claim`
/// (the `POST` alias is also registered).
class MissionClaimDto {
  const MissionClaimDto({
    required this.claimed,
    required this.coins,
    this.tier,
    this.reason,
    this.lifelines,
    this.cityResource,
    this.exclusiveBadge,
  });

  factory MissionClaimDto.fromJson(Map<String, dynamic> j) {
    final extras = j['extras'];
    return MissionClaimDto(
      // Success is signalled by the presence of a reason-free payload with
      // `claimed: true`; a refusal carries `reason` instead.
      claimed: (j['claimed'] as bool?) ?? ((j['reason'] as String?) == null),
      coins: _asInt(j['coins']) ?? 0,
      tier: j['tier'] as String?,
      reason: j['reason'] as String?,
      lifelines: extras is Map<String, dynamic> ? _asInt(extras['lifelines']) : null,
      cityResource: extras is Map<String, dynamic> ? _asInt(extras['cityResource']) : null,
      exclusiveBadge: extras is Map<String, dynamic> ? _asInt(extras['exclusiveBadges']) : null,
    );
  }

  final bool claimed;
  final int coins;
  final String? tier;
  final String? reason;
  final int? lifelines;
  final int? cityResource;
  final int? exclusiveBadge;
}

/// `POST /quiz/game/missions/claims` — claim everything currently claimable.
class MissionBulkClaimDto {
  const MissionBulkClaimDto({
    required this.claimedCount,
    required this.coins,
    required this.failedCount,
    this.failures = const [],
  });

  factory MissionBulkClaimDto.fromJson(Map<String, dynamic> j) => MissionBulkClaimDto(
        claimedCount: _asInt(j['claimedCount'] ?? j['claimed_count']) ?? 0,
        coins: _asInt(j['coins']) ?? 0,
        failedCount: _asInt(j['failedCount'] ?? j['failed_count']) ?? 0,
        failures: (j['failures'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((f) => (f['reason'] ?? 'Unknown').toString())
            .toList(),
      );

  final int claimedCount;
  final int coins;
  final int failedCount;
  final List<String> failures;
}

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

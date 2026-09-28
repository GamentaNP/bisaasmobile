

/// Attempt-scoped lifeline DTOs.
///
/// Verified against `App\Http\Controllers\Api\Quiz\QuizLifelineApiController`
/// and `App\Domains\Economy\Services\LifelineEffectService` (bisaas, read
/// 2026-09-27).
///
/// Casing is inconsistent *within* the cluster, by design of the server:
///   * `GET  /quiz/attempts/{a}/lifelines`                → camelCase
///   * `POST /quiz/attempts/{a}/lifelines/{slug}/purchase` → snake_case
///   * `POST /quiz/attempts/{a}/lifelines/{slug}/use`     → snake_case
/// Do not apply one global key strategy here.
///
/// Slugs are the `economy_lifelines.slug` column. The real values are
/// `fifty_fifty`, `skip`, `hint`, `eliminate_one`, `explanation`,
/// `extra_time`, `time_freeze_30s`, `question_swap`, `double_xp`, `shield`,
/// `second_chance`, `audience_poll`, `reveal_correct` — note **`fifty_fifty`,
/// not `50_50`**, which the previous client placeholder assumed.

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// One lifeline as the server offers it for this attempt.
class LifelineDto {
  const LifelineDto({
    required this.slug,
    required this.name,
    required this.costCoins,
    required this.effectType,
    required this.maxUsesPerAttempt,
    required this.purchasedUses,
    required this.usedUses,
    required this.remainingUses,
    required this.inventoryUses,
    required this.canPurchase,
    required this.canUse,
    required this.lockedByMode,
    required this.lockReason,
    required this.adUnlockEnabled,
    this.iconUrl,
    this.baseCostCoins,
    this.discountPct,
  });

  factory LifelineDto.fromJson(Map<String, dynamic> j) => LifelineDto(
        slug: (j['slug'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        iconUrl: j['iconUrl'] as String? ?? j['icon_url'] as String?,
        costCoins: _asInt(j['costCoins'] ?? j['cost_coins']) ?? 0,
        baseCostCoins: _asInt(j['baseCostCoins'] ?? j['base_cost_coins']),
        discountPct: _asInt(j['discountPct'] ?? j['discount_pct']),
        effectType: (j['effectType'] ?? j['effect_type'] ?? '').toString(),
        maxUsesPerAttempt: _asInt(j['maxUsesPerAttempt'] ?? j['max_uses_per_attempt']) ?? 0,
        purchasedUses: _asInt(j['purchasedUses'] ?? j['purchased_uses']) ?? 0,
        usedUses: _asInt(j['usedUses'] ?? j['used_uses']) ?? 0,
        remainingUses: _asInt(j['remainingUses'] ?? j['remaining_uses']) ?? 0,
        inventoryUses: _asInt(j['inventoryUses'] ?? j['inventory_uses']) ?? 0,
        canPurchase: (j['canPurchase'] as bool?) ?? (j['can_purchase'] as bool?) ?? false,
        canUse: (j['canUse'] as bool?) ?? (j['can_use'] as bool?) ?? false,
        lockedByMode: (j['lockedByMode'] as bool?) ?? (j['locked_by_mode'] as bool?) ?? false,
        lockReason: j['lockReason'] as String? ?? j['lock_reason'] as String?,
        adUnlockEnabled:
            (j['adUnlockEnabled'] as bool?) ?? (j['ad_unlock_enabled'] as bool?) ?? false,
      );

  final String slug;
  final String name;
  final String? iconUrl;

  /// What the player pays now. May be below [baseCostCoins] — the server
  /// applies a discount (verified live: 50 → 38, `discountPct: 25`).
  final int costCoins;
  final int? baseCostCoins;
  final int? discountPct;

  final String effectType;
  final int maxUsesPerAttempt;
  final int purchasedUses;
  final int usedUses;
  final int remainingUses;

  /// Tokens already owned (earned, not bought this attempt).
  final int inventoryUses;

  final bool canPurchase;

  /// The server says this lifeline may be used right now.
  final bool canUse;
  final bool lockedByMode;
  final String? lockReason;
  final bool adUnlockEnabled;

  /// True only when the server allows it. Never assumed.
  ///
  /// Note `canUse` alone is NOT the right gate: on a fresh attempt the server
  /// reports `canUse: false, canPurchase: true` (nothing banked yet, but the
  /// player can afford it). Gating on `canUse` alone would leave every chip
  /// permanently disabled. Verified live against attempt 6115.
  bool get isAvailable => !lockedByMode && (canUse || canPurchase);

  /// True when a banked token covers the cost, so no purchase is needed.
  bool get hasBankedUse => canUse || inventoryUses > 0;
}

/// `GET /quiz/attempts/{attempt}/lifelines` envelope.
/// `enabled: false` (feature kill switch) yields an empty catalogue and the UI
/// must hide the bar entirely rather than showing a dead row.
class LifelineCatalogueDto {
  const LifelineCatalogueDto({
    required this.enabled,
    required this.walletBalance,
    required this.lifelines,
  });

  factory LifelineCatalogueDto.fromJson(Map<String, dynamic> j) => LifelineCatalogueDto(
        enabled: (j['enabled'] as bool?) ?? false,
        walletBalance: _asInt(j['walletBalance'] ?? j['wallet_balance']) ?? 0,
        lifelines: (j['lifelines'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(LifelineDto.fromJson)
            .toList(),
      );

  final bool enabled;
  final int walletBalance;
  final List<LifelineDto> lifelines;

  LifelineDto? bySlug(String slug) {
    for (final l in lifelines) {
      if (l.slug == slug) return l;
    }
    return null;
  }
}

/// The server-built effect payload. Flutter renders it; it never computes one.
///
/// Shapes per `LifelineEffectService::effectPayload`:
///  * `fifty_fifty` / `question_swap` → `hidden_option_keys: [...]`
///  * `reveal_correct`                → `correct_answer`
///  * `hint`                          → `hint` (explanation, trimmed to 200)
///  * `explanation`                   → `explanation`
///  * `audience_poll`                 → `poll`
///  * `time_freeze`                   → `freeze_seconds`, `frozen_until`
///  * `extra_time`                    → `extra_seconds`
///  * `shield`                        → `shield_active`
///  * `second_chance`                 → `retry_question_id`
///  * `double_xp`                     → `double_xp_active`
class LifelineEffectDto {
  const LifelineEffectDto({
    required this.effectType,
    this.questionId,
    this.hiddenOptionKeys = const [],
    this.correctAnswer,
    this.hint,
    this.explanation,
    this.poll,
    this.freezeSeconds,
    this.frozenUntil,
    this.extraSeconds,
    this.shieldActive,
    this.retryQuestionId,
    this.doubleXpActive,
  });

  factory LifelineEffectDto.fromJson(Map<String, dynamic> j) => LifelineEffectDto(
        effectType: (j['effect_type'] ?? j['effectType'] ?? '').toString(),
        questionId: _asInt(j['question_id'] ?? j['questionId']),
        hiddenOptionKeys: (j['hidden_option_keys'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        correctAnswer: (j['correct_answer'] ?? j['correctAnswer'])?.toString(),
        hint: j['hint'] as String?,
        explanation: j['explanation'] as String?,
        poll: j['poll'],
        freezeSeconds: _asInt(j['freeze_seconds'] ?? j['freezeSeconds']),
        frozenUntil: DateTime.tryParse((j['frozen_until'] ?? j['frozenUntil'])?.toString() ?? ''),
        extraSeconds: _asInt(j['extra_seconds'] ?? j['extraSeconds']),
        shieldActive: j['shield_active'] as bool? ?? j['shieldActive'] as bool?,
        retryQuestionId: _asInt(j['retry_question_id'] ?? j['retryQuestionId']),
        doubleXpActive: j['double_xp_active'] as bool? ?? j['doubleXpActive'] as bool?,
      );

  final String effectType;
  final int? questionId;
  final List<String> hiddenOptionKeys;
  final String? correctAnswer;
  final String? hint;
  final String? explanation;
  final Object? poll;
  final int? freezeSeconds;
  final DateTime? frozenUntil;
  final int? extraSeconds;
  final bool? shieldActive;
  final int? retryQuestionId;
  final bool? doubleXpActive;

  /// True when the client has something concrete to render for this effect.
  /// An unrecognised effect is reported rather than silently ignored.
  bool get hasVisibleOutcome =>
      hiddenOptionKeys.isNotEmpty ||
      correctAnswer != null ||
      (hint != null && hint!.isNotEmpty) ||
      (explanation != null && explanation!.isNotEmpty) ||
      poll != null ||
      (freezeSeconds != null && freezeSeconds! > 0) ||
      (extraSeconds != null && extraSeconds! > 0) ||
      (shieldActive ?? false) ||
      (doubleXpActive ?? false) ||
      retryQuestionId != null;
}

/// `POST /quiz/attempts/{a}/lifelines/{slug}/use` and `/purchase-and-use`.
/// Both answer `{slug, remaining_uses, effect: {...}}` (snake_case at the top
/// level, camelCase inside `effect`).
class LifelineUseResultDto {
  const LifelineUseResultDto({
    required this.slug,
    required this.remainingUses,
    required this.effect,
  });

  factory LifelineUseResultDto.fromJson(Map<String, dynamic> j) => LifelineUseResultDto(
        slug: (j['slug'] ?? '').toString(),
        remainingUses: _asInt(j['remaining_uses'] ?? j['remainingUses']) ?? 0,
        effect: LifelineEffectDto.fromJson(
          j['effect'] is Map<String, dynamic> ? j['effect'] as Map<String, dynamic> : const {},
        ),
      );

  final String slug;
  final int remainingUses;
  final LifelineEffectDto effect;
}

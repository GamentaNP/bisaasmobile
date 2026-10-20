import '../../domain/entities/ai_settings.dart';

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
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

/// One stored BYOK credential, as the server publishes it.
class AiKeyDto {
  const AiKeyDto({
    required this.id,
    required this.provider,
    this.providerLabel,
    this.label,
    this.maskedPreview,
    this.isActive = true,
    this.healthStatus,
    this.healthDetail,
    this.dailyTokenLimit = 0,
    this.tokensConsumedToday = 0,
    this.lastUsedAt,
    this.createdAt,
  });

  factory AiKeyDto.fromJson(Map<String, dynamic> j) {
    final provider = AiProvider.fromWire(j['provider'] as String?);
    if (provider == null) {
      throw FormatException(
        'Unknown AI provider "${j['provider']}" in the ai-keys response',
      );
    }
    return AiKeyDto(
      id: _asInt(j['id']) ?? 0,
      provider: provider,
      providerLabel: j['provider_label'] as String?,
      label: j['label'] as String?,
      // The server never returns the secret — only this masked preview.
      maskedPreview: j['masked_preview'] as String?,
      isActive: j['is_active'] as bool? ?? true,
      healthStatus: j['health_status'] as String?,
      healthDetail: j['health_detail'] as String?,
      dailyTokenLimit: _asInt(j['daily_token_limit']) ?? 0,
      tokensConsumedToday: _asInt(j['tokens_consumed_today']) ?? 0,
      lastUsedAt: _asDate(j['last_used_at']),
      createdAt: _asDate(j['created_at']),
    );
  }

  final int id;
  final AiProvider provider;
  final String? providerLabel;
  final String? label;
  final String? maskedPreview;
  final bool isActive;
  final String? healthStatus;
  final String? healthDetail;
  final int dailyTokenLimit;
  final int tokensConsumedToday;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;

  AiKey toDomain() => AiKey(
        id: id,
        provider: provider,
        providerLabel: providerLabel,
        label: label,
        maskedPreview: maskedPreview,
        isActive: isActive,
        healthStatus: healthStatus,
        healthDetail: healthDetail,
        dailyTokenLimit: dailyTokenLimit,
        tokensConsumedToday: tokensConsumedToday,
        lastUsedAt: lastUsedAt,
        createdAt: createdAt,
      );
}

/// The user's own AI usage summary.
class AiUsageSummaryDto {
  const AiUsageSummaryDto({
    this.features = const [],
    this.requests = 0,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.tutorConversations = 0,
    this.periodFrom,
    this.periodTo,
  });

  factory AiUsageSummaryDto.fromJson(Map<String, dynamic> j) {
    final features = <AiUsageFeatureDto>[];
    final raw = j['features'];
    if (raw is List) {
      for (final f in raw) {
        if (f is Map<String, dynamic>) {
          features.add(AiUsageFeatureDto.fromJson(f));
        }
      }
    }

    final totals = j['totals'];
    final totalsMap =
        totals is Map ? totals.cast<String, dynamic>() : const <String, dynamic>{};

    final period = j['period'];
    final periodMap =
        period is Map ? period.cast<String, dynamic>() : const <String, dynamic>{};

    return AiUsageSummaryDto(
      features: features,
      requests: _asInt(totalsMap['requests']) ?? 0,
      promptTokens: _asInt(totalsMap['prompt_tokens']) ?? 0,
      completionTokens: _asInt(totalsMap['completion_tokens']) ?? 0,
      tutorConversations: _asInt(totalsMap['tutor_conversations']) ?? 0,
      periodFrom: periodMap['from'] as String?,
      periodTo: periodMap['to'] as String?,
    );
  }

  final List<AiUsageFeatureDto> features;
  final int requests;
  final int promptTokens;
  final int completionTokens;
  final int tutorConversations;
  final String? periodFrom;
  final String? periodTo;

  AiUsageSummary toDomain() => AiUsageSummary(
        features: features.map((f) => f.toDomain()).toList(),
        requests: requests,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        tutorConversations: tutorConversations,
        periodFrom: periodFrom,
        periodTo: periodTo,
      );
}

class AiUsageFeatureDto {
  const AiUsageFeatureDto({
    required this.key,
    required this.label,
    required this.requests,
  });

  factory AiUsageFeatureDto.fromJson(Map<String, dynamic> j) => AiUsageFeatureDto(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? j['key'] ?? '').toString(),
        requests: _asInt(j['requests']) ?? 0,
      );

  final String key;
  final String label;
  final int requests;

  AiUsageFeature toDomain() =>
      AiUsageFeature(key: key, label: label, requests: requests);
}

/// One of the user's own tutor conversations.
class TutorSessionDto {
  const TutorSessionDto({
    required this.id,
    this.questionId,
    this.turnCount = 0,
    this.rating,
    this.status,
    this.createdAt,
  });

  factory TutorSessionDto.fromJson(Map<String, dynamic> j) => TutorSessionDto(
        id: _asInt(j['id']) ?? 0,
        questionId: _asInt(j['question_id']),
        turnCount: _asInt(j['turn_count']) ?? 0,
        rating: _asInt(j['rating']),
        status: j['status'] as String?,
        createdAt: _asDate(j['created_at']),
      );

  final int id;
  final int? questionId;
  final int turnCount;
  final int? rating;
  final String? status;
  final DateTime? createdAt;

  TutorSession toDomain() => TutorSession(
        id: id,
        questionId: questionId,
        turnCount: turnCount,
        rating: rating,
        status: status,
        createdAt: createdAt,
      );
}

/// One week of the user's report card.
class ReportCardWeekDto {
  const ReportCardWeekDto({
    required this.id,
    required this.weekStartDate,
    this.accuracyPct = 0,
    this.xpEarned = 0,
    this.coinsEarned = 0,
    this.bestStreak = 0,
    this.levelsCompleted = 0,
    this.totalStarsEarned = 0,
    this.timeSpentSeconds = 0,
  });

  factory ReportCardWeekDto.fromJson(Map<String, dynamic> j) => ReportCardWeekDto(
        id: _asInt(j['id']) ?? 0,
        weekStartDate: (j['week_start_date'] ?? '').toString(),
        accuracyPct: _asDouble(j['accuracy_pct']) ?? 0,
        xpEarned: _asInt(j['xp_earned']) ?? 0,
        coinsEarned: _asInt(j['coins_earned']) ?? 0,
        bestStreak: _asInt(j['best_streak']) ?? 0,
        levelsCompleted: _asInt(j['levels_completed']) ?? 0,
        totalStarsEarned: _asInt(j['total_stars_earned']) ?? 0,
        timeSpentSeconds: _asInt(j['time_spent_seconds']) ?? 0,
      );

  final int id;
  final String weekStartDate;
  final double accuracyPct;
  final int xpEarned;
  final int coinsEarned;
  final int bestStreak;
  final int levelsCompleted;
  final int totalStarsEarned;
  final int timeSpentSeconds;

  ReportCardWeek toDomain() => ReportCardWeek(
        id: id,
        weekStartDate: weekStartDate,
        accuracyPct: accuracyPct,
        xpEarned: xpEarned,
        coinsEarned: coinsEarned,
        bestStreak: bestStreak,
        levelsCompleted: levelsCompleted,
        totalStarsEarned: totalStarsEarned,
        timeSpentSeconds: timeSpentSeconds,
      );
}


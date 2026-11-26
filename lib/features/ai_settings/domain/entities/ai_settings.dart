import 'package:meta/meta.dart';

/// One provider the server says it accepts for a bring-your-own-key (BYOK).
///
/// The catalogue comes from `GET /api/v1/app/config` (`data.ai_keys.providers`).
/// It is data, not an enum: a server can publish a new provider (for example
/// `openai-compatible`) before the client ships a build that knows its name.
@immutable
class AiProviderDescriptor {
  const AiProviderDescriptor({
    required this.value,
    required this.label,
    this.allowCustomEndpoint = false,
  });

  /// The wire value the server validates in `POST /ai-keys`.
  final String value;

  /// The server's display label. Never translated locally — a provider's own
  /// name is the same proper noun in every locale.
  final String label;

  /// Whether this provider accepts a caller-supplied `base_url`.
  final bool allowCustomEndpoint;

  AiProviderDescriptor copyWith({
    String? value,
    String? label,
    bool? allowCustomEndpoint,
  }) =>
      AiProviderDescriptor(
        value: value ?? this.value,
        label: label ?? this.label,
        allowCustomEndpoint: allowCustomEndpoint ?? this.allowCustomEndpoint,
      );
}

/// The providers an older server can be trusted to accept when it publishes
/// no catalogue at all.
///
/// This is deliberately a *closed* fallback: `openai-compatible` is not here,
/// because a server that has not said it exists must never be offered one.
enum AiProvider {
  openai,
  gemini,
  anthropic,
  deepseek,
  groq,
  mistral,
  openrouter;

  /// The wire value the server validates against.
  String get wireValue => name;

  String get label => switch (this) {
        AiProvider.openai => 'OpenAI',
        AiProvider.gemini => 'Google Gemini',
        AiProvider.anthropic => 'Anthropic',
        AiProvider.deepseek => 'DeepSeek',
        AiProvider.groq => 'Groq',
        AiProvider.mistral => 'Mistral',
        AiProvider.openrouter => 'OpenRouter',
      };

  AiProviderDescriptor get descriptor =>
      AiProviderDescriptor(value: wireValue, label: label);

  static AiProvider? fromWire(String? raw) {
    if (raw == null) return null;
    for (final p in AiProvider.values) {
      if (p.wireValue == raw) return p;
    }
    return null;
  }

  /// The last-resort picker list for a server predating `ai_keys`.
  static const List<AiProviderDescriptor> fallbackDescriptors = [
    AiProviderDescriptor(value: 'openai', label: 'OpenAI'),
    AiProviderDescriptor(value: 'gemini', label: 'Google Gemini'),
    AiProviderDescriptor(value: 'anthropic', label: 'Anthropic'),
    AiProviderDescriptor(value: 'deepseek', label: 'DeepSeek'),
    AiProviderDescriptor(value: 'groq', label: 'Groq'),
    AiProviderDescriptor(value: 'mistral', label: 'Mistral'),
    AiProviderDescriptor(value: 'openrouter', label: 'OpenRouter'),
  ];
}

/// One stored BYOK credential.
///
/// The secret is **never** returned by the server. Every response carries
/// only a masked preview (`••••last4`), so the client can show the user
/// which key is stored without ever holding the secret.
@immutable
class AiKey {
  const AiKey({
    required this.id,
    required this.provider,
    this.providerLabel,
    this.label,
    this.maskedPreview,
    this.baseUrlPreview,
    this.isActive = true,
    this.healthStatus,
    this.healthDetail,
    this.dailyTokenLimit = 0,
    this.tokensConsumedToday = 0,
    this.lastUsedAt,
    this.createdAt,
  });

  final int id;

  /// The provider's raw wire value, preserved verbatim.
  ///
  /// A new server provider must not turn the whole key list into a
  /// `FormatException`; the server's own [providerLabel] is what gets shown.
  final String provider;
  final String? providerLabel;

  /// The user's own label for this key.
  final String? label;

  /// `••••last4` — the only part of the secret the server will ever show.
  final String? maskedPreview;

  /// A non-secret endpoint preview (`base_url` / `base_url_preview`), when the
  /// server publishes one for a custom provider. Never a credential.
  final String? baseUrlPreview;

  final bool isActive;

  /// The server's health verdict for this credential.
  final String? healthStatus;
  final String? healthDetail;

  /// The daily token budget the server enforces for this key.
  final int dailyTokenLimit;

  /// How much of today's budget is already spent.
  final int tokensConsumedToday;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;

  /// How much of the daily budget is left.
  int get remainingTokens {
    final left = dailyTokenLimit - tokensConsumedToday;
    return left < 0 ? 0 : left;
  }

  /// Whether the daily budget is exhausted.
  bool get isQuotaExhausted =>
      dailyTokenLimit > 0 && tokensConsumedToday >= dailyTokenLimit;

  /// The provider name to show: the server's label wins, and an unknown wire
  /// value is shown verbatim rather than crashing the list.
  String get providerDisplayName {
    final published = providerLabel?.trim();
    if (published != null && published.isNotEmpty) return published;
    return AiProvider.fromWire(provider)?.label ?? provider;
  }

  /// What to show as the key's name.
  String get displayName {
    final l = label?.trim();
    if (l != null && l.isNotEmpty) return l;
    return providerDisplayName;
  }
}

/// One AI feature's usage in the period.
///
/// **Units and feature names only** — never the internal USD cost. That is
/// the server's rule (DF-1) and the client honours it: there is no cost
/// field to render, and none is invented.
@immutable
class AiUsageFeature {
  const AiUsageFeature({
    required this.key,
    required this.label,
    required this.requests,
  });

  final String key;

  /// The friendly label the server published.
  final String label;

  /// How many requests this feature served in the period.
  final int requests;
}

/// The user's own AI usage summary.
@immutable
class AiUsageSummary {
  const AiUsageSummary({
    this.features = const [],
    this.requests = 0,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.tutorConversations = 0,
    this.periodFrom,
    this.periodTo,
  });

  final List<AiUsageFeature> features;
  final int requests;
  final int promptTokens;
  final int completionTokens;

  /// How many tutor conversations the user has.
  final int tutorConversations;
  final String? periodFrom;
  final String? periodTo;

  int get totalTokens => promptTokens + completionTokens;
}

/// One of the user's own tutor conversations.
@immutable
class TutorSession {
  const TutorSession({
    required this.id,
    this.questionId,
    this.turnCount = 0,
    this.rating,
    this.status,
    this.createdAt,
  });

  final int id;
  final int? questionId;
  final int turnCount;

  /// The user's own rating of the conversation, when they gave one.
  final int? rating;
  final String? status;
  final DateTime? createdAt;
}

/// One week of the user's report card.
@immutable
class ReportCardWeek {
  const ReportCardWeek({
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

  final int id;

  /// The Monday of the week, as the server published it.
  final String weekStartDate;
  final double accuracyPct;
  final int xpEarned;
  final int coinsEarned;
  final int bestStreak;
  final int levelsCompleted;
  final int totalStarsEarned;
  final int timeSpentSeconds;
}

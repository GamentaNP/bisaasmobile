import 'package:meta/meta.dart';

/// The AI providers the server accepts for a bring-your-own-key (BYOK).
///
/// `AiProviderEnum` on the server; the client mirrors the list so the picker
/// cannot offer something the server would reject with a 422.
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

  static AiProvider? fromWire(String? raw) {
    if (raw == null) return null;
    for (final p in AiProvider.values) {
      if (p.wireValue == raw) return p;
    }
    return null;
  }
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
    this.isActive = true,
    this.healthStatus,
    this.healthDetail,
    this.dailyTokenLimit = 0,
    this.tokensConsumedToday = 0,
    this.lastUsedAt,
    this.createdAt,
  });

  final int id;
  final AiProvider provider;
  final String? providerLabel;

  /// The user's own label for this key.
  final String? label;

  /// `••••last4` — the only part of the secret the server will ever show.
  final String? maskedPreview;

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

  /// What to show as the key's name.
  String get displayName {
    final l = label?.trim();
    if (l != null && l.isNotEmpty) return l;
    return providerLabel ?? provider.label;
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

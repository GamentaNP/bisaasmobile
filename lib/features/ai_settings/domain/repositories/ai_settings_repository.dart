import '../../../../core/network/pagination.dart';
import '../entities/ai_settings.dart';


/// BYOK and own-usage AI reads and writes.
abstract class AiSettingsRepository {
  /// The caller's active BYOK credentials.
  Future<Page<AiKey>> getKeys({String? cursor, int perPage});

  /// Stores or refreshes a key. The secret is write-only.
  Future<AiKey> storeKey({
    required AiProvider provider,
    required String secret,
    String? label,
    int? dailyTokenLimit,
  });

  /// Revokes a key. Idempotent.
  Future<void> revokeKey(int keyId);

  /// The user's own AI usage summary.
  Future<AiUsageSummary> getUsageSummary({String period});

  /// The user's own tutor conversations.
  Future<Page<TutorSession>> getTutorSessions({
    String? cursor,
    int perPage,
    String? status,
  });

  /// The week-over-week report-card trend.
  Future<Page<ReportCardWeek>> getReportCardHistory({
    String? cursor,
    int perPage,
  });
}


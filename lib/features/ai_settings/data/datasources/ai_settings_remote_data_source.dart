import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../../../core/network/pagination.dart';
import '../../domain/entities/ai_settings.dart';
import '../models/ai_settings_dto.dart';

/// BYOK and own-usage AI surfaces.
///
/// Verified against `routes/api/v1.php` and `routes/api/v1/quiz.php`:
/// - GET    /ai-keys                 cursor list of the caller's keys (masked)
/// - POST   /ai-keys                 store or refresh a key (secret accepted once)
/// - DELETE /ai-keys/{key}           revoke (idempotent soft-disable)
/// - GET    /me/ai-usage?period=     summary (features + totals)
/// - GET    /me/ai-usage/tutor-sessions  cursor-paginated tutor history
/// - GET    /quiz/game/report-card/history  cursor-paginated week trend
///
/// **Secrets are write-only.** The server encrypts them at rest and never
/// echoes them back — every response carries only a masked preview. The
/// client therefore never reads a secret back and never stores one locally.
class AiSettingsRemoteDataSource {
  const AiSettingsRemoteDataSource(this._dio);
  final Dio _dio;

  // ── BYOK ───────────────────────────────────────────────────────────────────

  /// The caller's active keys.
  ///
  /// Cursor-paginated; the server rejects unknown query keys with a 422, so
  /// only `cursor` and `per_page` are ever sent.
  Future<Page<AiKeyDto>> getKeys({String? cursor, int perPage = 25}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/ai-keys',
      queryParameters: cursorQuery(cursor: cursor, perPage: perPage),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty ai-keys response',
        endpoint: '/ai-keys',
      );
    }
    return parsePage<AiKeyDto>(
      body,
      AiKeyDto.fromJson,
      endpoint: '/ai-keys',
    );
  }

  /// Stores or refreshes a key.
  ///
  /// Idempotent per `(user, provider, fingerprint)`: re-submitting the same
  /// key updates the row rather than duplicating it. The secret is accepted
  /// once and never returned.
  Future<AiKeyDto> storeKey({
    required AiProvider provider,
    required String secret,
    String? label,
    int? dailyTokenLimit,
  }) async {
    final payload = <String, dynamic>{
      'provider': provider.wireValue,
      'secret': secret,
    };
    if (label != null && label.trim().isNotEmpty) {
      payload['label'] = label.trim();
    }
    if (dailyTokenLimit != null) payload['daily_token_limit'] = dailyTokenLimit;

    final res = await _dio.post<Map<String, dynamic>>('/ai-keys', data: payload);
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty ai-keys store response',
        endpoint: '/ai-keys',
      );
    }
    final data = requireDataMap(body, endpoint: '/ai-keys');
    final key = data['key'];
    if (key is! Map<String, dynamic>) {
      throw const ContractViolation(
        'Stored key missing from the response',
        endpoint: '/ai-keys',
      );
    }
    return AiKeyDto.fromJson(key);
  }

  /// Revokes a key.
  ///
  /// Another user's key id is a 404, never a 403 — the server does not leak
  /// existence. Revoking is idempotent.
  Future<void> revokeKey(int keyId) async {
    await _dio.delete<void>('/ai-keys/$keyId');
  }

  // ── Own usage ──────────────────────────────────────────────────────────────

  /// The user's own AI usage summary.
  ///
  /// `period` is `7d`, `30d` or `90d`; anything else is a 400 from the
  /// server, so the client only ever sends those three.
  Future<AiUsageSummaryDto> getUsageSummary({String period = '30d'}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/me/ai-usage',
      queryParameters: {'period': period},
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty ai-usage response',
        endpoint: '/me/ai-usage',
      );
    }
    final data = requireDataMap(body, endpoint: '/me/ai-usage');
    return AiUsageSummaryDto.fromJson(data);
  }

  /// The user's own tutor conversations, newest first.
  ///
  /// Cursor-paginated. [status] is `active` or `archived`; the server
  /// rejects an unknown filter key with a 400 naming the allowed set.
  Future<Page<TutorSessionDto>> getTutorSessions({
    String? cursor,
    int perPage = 25,
    String? status,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/me/ai-usage/tutor-sessions',
      queryParameters: cursorQuery(
        cursor: cursor,
        perPage: perPage,
        extra: {
          if (status != null && status.isNotEmpty) 'filter[status]': status,
        },
      ),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty tutor-sessions response',
        endpoint: '/me/ai-usage/tutor-sessions',
      );
    }
    return parsePage<TutorSessionDto>(
      body,
      TutorSessionDto.fromJson,
      endpoint: '/me/ai-usage/tutor-sessions',
    );
  }

  /// The week-over-week report-card trend.
  ///
  /// Cursor-paginated, newest week first.
  Future<Page<ReportCardWeekDto>> getReportCardHistory({
    String? cursor,
    int perPage = 25,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/game/report-card/history',
      queryParameters: cursorQuery(cursor: cursor, perPage: perPage),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty report-card history response',
        endpoint: '/quiz/game/report-card/history',
      );
    }
    return parsePage<ReportCardWeekDto>(
      body,
      ReportCardWeekDto.fromJson,
      endpoint: '/quiz/game/report-card/history',
    );
  }
}

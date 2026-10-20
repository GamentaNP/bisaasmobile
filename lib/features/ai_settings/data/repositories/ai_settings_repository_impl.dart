import '../../../../core/network/pagination.dart';
import '../../domain/entities/ai_settings.dart';
import '../../domain/repositories/ai_settings_repository.dart';
import '../datasources/ai_settings_remote_data_source.dart';

class AiSettingsRepositoryImpl implements AiSettingsRepository {
  const AiSettingsRepositoryImpl(this._remote);
  final AiSettingsRemoteDataSource _remote;

  @override
  Future<Page<AiKey>> getKeys({String? cursor, int perPage = 25}) async {
    final page = await _remote.getKeys(cursor: cursor, perPage: perPage);
    return Page<AiKey>(
      items: page.items.map((d) => d.toDomain()).toList(),
      pagination: page.pagination,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  @override
  Future<AiKey> storeKey({
    required AiProvider provider,
    required String secret,
    String? label,
    int? dailyTokenLimit,
  }) async {
    final dto = await _remote.storeKey(
      provider: provider,
      secret: secret,
      label: label,
      dailyTokenLimit: dailyTokenLimit,
    );
    return dto.toDomain();
  }

  @override
  Future<void> revokeKey(int keyId) => _remote.revokeKey(keyId);

  @override
  Future<AiUsageSummary> getUsageSummary({String period = '30d'}) async {
    final dto = await _remote.getUsageSummary(period: period);
    return dto.toDomain();
  }

  @override
  Future<Page<TutorSession>> getTutorSessions({
    String? cursor,
    int perPage = 25,
    String? status,
  }) async {
    final page = await _remote.getTutorSessions(
      cursor: cursor,
      perPage: perPage,
      status: status,
    );
    return Page<TutorSession>(
      items: page.items.map((d) => d.toDomain()).toList(),
      pagination: page.pagination,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  @override
  Future<Page<ReportCardWeek>> getReportCardHistory({
    String? cursor,
    int perPage = 25,
  }) async {
    final page = await _remote.getReportCardHistory(
      cursor: cursor,
      perPage: perPage,
    );
    return Page<ReportCardWeek>(
      items: page.items.map((d) => d.toDomain()).toList(),
      pagination: page.pagination,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }
}

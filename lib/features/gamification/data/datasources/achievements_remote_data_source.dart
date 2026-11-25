import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../../../core/network/pagination.dart';
import '../models/achievements_dto.dart';

/// Fetches the server-authoritative achievement catalog and this user's
/// progress. No badge is unlocked and no counter is computed on the device.
///
/// All three routes are collections/objects under the canonical envelope, so
/// they go through the shared helpers: an unreadable 2xx body throws
/// [ContractViolation] instead of becoming an empty badge list.
class AchievementsRemoteDataSource {
  const AchievementsRemoteDataSource(this._dio);

  final Dio _dio;

  static const _catalogEndpoint = '/economy/achievements';
  static const _progressEndpoint = '/me/achievements/progress';
  static const _recentEndpoint = '/me/achievements/recent';

  Future<AchievementsBundleDto> fetchAchievements() async {
    final results = await Future.wait([
      _dio.get<Map<String, dynamic>>(_catalogEndpoint),
      _dio.get<Map<String, dynamic>>(_progressEndpoint),
      _dio.get<Map<String, dynamic>>(_recentEndpoint),
    ]);

    final catalog = requireDataMap(
      results[0].data,
      endpoint: _catalogEndpoint,
    );

    final progressBody = results[1].data;
    if (progressBody == null) {
      throw const ContractViolation('Empty achievement progress response',
          endpoint: _progressEndpoint);
    }
    final progressRows = extractRows(
      progressBody,
      keys: const ['items', 'progress', 'achievements'],
      endpoint: _progressEndpoint,
    );

    final recentBody = results[2].data;
    if (recentBody == null) {
      throw const ContractViolation('Empty recent achievements response',
          endpoint: _recentEndpoint);
    }
    final recentRows = extractRows(
      recentBody,
      keys: const ['items', 'achievements', 'recent'],
      endpoint: _recentEndpoint,
    );

    return AchievementsBundleDto(
      catalog: AchievementCatalogDto.fromJson(catalog),
      progress: progressRows
          .map(AchievementProgressDto.fromJson)
          .toList(growable: false),
      recentCount: recentRows.length,
    );
  }
}

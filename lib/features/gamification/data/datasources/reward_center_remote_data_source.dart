/// Data source for `GET /reward-center` (§9.5).
///
/// Bounded snapshot: no paging and no query keys. The existing
/// `/rewards/daily-checkin/*` and `/rewards/spin/*` endpoints are separate
/// mutation surfaces; this read does not call or mutate either of them.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/reward_center.dart';
import '../models/reward_center_dto.dart';

class RewardCenterRemoteDataSource {
  const RewardCenterRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/reward-center';

  Future<RewardCenterSnapshot> getSnapshot() async {
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    return RewardCenterDto.fromJson(
      requireDataMap(body, endpoint: endpoint),
      endpoint: endpoint,
    ).toDomain(endpoint: endpoint);
  }
}

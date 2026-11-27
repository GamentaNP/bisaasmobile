/// Data source for `GET /social/impact-leaders` (§9.5).
///
/// Bounded top-20 snapshot; no cursor and no query keys are accepted.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/impact_leaders.dart';
import '../models/impact_leaders_dto.dart';

class ImpactLeadersRemoteDataSource {
  const ImpactLeadersRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/social/impact-leaders';

  Future<ImpactLeadersSnapshot> getLeaders() async {
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    return ImpactLeadersDto.fromJson(
      requireDataMap(body, endpoint: endpoint),
      endpoint: endpoint,
    ).toDomain(endpoint: endpoint);
  }
}

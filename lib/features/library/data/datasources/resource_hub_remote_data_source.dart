/// Data source for `GET /quiz/resources` (§9.5).
///
/// A bounded snapshot: the endpoint rejects every query key, so no paging
/// parameters are sent. Its `detail_url` values are API member URLs; the
/// screen navigates to the app's existing library route by slug instead of
/// treating them as web links.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/resource_hub.dart';
import '../models/resource_hub_dto.dart';

class ResourceHubRemoteDataSource {
  const ResourceHubRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/quiz/resources';

  Future<ResourceHub> getHub() async {
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    return ResourceHubDto.fromJson(
      requireDataMap(body, endpoint: endpoint),
      endpoint: endpoint,
    ).toDomain(endpoint: endpoint);
  }
}

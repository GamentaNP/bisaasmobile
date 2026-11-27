/// Data source for `GET /quiz/analytics/overview`.
///
/// The endpoint takes no query parameters at all — even a harmless-looking
/// `?period=...` is rejected by the server. It is a bounded snapshot, not a
/// collection, so there is no cursor and no `page`.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/analytics.dart';
import '../models/analytics_dto.dart';

class AnalyticsRemoteDataSource {
  const AnalyticsRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/quiz/analytics/overview';

  Future<AnalyticsOverview> getOverview() async {
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = requireDataMap(body, endpoint: endpoint);
    return AnalyticsOverviewDto.fromJson(data, endpoint: endpoint).toDomain();
  }
}

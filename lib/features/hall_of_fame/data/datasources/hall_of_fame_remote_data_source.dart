/// Data source for `GET /quiz/hall-of-fame`.
///
/// The server publishes a bounded snapshot (top 100) and rejects every bare
/// query key except `filter`. There is no cursor here — sending `page` would
/// be a 400, not a second page.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/hall_of_fame.dart';
import '../models/hall_of_fame_dto.dart';

class HallOfFameRemoteDataSource {
  const HallOfFameRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/quiz/hall-of-fame';

  Future<HallOfFameSnapshot> getSnapshot({
    required String recordType,
    required String period,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'filter[record_type]': recordType,
      'filter[period]': period,
      if (search != null && search.isNotEmpty) 'filter[search]': search,
    };
    final res = await _dio.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: query,
    );
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = requireDataMap(body, endpoint: endpoint);
    return HallOfFameDto.fromJson(data, endpoint: endpoint).toDomain();
  }
}

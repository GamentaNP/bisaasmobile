/// Data source for `GET /quiz/creator/applications/current` (§9.5).
///
/// Status only. The one-way submit remains at
/// `POST /quiz/creator/applications` and is never called here.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/creator_application.dart';
import '../models/creator_application_dto.dart';

class CreatorApplicationRemoteDataSource {
  const CreatorApplicationRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/quiz/creator/applications/current';

  Future<CreatorApplicationStatus> getCurrent() async {
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    return CreatorApplicationDto.fromJson(
      requireDataMap(body, endpoint: endpoint),
      endpoint: endpoint,
    ).toDomain(endpoint: endpoint);
  }
}

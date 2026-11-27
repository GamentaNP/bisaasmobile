/// Data source for `GET /quiz/profile-onboarding/status` (§9.5).
///
/// Read-only. The wizard write stays at `POST /quiz/profile-onboarding` and is
/// deliberately not called from this surface.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/profile_onboarding_status.dart';
import '../models/profile_onboarding_status_dto.dart';

class ProfileOnboardingStatusRemoteDataSource {
  const ProfileOnboardingStatusRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/quiz/profile-onboarding/status';

  Future<ProfileOnboardingStatus> getStatus() async {
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    return ProfileOnboardingStatusDto.fromJson(
      requireDataMap(body, endpoint: endpoint),
      endpoint: endpoint,
    ).toDomain(endpoint: endpoint);
  }
}

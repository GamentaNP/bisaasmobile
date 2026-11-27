/// Data source for the two public-profile reads (§9.5).
///
/// Both are bounded snapshots — no cursor and no bare query keys. The compare
/// endpoint accepts exactly one key, `username`; the show endpoint accepts
/// none. A non-public profile 404s at the server; the PNG card route is not
/// mirrored and is never called from this bearer client.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/public_profile.dart';
import '../models/public_profile_dto.dart';

class PublicProfileRemoteDataSource {
  const PublicProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PublicProfileSnapshot> getProfile(String username) async {
    final endpoint = '/quiz/profiles/$username';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    return PublicProfileDto.fromJson(
      requireDataMap(body, endpoint: endpoint),
      endpoint: endpoint,
    ).toDomain(endpoint: endpoint);
  }

  Future<ProfileComparison> compare(String username) async {
    const endpoint = '/quiz/profiles/compare';
    final res = await _dio.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: <String, dynamic>{'username': username},
    );
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    return ProfileComparisonDto.fromJson(
      requireDataMap(body, endpoint: endpoint),
      endpoint: endpoint,
    ).toDomain(endpoint: endpoint);
  }
}

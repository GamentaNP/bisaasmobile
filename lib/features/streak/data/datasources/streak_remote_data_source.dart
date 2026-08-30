// ignore_for_file: avoid_dynamic_calls, cast_nullable_to_non_nullable

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../models/streak_dto.dart';

/// Verified server routes:
/// - GET /api/v1/quiz/streak
/// - POST /api/v1/donations/freeze-streak
class StreakRemoteDataSource {
  const StreakRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  Future<StreakDto> getStreak() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/streak');
    final body = res.data;
    if (body == null) return const StreakDto(currentStreak: 0, longestStreak: 0);
    // Envelope: {success, data: {current_streak,...}, message}
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return StreakDto.fromJson(data);
    }
    // Fallback via ApiResponse wrapper
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return StreakDto.fromJson(env.data!);
    } catch (_) {}
    // Last fallback: treat body itself as streak payload
    if (body.containsKey('current_streak')) {
      return StreakDto.fromJson(body);
    }
    return const StreakDto(currentStreak: 0, longestStreak: 0);
  }

  Future<FreezeStreakDto> freezeStreak({String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/donations/freeze-streak',
      data: {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body == null) return const FreezeStreakDto(frozen: false);
    if (body.containsKey('frozen') || body.containsKey('success')) {
      return FreezeStreakDto.fromJson(body);
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return FreezeStreakDto.fromJson(data);
    }
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return FreezeStreakDto.fromJson(env.data!);
    } catch (_) {}
    return const FreezeStreakDto(frozen: false);
  }
}

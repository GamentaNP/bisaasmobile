import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../models/rewards_dto.dart';

/// Daily check-in and spin-wheel client.
///
/// Verified server routes (`bisaas/routes/api/monetization.php:58-71`):
///   * `GET  /rewards/daily-checkin/status`  — enveloped
///   * `POST /rewards/daily-checkin`         — enveloped; 409 when already claimed
///   * `GET  /rewards/spin/status`           — **raw JSON, no envelope**
///   * `POST /rewards/spin`                  — **raw JSON, no envelope**, and a
///     422 (no spin available) also answers raw
///
/// The spin pair carries an optional `Idempotency-Key`; we always send one so a
/// retry cannot double-spin.
class RewardsRemoteDataSource {
  const RewardsRemoteDataSource(this._dio);

  final Dio _dio;
  static const _uuid = Uuid();

  Map<String, dynamic>? _envelopeData(Map<String, dynamic>? body) {
    if (body == null) return null;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      return env.data;
    } catch (_) {
      return null;
    }
  }

  Future<CheckInStatusDto> getCheckInStatus() async {
    final res = await _dio.get<Map<String, dynamic>>('/rewards/daily-checkin/status');
    final data = _envelopeData(res.data);
    if (data == null) throw Exception('Check-in status missing from response');
    return CheckInStatusDto.fromJson(data);
  }

  /// 409 (already claimed today) is a normal outcome, not a failure: the server
  /// returns the same payload shape with a `reason`. Surface it rather than
  /// throwing.
  Future<CheckInResultDto> claimCheckIn({String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/rewards/daily-checkin',
        data: const {},
        options: Options(headers: {'Idempotency-Key': key}),
      );
      final data = _envelopeData(res.data);
      if (data == null) throw Exception('Check-in response missing');
      return CheckInResultDto.fromJson(data);
    } on DioException catch (e) {
      // The 409 body carries the real reason; parse it instead of guessing.
      final error = e.response?.data;
      if (e.response?.statusCode == 409 && error is Map<String, dynamic>) {
        final details = error['error'];
        final inner = details is Map<String, dynamic> ? details['details'] : null;
        if (inner is Map<String, dynamic>) {
          return CheckInResultDto.fromJson({...inner, 'credited': false});
        }
        return CheckInResultDto(
          credited: false,
          amount: 0,
          newBalance: 0,
          streakDay: 0,
          reason: details is Map<String, dynamic> ? details['code'] as String? : 'CONFLICT',
        );
      }
      rethrow;
    }
  }

  /// Raw body, outside the envelope.
  Future<SpinStatusDto> getSpinStatus() async {
    final res = await _dio.get<Map<String, dynamic>>('/rewards/spin/status');
    final body = res.data;
    if (body == null) throw Exception('Spin status missing from response');
    // Defensive: tolerate an enveloped build too.
    if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
      return SpinStatusDto.fromJson(body['data'] as Map<String, dynamic>);
    }
    return SpinStatusDto.fromJson(body);
  }

  /// Raw body, outside the envelope. `spun: false` with a `reason` is returned
  /// as a value rather than thrown — "come back tomorrow" is not an error.
  Future<SpinResultDto> spin({String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/rewards/spin',
        data: const {},
        options: Options(headers: {'Idempotency-Key': key}),
      );
      final body = res.data;
      if (body == null) throw Exception('Spin response missing');
      if (body['data'] is Map<String, dynamic>) {
        return SpinResultDto.fromJson(body['data'] as Map<String, dynamic>);
      }
      return SpinResultDto.fromJson(body);
    } on DioException catch (e) {
      // 422 also answers raw, with spun:false and a reason.
      final body = e.response?.data;
      if ((e.response?.statusCode == 422 || e.response?.statusCode == 409) &&
          body is Map<String, dynamic>) {
        return SpinResultDto.fromJson({
          ...body,
          'spun': false,
          'reason': body['reason'] ?? 'No spin available right now',
        });
      }
      rethrow;
    }
  }
}

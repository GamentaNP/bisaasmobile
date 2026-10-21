import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/api_response.dart';
import '../models/streak_dto.dart';

/// Verified server routes (bisaas routes/api/v1/quiz.php:264-295, monetization.php:47):
/// - GET  /quiz/streak                  (live, QuizDailyApiController@streak)
/// - POST /donations/freeze-streak      (live)
/// - GET  /quiz/streak/repair           (eligibility check)
/// - POST /quiz/streak/repair           (50 coins)
/// - GET  /quiz/streak/insurance        (banked tokens + cost)
/// - POST /quiz/streak/insurance        (200 coins per token, stack limit 3)
/// - POST /quiz/streak/insurance/use    (spend a banked token)
/// - GET  /quiz/streak/wager            (active wager)
/// - POST /quiz/streak/wager            (open wager; 201 on create, 200 on replay)
///
/// All self-service mutations carry an `Idempotency-Key` (the server 422s
/// `IDEMPOTENCY_KEY_REQUIRED` without it) and are throttled `quiz-answer`.
///
/// **A failure is never a zero streak.** This data source used to answer a
/// transport error or a drifted body with
/// `StreakDto(currentStreak: 0, longestStreak: 0)` — which is a *plausible*
/// business value, not an obviously broken one. A user whose streak had
/// actually reset, and a user whose server was down, saw exactly the same
/// screen. Every read here now throws instead, so the failure is visible and
/// the zero state means what it says.
class StreakRemoteDataSource {
  const StreakRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  /// Reads the `data` object out of a streak envelope.
  ///
  /// The streak endpoints publish the payload in three shapes depending on
  /// the route (a bare object, `{data: {...}}`, and the canonical envelope),
  /// so all three are accepted — and a body that matches none of them is a
  /// contract drift, not an empty streak.
  Map<String, dynamic> _data(Map<String, dynamic>? body, String endpoint) {
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      final parsed = env.data;
      if (parsed != null) return parsed;
    } on Object {
      // Fall through to the bare-body check below.
    }
    if (body.containsKey('current_streak') ||
        body.containsKey('frozen') ||
        body.containsKey('success') ||
        body.containsKey('active_count')) {
      return body;
    }
    throw ContractViolation(
      'Streak payload not understood',
      endpoint: endpoint,
    );
  }

  Future<StreakDto> getStreak() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/streak');
    return StreakDto.fromJson(_data(res.data, '/quiz/streak'));
  }

  Future<FreezeStreakDto> freezeStreak({String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/donations/freeze-streak',
      data: {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body != null &&
        (body.containsKey('frozen') || body.containsKey('success'))) {
      return FreezeStreakDto.fromJson(body);
    }
    return FreezeStreakDto.fromJson(_data(body, '/donations/freeze-streak'));
  }

  // ── WO-6 Streak self-service ──────────────────────────────────────────────

  /// GET /quiz/streak/repair — eligibility check, no coins spent.
  Future<StreakRepairEligibilityDto> getRepairEligibility() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/streak/repair');
    return StreakRepairEligibilityDto.fromJson(
      _data(res.data, '/quiz/streak/repair'),
    );
  }

  /// POST /quiz/streak/repair — spend 50 coins to bridge a missed day.
  Future<StreakRepairResultDto> repairStreak({String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/streak/repair',
      data: {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty response body',
        endpoint: '/quiz/streak/repair',
      );
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return StreakRepairResultDto.fromJson(data);
    final success = body['success'] as bool? ?? false;
    return StreakRepairResultDto(repaired: success, message: body['message'] as String?);
  }

  /// POST /quiz/streak/insurance — spend 200 coins for an auto-repair token.
  Future<StreakInsuranceResultDto> buyInsurance({String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/streak/insurance',
      data: {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty response body',
        endpoint: '/quiz/streak/insurance',
      );
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return StreakInsuranceResultDto.fromJson(data);
    final success = body['success'] as bool? ?? false;
    return StreakInsuranceResultDto(purchased: success, message: body['message'] as String?);
  }

  /// GET /quiz/streak/insurance — banked auto-repair tokens + cost.
  Future<StreakInsuranceStatusDto> getInsuranceStatus() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/streak/insurance');
    return StreakInsuranceStatusDto.fromJson(
      _data(res.data, '/quiz/streak/insurance'),
    );
  }

  /// POST /quiz/streak/insurance/use — spend a banked token to bridge a missed day.
  Future<StreakInsuranceUsedDto> useInsurance({String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/streak/insurance/use',
      data: {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return StreakInsuranceUsedDto.fromJson(
      _data(res.data, '/quiz/streak/insurance/use'),
    );
  }

  /// GET /quiz/streak/wager — active wager status.
  Future<StreakWagerStatusDto> getActiveWager() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/streak/wager');
    return StreakWagerStatusDto.fromJson(_data(res.data, '/quiz/streak/wager'));
  }

  /// POST /quiz/streak/wager — commit a coin wager on N consecutive days.
  Future<StreakWagerOpenedDto> openWager({
    int coins = 100,
    int days = 7,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/streak/wager',
      data: {'coins': coins, 'days': days},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty response body',
        endpoint: '/quiz/streak/wager',
      );
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return StreakWagerOpenedDto.fromJson(data);
    final success = body['success'] as bool? ?? false;
    return StreakWagerOpenedDto(opened: success, message: body['message'] as String?);
  }
}

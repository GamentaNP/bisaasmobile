import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

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
class StreakRemoteDataSource {
  const StreakRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  Future<StreakDto> getStreak() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/streak');
    final body = res.data;
    if (body == null) return const StreakDto(currentStreak: 0, longestStreak: 0);
    final data = body['data'];
    if (data is Map<String, dynamic>) return StreakDto.fromJson(data);
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return StreakDto.fromJson(env.data!);
    } catch (_) {}
    if (body.containsKey('current_streak')) return StreakDto.fromJson(body);
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
    if (data is Map<String, dynamic>) return FreezeStreakDto.fromJson(data);
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return FreezeStreakDto.fromJson(env.data!);
    } catch (_) {}
    return const FreezeStreakDto(frozen: false);
  }

  // ── WO-6 Streak self-service ──────────────────────────────────────────────

  /// GET /quiz/streak/repair — eligibility check, no coins spent.
  Future<StreakRepairEligibilityDto> getRepairEligibility() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/streak/repair');
    final body = res.data;
    if (body == null) return const StreakRepairEligibilityDto(eligible: false);
    final data = body['data'];
    if (data is Map<String, dynamic>) return StreakRepairEligibilityDto.fromJson(data);
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return StreakRepairEligibilityDto.fromJson(env.data!);
    } catch (_) {}
    return const StreakRepairEligibilityDto(eligible: false);
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
    if (body == null) return const StreakRepairResultDto(repaired: false, message: 'Empty response');
    final data = body['data'];
    if (data is Map<String, dynamic>) return StreakRepairResultDto.fromJson(data);
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return StreakRepairResultDto.fromJson(env.data!);
    } catch (_) {}
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
    if (body == null) return const StreakInsuranceResultDto(purchased: false, message: 'Empty response');
    final data = body['data'];
    if (data is Map<String, dynamic>) return StreakInsuranceResultDto.fromJson(data);
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return StreakInsuranceResultDto.fromJson(env.data!);
    } catch (_) {}
    final success = body['success'] as bool? ?? false;
    return StreakInsuranceResultDto(purchased: success, message: body['message'] as String?);
  }

  /// GET /quiz/streak/insurance — banked auto-repair tokens + cost.
  Future<StreakInsuranceStatusDto> getInsuranceStatus() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/streak/insurance');
    final body = res.data;
    if (body == null) {
      return const StreakInsuranceStatusDto(
        activeCount: 0,
        maxActive: 0,
        costCoins: 0,
        canPurchase: false,
      );
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return StreakInsuranceStatusDto.fromJson(data);
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return StreakInsuranceStatusDto.fromJson(env.data!);
    } catch (_) {}
    return const StreakInsuranceStatusDto(
      activeCount: 0,
      maxActive: 0,
      costCoins: 0,
      canPurchase: false,
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
    final body = res.data;
    if (body == null) return const StreakInsuranceUsedDto(used: false);
    final data = body['data'];
    if (data is Map<String, dynamic>) return StreakInsuranceUsedDto.fromJson(data);
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return StreakInsuranceUsedDto.fromJson(env.data!);
    } catch (_) {}
    return StreakInsuranceUsedDto.fromJson(body);
  }

  /// GET /quiz/streak/wager — active wager status.
  Future<StreakWagerStatusDto> getActiveWager() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/streak/wager');
    final body = res.data;
    if (body == null) return const StreakWagerStatusDto(wager: null, currentStreak: 0);
    final data = body['data'];
    if (data is Map<String, dynamic>) return StreakWagerStatusDto.fromJson(data);
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return StreakWagerStatusDto.fromJson(env.data!);
    } catch (_) {}
    return const StreakWagerStatusDto(wager: null, currentStreak: 0);
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
    if (body == null) return const StreakWagerOpenedDto(opened: false, message: 'Empty response');
    final data = body['data'];
    if (data is Map<String, dynamic>) return StreakWagerOpenedDto.fromJson(data);
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      if (env.data != null) return StreakWagerOpenedDto.fromJson(env.data!);
    } catch (_) {}
    final success = body['success'] as bool? ?? false;
    return StreakWagerOpenedDto(opened: success, message: body['message'] as String?);
  }
}



import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../models/game_models.dart';
import '../models/mission_dto.dart';

/// Remote data source for the Duolingo-style game world engine.
///
/// All endpoints require auth (Bearer PAT via DioClient interceptors).
class GameRemoteDataSource {
  const GameRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  // ── Worlds ──────────────────────────────────────────────────────────────────

  /// `GET /api/v1/quiz/game/worlds`
  /// Returns lightweight world list with per-world star progress.
  Future<List<GameWorldSummaryDto>> getWorlds() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/game/worlds');
    final body = res.data;
    if (body == null) return [];
    try {
      final env = ApiResponse.fromJson(body, (data) => data);
      final raw = env.data;
      if (raw is Map && raw['worlds'] is List) {
        return (raw['worlds'] as List)
            .cast<Map<String, dynamic>>()
            .map(GameWorldSummaryDto.fromJson)
            .toList();
      }
      // Direct list
      if (raw is List) {
        return raw.cast<Map<String, dynamic>>().map(GameWorldSummaryDto.fromJson).toList();
      }
    } catch (_) {
      // Fallback: try direct parse
      final data = body['data'];
      if (data is Map && data['worlds'] is List) {
        return (data['worlds'] as List)
            .cast<Map<String, dynamic>>()
            .map(GameWorldSummaryDto.fromJson)
            .toList();
      }
    }
    return [];
  }

  // ── Missions ────────────────────────────────────────────────────────────────

  /// `GET /quiz/game/missions/dashboard`
  ///
  /// The `data` here is a **bare JSON array**, not `{items: [...]}` — verified
  /// 2026-09-27, 49 missions returned. Optional `cadence` filter is one of
  /// daily | weekly | campaign.
  Future<List<MissionDto>> getMissions({String? cadence}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/game/missions/dashboard',
      queryParameters: cadence == null ? null : {'cadence': cadence},
    );
    final body = res.data;
    if (body == null) return const [];

    List<dynamic>? rows;
    final data = body['data'];
    if (data is List) {
      rows = data;
    } else if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['missions'];
      if (items is List) rows = items;
    }
    if (rows == null) {
      try {
        final env = ApiResponse.fromJson(body, (json) => json);
        final d = env.data;
        if (d is List) rows = d;
      } catch (_) {}
    }
    if (rows == null) return const [];
    return rows.whereType<Map<String, dynamic>>().map(MissionDto.fromJson).toList();
  }

  /// `PUT /quiz/game/missions/{mission}/claim`
  ///
  /// The `POST` alias is also registered by the server. Idempotency-Key is
  /// required — without it the API answers 422 `IDEMPOTENCY_KEY_REQUIRED`, so
  /// a retry can never double-credit a reward.
  Future<MissionClaimDto> claimMission(int missionId, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.put<Map<String, dynamic>>(
      '/quiz/game/missions/$missionId/claim',
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return MissionClaimDto.fromJson(_dataOrEmpty(res.data));
  }

  /// `POST /quiz/game/missions/claims` — claim everything claimable in one call.
  Future<MissionBulkClaimDto> claimAllMissions({String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/game/missions/claims',
      data: const {},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return MissionBulkClaimDto.fromJson(_dataOrEmpty(res.data));
  }

  Map<String, dynamic> _dataOrEmpty(Map<String, dynamic>? body) {
    if (body == null) return const {};
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return body;
  }

  // ── World Map ───────────────────────────────────────────────────────────────

  /// `GET /api/v1/quiz/game/world/{slug}/map`
  /// Returns full chapter/level tree with per-level star progress.
  Future<GameWorldMapDto?> getWorldMap(String slug) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/game/world/$slug/map');
    final body = res.data;
    if (body == null) return null;
    try {
      final env = ApiResponse.fromJson(body, (data) => data);
      final raw = env.data;
      if (raw is Map<String, dynamic>) {
        return GameWorldMapDto.fromJson(raw);
      }
    } catch (_) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return GameWorldMapDto.fromJson(data);
      }
    }
    return null;
  }

  // ── Missions ────────────────────────────────────────────────────────────────

  /// `GET /api/v1/quiz/game/missions/dashboard`
  Future<Map<String, dynamic>?> getMissionsDashboard() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/game/missions/dashboard');
    final body = res.data;
    if (body == null) return null;
    try {
      final env = ApiResponse.fromJson(body, (data) => data);
      final raw = env.data;
      if (raw is Map<String, dynamic>) return raw;
    } catch (_) {
      return body['data'] as Map<String, dynamic>?;
    }
    return null;
  }
}

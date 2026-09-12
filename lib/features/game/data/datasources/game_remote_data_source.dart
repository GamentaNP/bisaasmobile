// ignore_for_file: cast_nullable_to_non_nullable

import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/game_models.dart';

/// Remote data source for the Duolingo-style game world engine.
///
/// All endpoints require auth (Bearer PAT via DioClient interceptors).
class GameRemoteDataSource {
  const GameRemoteDataSource(this._dio);
  final Dio _dio;

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

  /// `POST /api/v1/quiz/game/missions/{missionId}/claim`
  Future<Map<String, dynamic>> claimMission(int missionId) async {
    final res = await _dio.post<Map<String, dynamic>>('/quiz/game/missions/$missionId/claim');
    return res.data ?? {};
  }
}

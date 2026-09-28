import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import 'data/datasources/game_remote_data_source.dart';
import 'data/models/game_models.dart';
import 'data/models/mission_dto.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final gameRemoteDataSourceProvider = Provider<GameRemoteDataSource>((ref) {
  return GameRemoteDataSource(DioClient.instance.dio);
});

/// All active worlds (lightweight list).
/// Auto-disposed to avoid stale data after a user session.
final gameWorldsProvider = FutureProvider.autoDispose<List<GameWorldSummaryDto>>((ref) async {
  final remote = ref.watch(gameRemoteDataSourceProvider);
  return remote.getWorlds();
});

/// Full map for a specific world by slug.
final gameWorldMapProvider =
    FutureProvider.autoDispose.family<GameWorldMapDto?, String>((ref, slug) async {
  final remote = ref.watch(gameRemoteDataSourceProvider);
  return remote.getWorldMap(slug);
});

/// Missions dashboard.
///
/// `GET /api/v1/quiz/game/missions/dashboard` returns a **bare JSON array** in
/// `data` (49 missions for the QA account on 2026-09-27), so the parse lives
/// in the data source rather than in the envelope mapper.
final gameMissionsProvider =
    FutureProvider.autoDispose<List<MissionDto>>((ref) async {
  final remote = ref.watch(gameRemoteDataSourceProvider);
  return remote.getMissions();
});

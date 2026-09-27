import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import 'data/datasources/game_remote_data_source.dart';
import 'data/models/game_models.dart';

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
final gameMissionsDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final remote = ref.watch(gameRemoteDataSourceProvider);
  return remote.getMissionsDashboard();
});

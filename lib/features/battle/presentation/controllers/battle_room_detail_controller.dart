/// Provider for the scoped battle-room detail read (§9.5).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/battle_room_detail_remote_data_source.dart';
import '../../data/repositories/battle_room_detail_repository_impl.dart';
import '../../domain/entities/battle_room_detail.dart';
import '../../domain/repositories/battle_room_detail_repository.dart';

final battleRoomDetailRemoteDataSourceProvider =
    Provider<BattleRoomDetailRemoteDataSource>((ref) {
  return BattleRoomDetailRemoteDataSource(ref.watch(dioProvider));
});

final battleRoomDetailRepositoryProvider =
    Provider<BattleRoomDetailRepository>((ref) {
  return BattleRoomDetailRepositoryImpl(
    ref.watch(battleRoomDetailRemoteDataSourceProvider),
  );
});

final battleRoomDetailProvider =
    FutureProvider.family<BattleRoomDetail, String>((ref, lobbyId) {
  return ref.watch(battleRoomDetailRepositoryProvider).getLobby(lobbyId);
});

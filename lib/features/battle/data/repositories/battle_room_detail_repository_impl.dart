import '../../domain/entities/battle_room_detail.dart';
import '../../domain/repositories/battle_room_detail_repository.dart';
import '../datasources/battle_room_detail_remote_data_source.dart';

class BattleRoomDetailRepositoryImpl implements BattleRoomDetailRepository {
  const BattleRoomDetailRepositoryImpl(this._remote);

  final BattleRoomDetailRemoteDataSource _remote;

  @override
  Future<BattleRoomDetail> getLobby(String lobbyId) => _remote.getLobby(lobbyId);
}

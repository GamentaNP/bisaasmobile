import '../entities/battle_room_detail.dart';

/// Read boundary for the scoped lobby detail.
// ignore: one_member_abstracts — repository boundary per Clean Arch.
abstract class BattleRoomDetailRepository {
  Future<BattleRoomDetail> getLobby(String lobbyId);
}

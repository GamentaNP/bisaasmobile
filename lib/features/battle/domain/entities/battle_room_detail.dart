/// Pure Dart view of `GET /quiz/battle-rooms/{lobby}` (§9.5).
///
/// Deliberately narrow: the server omits question ids and reward-settlement
/// keys for this participant-only read, and the entity mirrors that omission.
/// No score, rank or settlement is computed on-device.
library;

class BattleRoomDetail {
  const BattleRoomDetail({required this.lobby});
  final BattleRoomLobby lobby;
}

class BattleRoomLobby {
  const BattleRoomLobby({
    required this.id,
    required this.code,
    required this.host,
    required this.participants,
    this.mode,
    this.queueType,
    this.status,
    this.wagerCoins = 0,
    this.maxPlayers,
    this.startedAt,
    this.finishedAt,
    this.scheduledFor,
  });

  final int id;
  final String code;
  final BattleRoomMember host;
  final List<BattleRoomParticipant> participants;
  final String? mode;
  final String? queueType;
  final String? status;
  final int wagerCoins;
  final int? maxPlayers;
  final String? startedAt;
  final String? finishedAt;
  final String? scheduledFor;
}

class BattleRoomMember {
  const BattleRoomMember({required this.id, this.name});
  final int id;
  final String? name;
}

class BattleRoomParticipant {
  const BattleRoomParticipant({
    required this.id,
    required this.userId,
    this.userName,
    this.score = 0,
    this.rank,
    this.isSpectating = false,
    this.joinedAt,
    this.evictedAt,
  });

  final int id;
  final int userId;
  final String? userName;
  final int score;
  final int? rank;
  final bool isSpectating;
  final String? joinedAt;
  final String? evictedAt;
}

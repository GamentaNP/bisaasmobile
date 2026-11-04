import '../entities/battle.dart';
import '../entities/battle_lobby.dart';

abstract class BattleRepository {
  Future<BattleToken> getFirebaseToken();
  Future<BattleMatch> findMatch({int? categoryId, int totalQuestions = 10});
  Future<List<Map<String, dynamic>>> getLeaderboard(String boardId);

  /// Create a private lobby the caller hosts — `POST /quiz/battle-rooms`.
  Future<BattleLobby> createLobby({
    required String mode,
    int wagerCoins = 0,
    String? idempotencyKey,
  });

  /// Invite a user by email — `POST /quiz/battle-rooms/{lobby}/invitations`.
  Future<BattleInvitation> inviteToLobby({
    required int lobbyId,
    required String email,
    String? idempotencyKey,
  });

  /// Accept a lobby invitation — `PUT /quiz/invitations/{id}/acceptance`.
  Future<BattleLobby> acceptLobbyInvitation({
    required int notificationId,
    String? idempotencyKey,
  });
}

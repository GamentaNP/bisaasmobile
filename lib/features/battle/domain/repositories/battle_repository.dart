import '../entities/battle.dart';
import '../entities/battle_lobby.dart';

abstract class BattleRepository {
  Future<BattleToken> getFirebaseToken();
  Future<BattleMatch> findMatch({
    int? categoryId,
    int totalQuestions = 10,
    String mode = '1v1',
  });

  /// Join a specific open battle by its RTDB id. Returns the same canonical
  /// payload as create, including a fresh single-use `firebase_token`.
  Future<BattleMatch> joinBattle(String firebaseBattleId);

  /// Authoritative result, parsed through the same payload rules as the
  /// realtime snapshot (winner may be `winner` or `winner_id`).
  Future<Map<String, dynamic>> getBattleResults(String firebaseBattleId);
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

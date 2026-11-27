import '../../../../core/network/api_failure.dart';
import '../../domain/entities/battle.dart';
import '../../domain/entities/battle_lobby.dart';
import '../../domain/repositories/battle_repository.dart';
import '../datasources/battle_remote_data_source.dart';
import '../models/battle_payload.dart';

class BattleRepositoryImpl implements BattleRepository {
  const BattleRepositoryImpl(this._remote);
  final BattleRemoteDataSource _remote;

  @override
  Future<BattleToken> getFirebaseToken() async {
    final m = await _remote.getFirebaseToken();
    final token = BattlePayload.firebaseToken(m);
    final expRaw = m['expires_at'] ?? m['expiresAt'];
    DateTime? exp;
    if (expRaw is String) exp = DateTime.tryParse(expRaw);
    return BattleToken(token: token, expiresAt: exp);
  }

  @override
  Future<BattleMatch> findMatch({
    int? categoryId,
    int totalQuestions = 10,
    String mode = '1v1',
  }) async {
    final raw = await _remote.findMatch(
      categoryId: categoryId,
      totalQuestions: totalQuestions,
      mode: mode,
    );
    BattleMatch match;
    try {
      // A match with no questions is contract drift, never an empty arena.
      match = BattlePayload.parse(raw, endpoint: BattlePayload.createEndpoint);
    } on ContractViolation catch (e) {
      // The legacy create response has no questions and often no `id` beyond
      // the numeric battle id. Join by the RTDB handle to get the canonical
      // payload before giving up — the create itself is not yet playable.
      final handle = BattlePayload.stringOf(
        raw['firebase_battle_id'] ?? raw['battle_id'] ?? raw['id'],
      );
      if (handle.isEmpty) rethrow;
      try {
        return await joinBattle(handle);
      } on Object {
        throw e;
      }
    }

    // A fresh token is minted by create; fall back to the token endpoint only
    // for a legacy server that did not send one. The fallback token is used
    // once and never written over a token the create response provided.
    if (match.firebaseToken.isEmpty) {
      final fallback = await getFirebaseToken();
      match = _withToken(match, fallback.token);
    }
    return match;
  }

  @override
  Future<BattleMatch> joinBattle(String firebaseBattleId) async {
    final raw = await _remote.join(firebaseBattleId);
    final match = BattlePayload.parse(
      raw,
      endpoint: BattlePayload.joinEndpoint,
      base: BattleMatch(
        id: firebaseBattleId,
        status: 'waiting',
        firebaseBattleId: firebaseBattleId,
      ),
    );
    if (match.firebaseToken.isEmpty) {
      final fallback = await getFirebaseToken();
      return _withToken(match, fallback.token);
    }
    return match;
  }

  @override
  Future<Map<String, dynamic>> getBattleResults(String firebaseBattleId) =>
      _remote.getResults(firebaseBattleId);

  BattleMatch _withToken(BattleMatch match, String token) =>
      match.copyWith(firebaseToken: token);

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(String boardId) => _remote.getLeaderboard(boardId);

  @override
  Future<BattleLobby> createLobby({
    required String mode,
    int wagerCoins = 0,
    String? idempotencyKey,
  }) async {
    final m = await _remote.createLobby(
      mode: mode,
      wagerCoins: wagerCoins,
      idempotencyKey: idempotencyKey,
    );
    return _lobby(m, '/quiz/battle-rooms');
  }

  @override
  Future<BattleInvitation> inviteToLobby({
    required int lobbyId,
    required String email,
    String? idempotencyKey,
  }) async {
    final m = await _remote.inviteToLobby(
      lobbyId: lobbyId,
      email: email,
      idempotencyKey: idempotencyKey,
    );
    try {
      return BattleInvitation.fromJson(m);
    } on FormatException catch (e) {
      throw ContractViolation(
        'Invitation payload not understood: ${e.message}',
        endpoint: '/quiz/battle-rooms/{lobby}/invitations',
      );
    }
  }

  @override
  Future<BattleLobby> acceptLobbyInvitation({
    required int notificationId,
    String? idempotencyKey,
  }) async {
    final m = await _remote.acceptLobbyInvitation(
      notificationId: notificationId,
      idempotencyKey: idempotencyKey,
    );
    return _lobby(m, '/quiz/invitations/{notification}/acceptance');
  }

  /// A lobby payload the client cannot read is contract drift, not an empty
  /// room: the id is the handle every later call needs.
  BattleLobby _lobby(Map<String, dynamic> json, String endpoint) {
    try {
      return BattleLobby.fromJson(json);
    } on FormatException catch (e) {
      throw ContractViolation(
        'Lobby payload not understood: ${e.message}',
        endpoint: endpoint,
      );
    }
  }
}

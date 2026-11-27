import 'package:dio/dio.dart';

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
    final token = BattlePayload.stringOf(
      m['firebase_token'] ?? m['token'] ?? m['custom_token'],
    );
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
    final isTeam = BattlePayload.teamModes.contains(mode);
    final candidates = <Future<Map<String, dynamic>> Function()>[
      if (isTeam) () => _remote.createTeamMatch(mode: mode),
      if (isTeam) () => _remote.createQuickMatch(mode: mode),
      () => _remote.findMatch(
            categoryId: categoryId,
            totalQuestions: totalQuestions,
            mode: mode,
          ),
    ];

    Object? lastError;
    for (var i = 0; i < candidates.length; i++) {
      try {
        final raw = await candidates[i]();
        final match = BattlePayload.parse(
          raw,
          endpoint: isTeam
              ? BattlePayload.teamMatchEndpoint
              : BattlePayload.createEndpoint,
        );
        // The fresh token from create/join is the ONLY credential used for
        // signInWithCustomToken. Never substitute /quiz/firebase-token here.
        if (match.firebaseToken.isEmpty) {
          throw ContractViolation(
            'Battle payload has no firebase_token',
            endpoint: isTeam
                ? BattlePayload.teamMatchEndpoint
                : BattlePayload.createEndpoint,
          );
        }
        return match;
      } on Object catch (e) {
        lastError = e;
        final isLast = i == candidates.length - 1;
        if (isLast || !_canTryNextEndpoint(e)) rethrow;
      }
    }
    if (lastError is Exception) throw lastError;
    if (lastError is Error) throw lastError;
    throw const ContractViolation('Battle match unavailable');
  }

  /// Only fall back when the endpoint itself is unavailable or drifted — a
  /// transport failure or an auth refusal must reach the user as-is.
  static bool _canTryNextEndpoint(Object error) {
    if (error is ContractViolation) return true;
    if (error is DioException) {
      final status = error.response?.statusCode;
      return status == 404 || status == 405 || status == 422 || status == 501;
    }
    return false;
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
      throw const ContractViolation(
        'Battle payload has no firebase_token',
        endpoint: BattlePayload.joinEndpoint,
      );
    }
    return match;
  }

  @override
  Future<Map<String, dynamic>> getBattleResults(String firebaseBattleId) =>
      _remote.getResults(firebaseBattleId);

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

import '../../domain/entities/battle.dart';
import '../../domain/repositories/battle_repository.dart';
import '../datasources/battle_remote_data_source.dart';

class BattleRepositoryImpl implements BattleRepository {
  const BattleRepositoryImpl(this._remote);
  final BattleRemoteDataSource _remote;

  @override
  Future<BattleToken> getFirebaseToken() async {
    final m = await _remote.getFirebaseToken();
    final token = (m['token'] ?? m['custom_token'] ?? m['firebase_token'] ?? '') as String;
    final expRaw = m['expires_at'] ?? m['expiresAt'];
    DateTime? exp;
    if (expRaw is String) exp = DateTime.tryParse(expRaw);
    return BattleToken(token: token, expiresAt: exp);
  }

  @override
  Future<BattleMatch> findMatch() async {
    final m = await _remote.findMatch();
    return BattleMatch(
      id: (m['id'] ?? m['battle_id'] ?? 'demo') as String,
      status: (m['status'] ?? 'searching') as String,
      opponentLabel: (m['opponent'] ?? m['opponent_label'] ?? 'Searching…') as String,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(String boardId) => _remote.getLeaderboard(boardId);
}

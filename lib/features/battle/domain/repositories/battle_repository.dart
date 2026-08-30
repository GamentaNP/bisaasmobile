import '../entities/battle.dart';

abstract class BattleRepository {
  Future<BattleToken> getFirebaseToken();
  Future<BattleMatch> findMatch({String? category});
  Future<List<Map<String, dynamic>>> getLeaderboard(String boardId);
}

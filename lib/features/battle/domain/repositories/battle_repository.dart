import '../entities/battle.dart';

abstract class BattleRepository {
  Future<BattleToken> getFirebaseToken();
  Future<BattleMatch> findMatch({int? categoryId, int totalQuestions = 10});
  Future<List<Map<String, dynamic>>> getLeaderboard(String boardId);
}

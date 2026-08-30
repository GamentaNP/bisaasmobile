import '../entities/leaderboard.dart';

abstract class LeaderboardRepository {
  Future<LeaderboardShow> getLeaderboard(int leaderboardId, {int limit = 20});
  Future<List<MyRank>> getMyRanks();
  Future<Map<String, dynamic>> submitScore({
    required String mode,
    required int score,
    required int correct,
    required int total,
    required int streak,
    String? idempotencyKey,
  });
  Future<List<DonorLeaderboardEntry>> getDonationLeaderboard();
}

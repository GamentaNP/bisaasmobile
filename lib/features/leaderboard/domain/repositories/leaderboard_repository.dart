import '../entities/leaderboard.dart';

abstract class LeaderboardRepository {
  Future<LeaderboardShow> getLeaderboard(int leaderboardId, {int limit = 20});
  Future<List<MyRank>> getMyRanks();
  /// [attemptId] is the completed attempt the server grades. Legacy score
  /// fields remain only for source compatibility — they are not transmitted.
  Future<Map<String, dynamic>> submitScore({
    required String mode,
    int? attemptId,
    int? score,
    int? correct,
    int? total,
    int? streak,
    String? idempotencyKey,
  });
  Future<List<DonorLeaderboardEntry>> getDonationLeaderboard();
}

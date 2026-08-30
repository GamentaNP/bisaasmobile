import '../../domain/entities/leaderboard.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/leaderboard_remote_data_source.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  const LeaderboardRepositoryImpl(this._remote);
  final LeaderboardRemoteDataSource _remote;

  @override
  Future<LeaderboardShow> getLeaderboard(int leaderboardId, {int limit = 20}) => _remote.getLeaderboard(leaderboardId, limit: limit);

  @override
  Future<List<MyRank>> getMyRanks() => _remote.getMyRanks();

  @override
  Future<Map<String, dynamic>> submitScore({
    required String mode,
    required int score,
    required int correct,
    required int total,
    required int streak,
    String? idempotencyKey,
  }) =>
      _remote.submitScore(mode: mode, score: score, correct: correct, total: total, streak: streak, idempotencyKey: idempotencyKey);

  @override
  Future<List<DonorLeaderboardEntry>> getDonationLeaderboard() => _remote.getDonationLeaderboard();
}

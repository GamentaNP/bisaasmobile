import '../entities/contest.dart';

abstract class ContestsRepository {
  Future<({List<Contest> items, int? total, int? perPage, int? currentPage})> getContests({int page = 1, int perPage = 20});
  Future<ContestDetail> getContest(int id);
  Future<Map<String, dynamic>> getJoinIntent(int id);
  Future<int> joinContest(int id, {String? joinIntent, String? idempotencyKey});
  Future<ContestAttempt> enterContest(int id, {String? idempotencyKey});
  Future<List<ContestEntry>> getLeaderboard(int id, {int limit = 20});
  Future<ContestRecap> getRecap(int id);
  Future<void> leaveContest(int id);
}

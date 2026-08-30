import '../../domain/entities/contest.dart';
import '../../domain/repositories/contests_repository.dart';
import '../datasources/contests_remote_data_source.dart';

class ContestsRepositoryImpl implements ContestsRepository {
  const ContestsRepositoryImpl(this._remote);
  final ContestsRemoteDataSource _remote;

  @override
  Future<({List<Contest> items, int? total, int? perPage, int? currentPage})> getContests({int page = 1, int perPage = 20}) async {
    final res = await _remote.getContests(page: page, perPage: perPage);
    final items = res.items.map((d) => d.toDomain()).toList();
    final p = res.pagination;
    return (items: items, total: p?.total, perPage: p?.perPage, currentPage: p?.currentPage);
  }

  @override
  Future<ContestDetail> getContest(int id) async {
    final dto = await _remote.getContest(id);
    return dto.toDomain();
  }

  @override
  Future<Map<String, dynamic>> getJoinIntent(int id) => _remote.getJoinIntent(id);

  @override
  Future<int> joinContest(int id, {String? joinIntent, String? idempotencyKey}) => _remote.joinContest(id, joinIntent: joinIntent, idempotencyKey: idempotencyKey);

  @override
  Future<ContestAttempt> enterContest(int id, {String? idempotencyKey}) async {
    final dto = await _remote.enterContest(id, idempotencyKey: idempotencyKey);
    return dto.toDomain();
  }

  @override
  Future<List<ContestEntry>> getLeaderboard(int id, {int limit = 20}) async {
    final dtos = await _remote.getLeaderboard(id, limit: limit);
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<ContestRecap> getRecap(int id) async {
    final dto = await _remote.getRecap(id);
    return dto.toDomain();
  }

  @override
  Future<void> leaveContest(int id) => _remote.leaveContest(id);
}

import '../../domain/entities/streak.dart';
import '../../domain/repositories/streak_repository.dart';
import '../datasources/streak_remote_data_source.dart';

class StreakRepositoryImpl implements StreakRepository {
  const StreakRepositoryImpl(this._remote);
  final StreakRemoteDataSource _remote;

  @override
  Future<Streak> getStreak() async {
    final dto = await _remote.getStreak();
    return dto.toDomain();
  }

  @override
  Future<bool> freezeStreak() async {
    final dto = await _remote.freezeStreak();
    return dto.frozen;
  }
}

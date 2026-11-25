import '../../domain/entities/achievements.dart';
import '../../domain/repositories/achievements_repository.dart';
import '../datasources/achievements_remote_data_source.dart';

class AchievementsRepositoryImpl implements AchievementsRepository {
  const AchievementsRepositoryImpl(this._remote);

  final AchievementsRemoteDataSource _remote;

  @override
  Future<AchievementsData> getAchievements() async {
    final bundle = await _remote.fetchAchievements();
    return bundle.toDomain();
  }
}

import '../../domain/entities/reward_center.dart';
import '../../domain/repositories/reward_center_repository.dart';
import '../datasources/reward_center_remote_data_source.dart';

class RewardCenterRepositoryImpl implements RewardCenterRepository {
  const RewardCenterRepositoryImpl(this._remote);

  final RewardCenterRemoteDataSource _remote;

  @override
  Future<RewardCenterSnapshot> getSnapshot() => _remote.getSnapshot();
}

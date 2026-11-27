import '../../domain/entities/hall_of_fame.dart';
import '../../domain/repositories/hall_of_fame_repository.dart';
import '../datasources/hall_of_fame_remote_data_source.dart';

class HallOfFameRepositoryImpl implements HallOfFameRepository {
  const HallOfFameRepositoryImpl(this._remote);

  final HallOfFameRemoteDataSource _remote;

  @override
  Future<HallOfFameSnapshot> getSnapshot({
    required String recordType,
    required String period,
    String? search,
  }) =>
      _remote.getSnapshot(recordType: recordType, period: period, search: search);
}

import '../../domain/entities/impact_leaders.dart';
import '../../domain/repositories/impact_leaders_repository.dart';
import '../datasources/impact_leaders_remote_data_source.dart';

class ImpactLeadersRepositoryImpl implements ImpactLeadersRepository {
  const ImpactLeadersRepositoryImpl(this._remote);

  final ImpactLeadersRemoteDataSource _remote;

  @override
  Future<ImpactLeadersSnapshot> getLeaders() => _remote.getLeaders();
}

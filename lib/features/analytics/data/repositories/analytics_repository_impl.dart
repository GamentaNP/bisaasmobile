import '../../domain/entities/analytics.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_data_source.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  const AnalyticsRepositoryImpl(this._remote);

  final AnalyticsRemoteDataSource _remote;

  @override
  Future<AnalyticsOverview> getOverview() => _remote.getOverview();
}

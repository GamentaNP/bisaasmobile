import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._remoteDataSource);
  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<DashboardData> getDashboardData() async {
    final dto = await _remoteDataSource.getDashboard();
    return dto.toDomain();
  }
}

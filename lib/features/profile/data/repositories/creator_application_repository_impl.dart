import '../../domain/entities/creator_application.dart';
import '../../domain/repositories/creator_application_repository.dart';
import '../datasources/creator_application_remote_data_source.dart';

class CreatorApplicationRepositoryImpl implements CreatorApplicationRepository {
  const CreatorApplicationRepositoryImpl(this._remote);

  final CreatorApplicationRemoteDataSource _remote;

  @override
  Future<CreatorApplicationStatus> getCurrent() => _remote.getCurrent();
}

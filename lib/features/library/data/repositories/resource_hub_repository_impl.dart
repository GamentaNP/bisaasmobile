import '../../domain/entities/resource_hub.dart';
import '../../domain/repositories/resource_hub_repository.dart';
import '../datasources/resource_hub_remote_data_source.dart';

class ResourceHubRepositoryImpl implements ResourceHubRepository {
  const ResourceHubRepositoryImpl(this._remote);

  final ResourceHubRemoteDataSource _remote;

  @override
  Future<ResourceHub> getHub() => _remote.getHub();
}

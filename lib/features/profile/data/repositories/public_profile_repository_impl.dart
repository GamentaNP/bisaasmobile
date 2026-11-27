import '../../domain/entities/public_profile.dart';
import '../../domain/repositories/public_profile_repository.dart';
import '../datasources/public_profile_remote_data_source.dart';

class PublicProfileRepositoryImpl implements PublicProfileRepository {
  const PublicProfileRepositoryImpl(this._remote);

  final PublicProfileRemoteDataSource _remote;

  @override
  Future<PublicProfileSnapshot> getProfile(String username) =>
      _remote.getProfile(username);

  @override
  Future<ProfileComparison> compare(String username) => _remote.compare(username);
}

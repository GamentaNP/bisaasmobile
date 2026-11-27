import '../../domain/entities/profile_onboarding_status.dart';
import '../../domain/repositories/profile_onboarding_status_repository.dart';
import '../datasources/profile_onboarding_status_remote_data_source.dart';

class ProfileOnboardingStatusRepositoryImpl
    implements ProfileOnboardingStatusRepository {
  const ProfileOnboardingStatusRepositoryImpl(this._remote);

  final ProfileOnboardingStatusRemoteDataSource _remote;

  @override
  Future<ProfileOnboardingStatus> getStatus() => _remote.getStatus();
}

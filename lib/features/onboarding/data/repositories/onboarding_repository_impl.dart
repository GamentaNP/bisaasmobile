library;

import '../../domain/entities/onboarding_options.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_options_remote_data_source.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._remote);

  final OnboardingOptionsRemoteDataSource _remote;

  @override
  Future<OnboardingOptions> getOptions() => _remote.fetchOptions();
}

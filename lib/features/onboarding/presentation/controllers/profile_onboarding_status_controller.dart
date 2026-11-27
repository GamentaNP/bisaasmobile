/// Provider for the onboarding status read (§9.5).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/profile_onboarding_status_remote_data_source.dart';
import '../../data/repositories/profile_onboarding_status_repository_impl.dart';
import '../../domain/repositories/profile_onboarding_status_repository.dart';

final profileOnboardingStatusRemoteDataSourceProvider =
    Provider<ProfileOnboardingStatusRemoteDataSource>((ref) {
  return ProfileOnboardingStatusRemoteDataSource(ref.watch(dioProvider));
});

final profileOnboardingStatusRepositoryProvider =
    Provider<ProfileOnboardingStatusRepository>((ref) {
  return ProfileOnboardingStatusRepositoryImpl(
    ref.watch(profileOnboardingStatusRemoteDataSourceProvider),
  );
});

final profileOnboardingStatusProvider = FutureProvider((ref) {
  return ref.watch(profileOnboardingStatusRepositoryProvider).getStatus();
});

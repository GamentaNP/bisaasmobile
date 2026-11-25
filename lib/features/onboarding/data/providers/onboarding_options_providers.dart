library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/entities/onboarding_options.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_options_remote_data_source.dart';
import '../repositories/onboarding_repository_impl.dart';

final onboardingOptionsRemoteDataSourceProvider =
    Provider<OnboardingOptionsRemoteDataSource>((ref) {
  return OnboardingOptionsRemoteDataSource(ref.watch(dioProvider));
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(ref.watch(onboardingOptionsRemoteDataSourceProvider));
});

/// The one source of wizard options. Errors propagate to the screen, which
/// renders `ErrorView` with a retry — a drifted body is never shown as an
/// empty list of choices.
final onboardingOptionsProvider = FutureProvider<OnboardingOptions>((ref) {
  return ref.watch(onboardingRepositoryProvider).getOptions();
});

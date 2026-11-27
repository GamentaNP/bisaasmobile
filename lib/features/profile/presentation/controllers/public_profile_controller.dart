/// Providers for public-profile reads (§9.5).
///
/// Keys are usernames, so a different target always issues a fresh bounded
/// read. Failures stay errors for the screen to render with a retry.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/public_profile_remote_data_source.dart';
import '../../data/repositories/public_profile_repository_impl.dart';
import '../../domain/entities/public_profile.dart';
import '../../domain/repositories/public_profile_repository.dart';

final publicProfileRemoteDataSourceProvider = Provider<PublicProfileRemoteDataSource>((ref) {
  return PublicProfileRemoteDataSource(ref.watch(dioProvider));
});

final publicProfileRepositoryProvider = Provider<PublicProfileRepository>((ref) {
  return PublicProfileRepositoryImpl(ref.watch(publicProfileRemoteDataSourceProvider));
});

final publicProfileProvider = FutureProvider.family<PublicProfileSnapshot, String>((ref, username) {
  return ref.watch(publicProfileRepositoryProvider).getProfile(username);
});

final profileCompareProvider = FutureProvider.family<ProfileComparison, String>((ref, username) {
  return ref.watch(publicProfileRepositoryProvider).compare(username);
});

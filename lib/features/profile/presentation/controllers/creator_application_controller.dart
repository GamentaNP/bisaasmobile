/// Provider for the creator-application status read (§9.5).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/creator_application_remote_data_source.dart';
import '../../data/repositories/creator_application_repository_impl.dart';
import '../../domain/repositories/creator_application_repository.dart';

final creatorApplicationRemoteDataSourceProvider =
    Provider<CreatorApplicationRemoteDataSource>((ref) {
  return CreatorApplicationRemoteDataSource(ref.watch(dioProvider));
});

final creatorApplicationRepositoryProvider =
    Provider<CreatorApplicationRepository>((ref) {
  return CreatorApplicationRepositoryImpl(
    ref.watch(creatorApplicationRemoteDataSourceProvider),
  );
});

final creatorApplicationStatusProvider = FutureProvider((ref) {
  return ref.watch(creatorApplicationRepositoryProvider).getCurrent();
});

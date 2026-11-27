/// Provider for the bounded resource-hub snapshot.
///
/// No family key and no pagination: the server rejects every query key.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/resource_hub_remote_data_source.dart';
import '../../data/repositories/resource_hub_repository_impl.dart';
import '../../domain/repositories/resource_hub_repository.dart';

final resourceHubRemoteDataSourceProvider = Provider<ResourceHubRemoteDataSource>((ref) {
  return ResourceHubRemoteDataSource(ref.watch(dioProvider));
});

final resourceHubRepositoryProvider = Provider<ResourceHubRepository>((ref) {
  return ResourceHubRepositoryImpl(ref.watch(resourceHubRemoteDataSourceProvider));
});

final resourceHubProvider = FutureProvider((ref) {
  return ref.watch(resourceHubRepositoryProvider).getHub();
});

/// Provider for the impact-leaderboard snapshot (§9.5).
///
/// No family key: the endpoint is a bounded, non-paged read.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/impact_leaders_remote_data_source.dart';
import '../../data/repositories/impact_leaders_repository_impl.dart';
import '../../domain/repositories/impact_leaders_repository.dart';

final impactLeadersRemoteDataSourceProvider = Provider<ImpactLeadersRemoteDataSource>((ref) {
  return ImpactLeadersRemoteDataSource(ref.watch(dioProvider));
});

final impactLeadersRepositoryProvider = Provider<ImpactLeadersRepository>((ref) {
  return ImpactLeadersRepositoryImpl(ref.watch(impactLeadersRemoteDataSourceProvider));
});

final impactLeadersProvider = FutureProvider((ref) {
  return ref.watch(impactLeadersRepositoryProvider).getLeaders();
});

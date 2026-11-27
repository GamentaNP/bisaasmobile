/// Provider for the reward-center snapshot (§9.5).
///
/// The balance, check-in and spin statuses are the server's conclusions; no
/// local timer or coin math is layered on top of them.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/reward_center_remote_data_source.dart';
import '../../data/repositories/reward_center_repository_impl.dart';
import '../../domain/repositories/reward_center_repository.dart';

final rewardCenterRemoteDataSourceProvider = Provider<RewardCenterRemoteDataSource>((ref) {
  return RewardCenterRemoteDataSource(ref.watch(dioProvider));
});

final rewardCenterRepositoryProvider = Provider<RewardCenterRepository>((ref) {
  return RewardCenterRepositoryImpl(ref.watch(rewardCenterRemoteDataSourceProvider));
});

final rewardCenterProvider = FutureProvider((ref) {
  return ref.watch(rewardCenterRepositoryProvider).getSnapshot();
});

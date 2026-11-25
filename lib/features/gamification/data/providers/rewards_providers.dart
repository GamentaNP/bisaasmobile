import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/entities/rewards.dart';
import '../../domain/repositories/rewards_repository.dart';
import '../datasources/rewards_remote_data_source.dart';
import '../repositories/rewards_repository_impl.dart';

/// Data source and repository for the check-in / spin pair, composed from the
/// app's single Dio instead of inside the screen.
final rewardsRemoteDataSourceProvider = Provider<RewardsRemoteDataSource>((ref) {
  return RewardsRemoteDataSource(ref.watch(dioProvider));
});

final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  return RewardsRepositoryImpl(ref.watch(rewardsRemoteDataSourceProvider));
});

/// Kept under their original public names: `feature_bridges.dart` exports
/// `checkInStatusProvider` from the screen for the home card, and the screen
/// itself watches both.
final checkInStatusProvider = FutureProvider.autoDispose<CheckInStatus>((ref) {
  return ref.watch(rewardsRepositoryProvider).getCheckInStatus();
});

final spinStatusProvider = FutureProvider.autoDispose<SpinStatus>((ref) {
  return ref.watch(rewardsRepositoryProvider).getSpinStatus();
});

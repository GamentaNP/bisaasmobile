import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/entities/achievements.dart';
import '../../domain/repositories/achievements_repository.dart';
import '../datasources/achievements_remote_data_source.dart';
import '../repositories/achievements_repository_impl.dart';

final achievementsRemoteDataSourceProvider =
    Provider<AchievementsRemoteDataSource>((ref) {
  return AchievementsRemoteDataSource(ref.watch(dioProvider));
});

final achievementsRepositoryProvider = Provider<AchievementsRepository>((ref) {
  return AchievementsRepositoryImpl(
      ref.watch(achievementsRemoteDataSourceProvider));
});

/// Kept under its original public name: the screen watches it, and callers
/// outside the feature can reach it through this provider rather than by
/// constructing a Dio themselves.
final achievementsDataProvider = FutureProvider<AchievementsData>((ref) {
  return ref.watch(achievementsRepositoryProvider).getAchievements();
});

/// Providers for the Hall of Fame snapshot.
///
/// Filters are part of the family key so a change re-fetches the snapshot;
/// a failed read remains an error for the screen to render with a retry.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/hall_of_fame_remote_data_source.dart';
import '../../data/repositories/hall_of_fame_repository_impl.dart';
import '../../domain/entities/hall_of_fame.dart';
import '../../domain/repositories/hall_of_fame_repository.dart';

typedef HallOfFameFilters = ({String recordType, String period, String? search});

final hallOfFameRemoteDataSourceProvider = Provider<HallOfFameRemoteDataSource>((ref) {
  return HallOfFameRemoteDataSource(ref.watch(dioProvider));
});

final hallOfFameRepositoryProvider = Provider<HallOfFameRepository>((ref) {
  return HallOfFameRepositoryImpl(ref.watch(hallOfFameRemoteDataSourceProvider));
});

final hallOfFameProvider =
    FutureProvider.family<HallOfFameSnapshot, HallOfFameFilters>((ref, filters) {
  return ref.watch(hallOfFameRepositoryProvider).getSnapshot(
        recordType: filters.recordType,
        period: filters.period,
        search: filters.search,
      );
});

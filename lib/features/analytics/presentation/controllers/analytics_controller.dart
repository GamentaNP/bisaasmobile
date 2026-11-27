/// Provider for `GET /quiz/analytics/overview`.
///
/// A failed read stays an error with retry; the screen never substitutes a
/// fabricated zero-accuracy dashboard for an outage.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/analytics_remote_data_source.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../domain/entities/analytics.dart';
import '../../domain/repositories/analytics_repository.dart';

final analyticsRemoteDataSourceProvider = Provider<AnalyticsRemoteDataSource>((ref) {
  return AnalyticsRemoteDataSource(ref.watch(dioProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(ref.watch(analyticsRemoteDataSourceProvider));
});

final analyticsOverviewProvider = FutureProvider<AnalyticsOverview>((ref) {
  return ref.watch(analyticsRepositoryProvider).getOverview();
});

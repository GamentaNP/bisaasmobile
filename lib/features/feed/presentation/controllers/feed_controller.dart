/// Providers for the activity feed.
///
/// The read is a keyed future: changing the scope re-fetches through the same
/// cursor walk, and a failed read stays an error the screen renders with a
/// retry action — it is never converted into an empty feed.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/feed.dart';
import '../../domain/repositories/feed_repository.dart';

/// Wire-level filter values. Records give the family provider value equality.
typedef FeedFilters = ({String scope, String activityType});

abstract final class FeedScope {
  static const personalized = 'personalized';
  static const friends = 'friends';
  static const global = 'global';
}

final feedRemoteDataSourceProvider = Provider<FeedRemoteDataSource>((ref) {
  return FeedRemoteDataSource(ref.watch(dioProvider));
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl(ref.watch(feedRemoteDataSourceProvider));
});

final feedProvider = FutureProvider.family<List<FeedCard>, FeedFilters>((ref, filters) {
  return ref.watch(feedRepositoryProvider).getFeed(
        scope: filters.scope,
        activityType: filters.activityType,
      );
});

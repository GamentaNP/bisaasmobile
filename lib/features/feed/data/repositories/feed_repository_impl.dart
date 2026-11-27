import '../../domain/entities/feed.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_data_source.dart';

class FeedRepositoryImpl implements FeedRepository {
  const FeedRepositoryImpl(this._remote);

  final FeedRemoteDataSource _remote;

  @override
  Future<List<FeedCard>> getFeed({
    required String scope,
    required String activityType,
  }) =>
      _remote.getFeed(scope: scope, activityType: activityType);
}

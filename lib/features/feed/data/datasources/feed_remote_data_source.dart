/// Data source for `GET /api/v1/quiz/feed`.
///
/// The feed is a bounded 50-card window paged with opaque cursors. The server
/// rejects `page` and any unknown query key, so the only keys sent here are
/// the two `filter[...]` values, `per_page` and (after page one) `cursor`.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/pagination.dart';
import '../../domain/entities/feed.dart';
import '../models/feed_dto.dart';

class FeedRemoteDataSource {
  const FeedRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/quiz/feed';

  /// The service caps the window at 50; this endpoint caps `per_page` at 50.
  static const _perPage = 25;

  Future<List<FeedCard>> getFeed({
    String scope = 'personalized',
    String activityType = 'all',
  }) =>
      collectAllPages<FeedCard>(
        endpoint: endpoint,
        fetch: (cursor) async {
          final res = await _dio.get<Map<String, dynamic>>(
            endpoint,
            queryParameters: cursorQuery(
              cursor: cursor,
              perPage: _perPage,
              extra: <String, dynamic>{
                'filter[scope]': scope,
                'filter[activity_type]': activityType,
              },
            ),
          );
          final body = res.data;
          if (body == null) {
            throw ContractViolation('Empty response body', endpoint: endpoint);
          }
          return parsePage<FeedCard>(
            body,
            (row) => FeedCardDto.fromJson(row, endpoint: endpoint).toDomain(),
            endpoint: endpoint,
          );
        },
      );
}

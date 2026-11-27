/// Data source for the learner-review cluster.
///
/// Verified routes (`MOBILE_API_INTEGRATION_GUIDE.md` §9.4, §13):
///  * GET  /quiz/review/due                 — cursor-only, prompt cards
///  * GET  /quiz/attempts/{attempt}/review  — cursor-only verdict sheet
///  * PUT  /quiz/reviews/{review}/grade      — quality 0..5, Idempotency-Key REQUIRED
///
/// The read is singular (`review/due`), the grade path is plural (`reviews/…`).
/// Both are distinct from `/learning/reviews/*`. Dio's baseUrl already ends
/// with `/api/v1` — never add it again here.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../../../core/network/pagination.dart';
import '../../domain/entities/review.dart';
import '../models/review_dto.dart';

class ReviewRemoteDataSource {
  const ReviewRemoteDataSource(this._dio);

  final Dio _dio;

  static const dueEndpoint = '/quiz/review/due';
  static const gradeEndpoint = '/quiz/reviews/{review}/grade';

  static const _perPage = 50;

  /// Walks the whole due queue with opaque cursors only.
  ///
  /// A transport error, a stalled cursor or a row the client cannot parse
  /// throws — none of them can be mistaken for "nothing is due".
  Future<List<ReviewCard>> getDueCards() => collectAllPages<ReviewCard>(
        endpoint: dueEndpoint,
        fetch: (cursor) async {
          final res = await _dio.get<Map<String, dynamic>>(
            dueEndpoint,
            queryParameters: cursorQuery(cursor: cursor, perPage: _perPage),
          );
          final body = res.data;
          if (body == null) {
            throw ContractViolation('Empty response body', endpoint: dueEndpoint);
          }
          return parsePage<ReviewCard>(
            body,
            (row) => ReviewCardDto.fromJson(row, endpoint: dueEndpoint).toDomain(),
            endpoint: dueEndpoint,
          );
        },
      );

  /// Reads one completed attempt's per-question verdicts.
  ///
  /// The release gate is applied by the server: a locked attempt publishes
  /// null verdicts and explanations, and no answer key is ever sent.
  Future<AttemptReview> getAttemptReview(int attemptId) async {
    final endpoint = '/quiz/attempts/$attemptId/review';
    Map<String, dynamic>? payload;
    final items = await collectAllPages<AttemptReviewItem>(
      endpoint: endpoint,
      fetch: (cursor) async {
        final res = await _dio.get<Map<String, dynamic>>(
          endpoint,
          queryParameters: cursorQuery(cursor: cursor, perPage: _perPage),
        );
        final body = res.data;
        if (body == null) {
          throw ContractViolation('Empty response body', endpoint: endpoint);
        }
        payload = requireDataMap(body, endpoint: endpoint);
        return parsePage<AttemptReviewItem>(
          body,
          (row) => AttemptReviewItemDto.fromJson(row, endpoint: endpoint).toDomain(),
          endpoint: endpoint,
        );
      },
    );
    final data = payload;
    if (data == null) {
      throw ContractViolation('No attempt review payload', endpoint: endpoint);
    }
    final snapshot = AttemptReviewDto.fromJson(data, endpoint: endpoint).toDomain();
    return AttemptReview(
      attemptId: snapshot.attemptId,
      status: snapshot.status,
      policy: snapshot.policy,
      items: items,
    );
  }

  /// Grades one card. Only `quality` and the card family are sent — the
  /// server recomputes the interval, repetitions, easiness and due date.
  ///
  /// [idempotencyKey] must stay stable across retries of the same intent; a
  /// fresh key would apply SM-2 twice after a lost response.
  Future<ReviewGradeResult> gradeReview(
    String reviewId, {
    required int quality,
    required String type,
    String? idempotencyKey,
  }) async {
    if (!ReviewQuality.isValid(quality)) {
      throw ArgumentError.value(quality, 'quality', 'must be between 0 and 5');
    }
    final endpoint = '/quiz/reviews/$reviewId/grade';
    final res = await _dio.put<Map<String, dynamic>>(
      endpoint,
      data: <String, dynamic>{
        'quality': quality,
        'type': type,
      },
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = requireDataMap(body, endpoint: endpoint);
    return ReviewGradeResultDto.fromJson(data, endpoint: endpoint).toDomain();
  }
}

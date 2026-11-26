/// Data source for the unified QUIZ spaced-repetition queue.
///
/// Verified server routes (`routes/api/v1/quiz.php:234-239` in the server
/// repo, `MOBILE_API_INTEGRATION_GUIDE.md` §9.3):
///  * GET  /quiz/reviews/due            — cursor-only, answer keys withheld
///  * PUT  /quiz/reviews/{review}/grade — quality 0..5, Idempotency-Key REQUIRED
///
/// These are NOT the Learning-domain `/learning/reviews/*` atom queue:
/// the ids and the engines are different. Dio's baseUrl already ends with
/// `/api/v1` — never add it again here.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../../../core/network/pagination.dart';
import '../../domain/entities/quiz_srs.dart';
import '../models/quiz_srs_dto.dart';

class QuizSrsRemoteDataSource {
  const QuizSrsRemoteDataSource(this._dio);

  final Dio _dio;

  static const dueEndpoint = '/quiz/reviews/due';

  /// The server caps `per_page` at 100 for this collection.
  static const _perPage = 50;

  /// Walks the whole due queue, round-tripping the opaque cursor verbatim.
  ///
  /// A transport error or a body that does not match the cursor envelope
  /// throws: [collectAllPages] refuses a stalled or looping cursor and
  /// [parsePage] refuses rows it cannot understand, so neither can be
  /// mistaken for "nothing is due".
  Future<List<QuizSrsCardDto>> getDueCards() => collectAllPages<QuizSrsCardDto>(
        endpoint: dueEndpoint,
        fetch: (cursor) async {
          final res = await _dio.get<Map<String, dynamic>>(
            dueEndpoint,
            queryParameters: cursorQuery(cursor: cursor, perPage: _perPage),
          );
          final body = res.data;
          if (body == null) {
            throw const ContractViolation(
              'Empty response body',
              endpoint: dueEndpoint,
            );
          }
          return parsePage<QuizSrsCardDto>(
            body,
            (row) => QuizSrsCardDto.fromJson(row, endpoint: dueEndpoint),
            endpoint: dueEndpoint,
          );
        },
      );

  /// Grades one card. Only [quality] is sent — the server recomputes the
  /// interval, repetitions, easiness factor and next due date.
  ///
  /// [idempotencyKey] must be stable across retries of the same intent; a
  /// fresh key on retry would apply SM-2 twice.
  Future<QuizSrsGradeResultDto> gradeReview(
    String reviewId, {
    required int quality,
    String? type,
    String? idempotencyKey,
  }) async {
    if (!QuizSrsQuality.isValid(quality)) {
      throw ArgumentError.value(quality, 'quality', 'must be between 0 and 5');
    }
    final endpoint = '/quiz/reviews/$reviewId/grade';
    final res = await _dio.put<Map<String, dynamic>>(
      endpoint,
      data: <String, dynamic>{
        'quality': quality,
        'type': ?type,
      },
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = requireDataMap(body, endpoint: endpoint);
    return QuizSrsGradeResultDto.fromJson(data, endpoint: endpoint);
  }
}

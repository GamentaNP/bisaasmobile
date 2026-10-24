/// Search data source — `GET /quiz/questions?search=…` (server query builder 7.3).
///
/// Lives in the data layer like every other remote surface: the presentation
/// side used to call Dio inline, which skipped envelope validation and made
/// the search screen the one feature with no home for its contract.
library;

import 'package:dio/dio.dart';

import '../../../core/network/api_failure.dart';

class SearchRemoteDataSource {
  SearchRemoteDataSource(this._dio);
  final Dio _dio;

  /// Top hits for [query]. The screen caps the list, so this reads one page —
  /// `/quiz/questions` is one of the cursor-shaped routes and `per_page` only
  /// sizes that page.
  Future<List<Map<String, dynamic>>> searchQuestions(String query) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/questions',
      queryParameters: {'search': query, 'per_page': 10},
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty response body', endpoint: '/quiz/questions');
    }
    final data = body['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map<String, dynamic> && data['questions'] is List) {
      return (data['questions'] as List).cast<Map<String, dynamic>>();
    }
    throw const ContractViolation(
      'Search payload not understood',
      endpoint: '/quiz/questions',
    );
  }
}

/// Data source for `GET /quiz/word-bank` (§9.5).
///
/// Cursor-only: `per_page` is validated 10–100 by the server (never clamped),
/// so the client default of 25 is safe. The web-only `?tag=` filter is not
/// offered by the API and is deliberately not sent.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../../../core/network/pagination.dart';
import '../../domain/entities/word_bank.dart';
import '../models/word_bank_dto.dart';

class WordBankRemoteDataSource {
  const WordBankRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/quiz/word-bank';

  Future<WordBankCatalogPage> getWords({
    String? search,
    String? difficulty,
    String? course,
    String? cursor,
    int perPage = 25,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: cursorQuery(
        cursor: cursor,
        perPage: perPage,
        extra: <String, dynamic>{
          if (search != null && search.isNotEmpty) 'filter[search]': search,
          if (difficulty != null &&
              difficulty.isNotEmpty &&
              difficulty != 'all') 'filter[difficulty]': difficulty,
          if (course != null && course.isNotEmpty && course != 'all') 'filter[course]': course,
        },
      ),
    );
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final page = parsePage<Map<String, dynamic>>(body, (j) => j, endpoint: endpoint);
    if (page.isStalled) {
      throw ContractViolation(
        'has_more was true but no next_cursor was published',
        endpoint: endpoint,
      );
    }
    final data = requireDataMap(body, endpoint: endpoint);
    final catalog = WordBankDto.fromJson(data, endpoint: endpoint)
        .toDomain(endpoint: endpoint);

    return WordBankCatalogPage(
      items: catalog.items,
      filters: catalog.filters,
      allTags: catalog.allTags,
      allCourses: catalog.allCourses,
      allDifficulties: catalog.allDifficulties,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }
}

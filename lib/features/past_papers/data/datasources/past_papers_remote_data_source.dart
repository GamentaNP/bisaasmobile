/// Data source for the two past-paper reads (§9.5).
///
/// The catalog is cursor-only: `cursor` is round-tripped verbatim and `page`
/// is never sent. The detail endpoint is a bounded snapshot — no paging and
/// no answer key. Both are authenticated tenant-scoped reads.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../../../core/network/pagination.dart';
import '../../domain/entities/past_paper.dart';
import '../models/past_paper_dto.dart';

class PastPapersRemoteDataSource {
  const PastPapersRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/quiz/past-papers';

  Future<PastPaperCatalogPage> getPapers({
    String? search,
    String? country,
    String? province,
    String? year,
    String? paper,
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
          if (country != null && country.isNotEmpty) 'filter[country]': country,
          if (province != null && province.isNotEmpty) 'filter[province]': province,
          if (year != null && year.isNotEmpty) 'filter[year]': year,
          if (paper != null && paper.isNotEmpty) 'filter[paper]': paper,
        },
      ),
    );
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    // Reuse the one cursor implementation: a has_more without a next_cursor is
    // drift and throws instead of spinning the same page forever.
    final page = parsePage<Map<String, dynamic>>(
      body,
      (j) => j,
      endpoint: endpoint,
    );
    if (page.isStalled) {
      throw ContractViolation(
        'has_more was true but no next_cursor was published',
        endpoint: endpoint,
      );
    }
    final data = requireDataMap(body, endpoint: endpoint);
    final catalog = PastPaperCatalogDto.fromJson(data, endpoint: endpoint)
        .toDomain(endpoint: endpoint);

    return PastPaperCatalogPage(
      items: catalog.items,
      filters: catalog.filters,
      facets: catalog.facets,
      courses: catalog.courses,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  /// `GET /quiz/past-papers/{paper}` — bounded, no answer key.
  ///
  /// The list publishes a `detail_url` API literal. It is the same canonical
  /// path built from the row's id; no web URL is followed from a bearer client.
  Future<PastPaperDetail> getPaper(int paperId) async {
    final endpoint = '/quiz/past-papers/$paperId';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = requireDataMap(body, endpoint: endpoint);
    return PastPaperDetailDto.fromJson(data, endpoint: endpoint)
        .toDomain(endpoint: endpoint);
  }
}

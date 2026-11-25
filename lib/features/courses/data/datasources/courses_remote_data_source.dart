import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/pagination.dart';
import '../../domain/entities/course_catalog.dart';
import '../models/course_catalog_dto.dart';

/// Reads the public course catalog.
///
/// `GET /quiz/courses` is one of the few public routes: no token, no paging
/// parameters. The server publishes every active course as one array; the
/// screen paginates locally so a 90-import course list is not one endless grid.
///
/// A body that is neither a list nor a recognised list envelope is a contract
/// drift and throws [ContractViolation] — it must never read as "no courses".
class CoursesRemoteDataSource {
  const CoursesRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/quiz/courses';

  Future<List<CourseCatalogEntry>> getCourses() async {
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty course catalog response',
          endpoint: endpoint);
    }
    final page = parsePage<CourseCatalogDto>(
      body,
      CourseCatalogDto.fromJson,
      rowKeys: const ['items', 'courses'],
      endpoint: endpoint,
    );
    return page.items.map((dto) => dto.toDomain()).toList();
  }
}

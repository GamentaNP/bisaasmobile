import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../../domain/entities/syllabus.dart';
import '../models/syllabus_dto.dart';

/// Syllabus Engine routes, verified against `routes/api/v1/syllabus.php` in
/// `C:\laragon\www\bisaas` (do not invent routes — re-check that file first).
///
/// Public catalog (no auth):
/// - GET    /syllabi                              version list, cursor paginated
/// - GET    /syllabi/{publicId}                  version detail + exam identity
/// - GET    /syllabi/{publicId}/nodes?depth=N     flat summary, depth-capped
/// - GET    /syllabi/{publicId}/tree?depth=N      nested graph with counts
/// - GET    /syllabi/{publicId}/nodes/{nodeId}    node detail + coverage
/// - GET    /syllabi/{publicId}/blueprint         paper marks blueprint (list)
/// - GET    /syllabi/{publicId}/questions         corpus by version
/// - GET    /syllabi/comparisons, /diff/{a}/{b}   version comparison
///
/// Authenticated:
/// - GET    /syllabi/{publicId}/nodes/{nodeId}/questions   (throttle: quiz-content-read)
/// - GET    /syllabi/{publicId}/nodes/{nodeId}/materials   (throttle: library-api-read)
/// - GET|POST /me/syllabi                          the learner's own plans
/// - PUT|DELETE /me/syllabi/{publicId}
/// - GET    /me/syllabi/{publicId}/progress
/// - PUT    /me/syllabi/{publicId}/nodes/{nodeId}/progress
/// - GET    /me/syllabi/{publicId}/routine
/// - PUT    /me/syllabi/{publicId}/routine/{day}/completion
/// - PUT    /me/syllabi/{publicId}/version
/// - POST   /me/syllabi/{publicId}/exports
/// - GET    /me/syllabi/{publicId}/exports/{export}
///
/// `{version}` binds on `SyllabusVersion::getRouteKeyName()` = **`public_id`**
/// (a ULID). `version_code` is human-facing and is NOT the route key.
class SyllabusRemoteDataSource {
  const SyllabusRemoteDataSource(this._dio);
  final Dio _dio;

  /// Unwraps `{success, data, ...}` and returns the `data` node.
  ///
  /// Returns null rather than throwing on an unexpected shape, so a single
  /// malformed response degrades one screen instead of the whole session.
  Map<String, dynamic>? _dataObject(Map<String, dynamic>? body) {
    if (body == null) return null;
    final envelope = ApiResponse.fromJson(body, (json) => json);
    final data = envelope.data;
    if (data is Map<String, dynamic>) return data;
    if (body['data'] is Map<String, dynamic>) return body['data'] as Map<String, dynamic>;
    return null;
  }

  List<dynamic> _dataList(Map<String, dynamic>? body) {
    if (body == null) return const [];
    final data = body['data'];
    if (data is List) return data;
    if (data is Map && data['items'] is List) return data['items'] as List;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }

  // ── Catalog ────────────────────────────────────────────────────────────────

  Future<List<SyllabusVersionDto>> getVersions({
    int? examId,
    String? authority,
    String? status,
    int perPage = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/syllabi',
      queryParameters: {
        'filter[exam]': ?examId,
        'filter[authority]': ?authority,
        'filter[status]': ?status,
        'per_page': perPage,
      },
    );
    final out = <SyllabusVersionDto>[];
    for (final item in _dataList(res.data)) {
      if (item is! Map) continue;
      final dto = SyllabusVersionDto.fromJson(item.cast<String, dynamic>());
      if (dto != null) out.add(dto);
    }
    return out;
  }

  Future<SyllabusVersionDto?> getVersion(String publicId) async {
    final res = await _dio.get<Map<String, dynamic>>('/syllabi/$publicId');
    final obj = _dataObject(res.data);
    return obj == null ? null : SyllabusVersionDto.fromJson(obj);
  }

  /// Flat depth-capped summary. The server clamps `depth` to 1..6 and defaults
  /// to 2; this is the cheap first paint, whereas [getTree] is the full graph.
  Future<List<SyllabusNodeDto>> getNodeSummary(String publicId, {int depth = 2}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/syllabi/$publicId/nodes',
      queryParameters: {'depth': depth},
    );
    final out = <SyllabusNodeDto>[];
    for (final item in _dataList(res.data)) {
      if (item is! Map) continue;
      final dto = SyllabusNodeDto.fromJson(item.cast<String, dynamic>());
      if (dto != null) out.add(dto);
    }
    return out;
  }

  /// Nested graph. Omit [depth] to get every level — the server caches the
  /// unbounded payload for 24h keyed on `structure_hash`.
  Future<SyllabusTreeDto> getTree(String publicId, {int? depth}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/syllabi/$publicId/tree',
      queryParameters: {'depth': ?depth},
    );
    final obj = _dataObject(res.data) ?? const {};
    return SyllabusTreeDto.fromJson(obj, depthLimited: depth != null);
  }

  Future<SyllabusNodeDetailDto?> getNodeDetail(String publicId, int nodeId) async {
    final res = await _dio.get<Map<String, dynamic>>('/syllabi/$publicId/nodes/$nodeId');
    final obj = _dataObject(res.data);
    final dto = SyllabusNodeDetailDto.fromJson(obj ?? const {});
    return dto.isEmpty ? null : dto;
  }

  /// The server returns a **list** of blueprints for a version, not a single one.
  Future<List<SyllabusBlueprint>> getBlueprints(String publicId) async {
    final res = await _dio.get<Map<String, dynamic>>('/syllabi/$publicId/blueprint');
    return SyllabusBlueprintDto.fromList(res.data?['data']).items;
  }

  // ── The learner's own plans ───────────────────────────────────────────────

  Future<List<UserSyllabusPlanDto>> getMyPlans() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/syllabi');
    final out = <UserSyllabusPlanDto>[];
    for (final item in _dataList(res.data)) {
      if (item is! Map) continue;
      final dto = UserSyllabusPlanDto.fromJson(item.cast<String, dynamic>());
      if (dto != null) out.add(dto);
    }
    return out;
  }

  Future<UserSyllabusPlanDto?> createPlan({
    required int syllabusVersionId,
    String? nickname,
    DateTime? targetExamDate,
    int? dailyMinutes,
    String planningMode = 'exam_date',
    String scopeMode = 'examinable',
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/me/syllabi',
      data: {
        'syllabus_version_id': syllabusVersionId,
        'nickname': ?nickname,
        'target_exam_date': ?targetExamDate?.toIso8601String().split('T').first,
        'daily_minutes': ?dailyMinutes,
        'planning_mode': planningMode,
        'scope_mode': scopeMode,
      },
    );
    final obj = _dataObject(res.data);
    return obj == null ? null : UserSyllabusPlanDto.fromJson(obj);
  }

  Future<void> deletePlan(String publicId) async {
    await _dio.delete<void>('/me/syllabi/$publicId');
  }

  /// Marks a node done. The server is authoritative on progress; this only
  /// reports the user's action and never derives completion locally.
  Future<void> updateNodeProgress(String planPublicId, int nodeId, {required bool completed}) async {
    await _dio.put<void>(
      '/me/syllabi/$planPublicId/nodes/$nodeId/progress',
      data: {'completed': completed},
    );
  }
}

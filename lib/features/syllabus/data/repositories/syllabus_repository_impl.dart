import '../../domain/entities/syllabus.dart';
import '../../domain/repositories/syllabus_repository.dart';
import '../datasources/syllabus_remote_data_source.dart';

class SyllabusRepositoryImpl implements SyllabusRepository {
  const SyllabusRepositoryImpl(this._remote);
  final SyllabusRemoteDataSource _remote;

  @override
  Future<List<SyllabusVersion>> getVersions({int? examId, String? authority, String? status}) async {
    final dtos = await _remote.getVersions(examId: examId, authority: authority, status: status);
    return dtos.map((d) => d.domain).toList();
  }

  @override
  Future<SyllabusVersion?> getVersion(String publicId) async =>
      (await _remote.getVersion(publicId))?.domain;

  @override
  Future<List<SyllabusNode>> getNodeSummary(String publicId, {int depth = 2}) async {
    final dtos = await _remote.getNodeSummary(publicId, depth: depth);
    return dtos.map((d) => d.domain).toList();
  }

  @override
  Future<SyllabusTree> getTree(String publicId, {int? depth}) async =>
      (await _remote.getTree(publicId, depth: depth)).domain;

  @override
  Future<SyllabusNodeDetail?> getNodeDetail(String publicId, int nodeId) async {
    final dto = await _remote.getNodeDetail(publicId, nodeId);
    return dto?.domain;
  }

  @override
  Future<List<SyllabusBlueprint>> getBlueprints(String publicId) =>
      _remote.getBlueprints(publicId);

  @override
  Future<List<UserSyllabusPlan>> getMyPlans() async {
    final dtos = await _remote.getMyPlans();
    return dtos.map((d) => d.domain).toList();
  }

  @override
  Future<UserSyllabusPlan?> createPlan({
    required int syllabusVersionId,
    String? nickname,
    DateTime? targetExamDate,
    int? dailyMinutes,
    String planningMode = 'exam_date',
    String scopeMode = 'examinable',
  }) async {
    final dto = await _remote.createPlan(
      syllabusVersionId: syllabusVersionId,
      nickname: nickname,
      targetExamDate: targetExamDate,
      dailyMinutes: dailyMinutes,
      planningMode: planningMode,
      scopeMode: scopeMode,
    );
    return dto?.domain;
  }

  @override
  Future<void> deletePlan(String publicId) => _remote.deletePlan(publicId);

  @override
  Future<void> updateNodeProgress(String planPublicId, int nodeId, {required bool completed}) =>
      _remote.updateNodeProgress(planPublicId, nodeId, completed: completed);
}

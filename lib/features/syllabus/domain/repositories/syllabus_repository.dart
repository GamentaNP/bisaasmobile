import '../entities/syllabus.dart';

/// Syllabus reads. Server-authoritative: the client never derives coverage,
/// completion, or marks — it only renders what the Syllabus Engine returns.
abstract class SyllabusRepository {
  Future<List<SyllabusVersion>> getVersions({int? examId, String? authority, String? status});

  Future<SyllabusVersion?> getVersion(String publicId);

  /// Flat depth-capped node summary for a cheap first paint.
  Future<List<SyllabusNode>> getNodeSummary(String publicId, {int depth});

  /// Nested graph with subtree-inclusive question and material counts.
  Future<SyllabusTree> getTree(String publicId, {int? depth});

  Future<SyllabusNodeDetail?> getNodeDetail(String publicId, int nodeId);

  /// A version can define several papers, so this is a list.
  Future<List<SyllabusBlueprint>> getBlueprints(String publicId);

  Future<List<UserSyllabusPlan>> getMyPlans();

  Future<UserSyllabusPlan?> createPlan({
    required int syllabusVersionId,
    String? nickname,
    DateTime? targetExamDate,
    int? dailyMinutes,
    String planningMode,
    String scopeMode,
  });

  Future<void> deletePlan(String publicId);

  /// Reports the user's action. Progress itself stays server-computed.
  Future<void> updateNodeProgress(String planPublicId, int nodeId, {required bool completed});
}

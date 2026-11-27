import '../../domain/entities/eice_data.dart';
import '../../domain/repositories/eice_repository.dart';
import '../eice_remote_data_source.dart';

/// Thin repository over the existing data source.
///
/// It maps the data source's raw maps to domain payloads without touching how
/// they are read: the data source still owns the envelope checks and still
/// throws on an unreadable 2xx body, so a failure cannot be rendered as an
/// empty study plan.
class EiceRepositoryImpl implements EiceRepository {
  const EiceRepositoryImpl(this._remote);

  final EiceRemoteDataSource _remote;

  static EicePayload? _payload(Map<String, dynamic>? raw) =>
      raw == null ? null : EicePayload(raw);

  @override
  Future<EicePayload?> getCoach() async => _payload(await _remote.getCoach());

  @override
  Future<EicePayload?> getCombinedStudyPlan() async =>
      _payload(await _remote.getCombinedStudyPlan());

  @override
  Future<EicePayload?> getStudyPlan(int examId) async =>
      _payload(await _remote.getStudyPlan(examId));

  @override
  Future<EicePayload?> getTriage(int examId) async =>
      _payload(await _remote.getTriage(examId));

  @override
  Future<EicePayload?> getTopicPattern(int topicId) async =>
      _payload(await _remote.getTopicPattern(topicId));

  @override
  Future<EicePayload?> getCoursePatterns(int courseId) async =>
      _payload(await _remote.getCoursePatterns(courseId));

  @override
  Future<List<EicePayload>> getSprint() async {
    final rows = await _remote.getSprint();
    return rows.map(EicePayload.new).toList(growable: false);
  }

  @override
  Future<EicePayload?> getWeekly() async => _payload(await _remote.getWeekly());

  @override
  Future<List<EicePayload>> getWeeklyHistory() async {
    final rows = await _remote.getWeeklyHistory();
    return rows.map(EicePayload.new).toList(growable: false);
  }

  @override
  Future<bool> gradeSprint(String questionId, int grade) =>
      _remote.gradeSprint(questionId, grade);
}

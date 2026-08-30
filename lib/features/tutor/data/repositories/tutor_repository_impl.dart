import '../../domain/entities/tutor.dart';
import '../../domain/repositories/tutor_repository.dart';
import '../datasources/tutor_remote_data_source.dart';

class TutorRepositoryImpl implements TutorRepository {
  const TutorRepositoryImpl(this._remote);
  final TutorRemoteDataSource _remote;

  @override
  Future<TutorOnboardingSession> startOnboarding({Map<String, dynamic>? payload}) async {
    final dto = await _remote.startOnboarding(payload: payload);
    return dto.toDomain();
  }

  @override
  Future<void> completeOnboarding(String sessionId, {Map<String, dynamic>? payload}) async {
    await _remote.completeOnboarding(sessionId, payload: payload);
  }

  @override
  Future<TutorChatResult> chat(String message, {List<TutorMessage>? history}) async {
    final hist = history?.map((m) => {'role': m.role, 'content': m.content}).toList();
    final dto = await _remote.chat(message, history: hist);
    return dto.toDomain();
  }

  @override
  Future<String> askLegacyTutor(String prompt, {List<TutorMessage>? history}) async {
    final hist = history?.map((m) => {'role': m.role, 'content': m.content}).toList();
    return _remote.askLegacyTutor(prompt, history: hist);
  }

  @override
  Future<TutorPlan> getPlan() async {
    final dto = await _remote.getPlan();
    return dto.toDomain();
  }

  @override
  Future<TutorToday> getToday() async {
    final dto = await _remote.getToday();
    return dto.toDomain();
  }

  @override
  Future<void> completeDay({String? dayId, int? dayIndex}) =>
      _remote.completeDay(dayId: dayId, dayIndex: dayIndex);

  @override
  Future<void> adjustPlan(Map<String, dynamic> adjustments) =>
      _remote.adjustPlan(adjustments);

  @override
  Future<List<WeakArea>> getWeakAreas() async {
    final dtos = await _remote.getWeakAreas();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<ProjectedScore> getProjectedScore() async {
    final dto = await _remote.getProjectedScore();
    return dto.toDomain();
  }

  @override
  Future<WeeklyReport> getWeeklyReport() async {
    final dto = await _remote.getWeeklyReport();
    return dto.toDomain();
  }

  @override
  Future<List<RevisionItem>> getRevisionsDue() async {
    final dtos = await _remote.getRevisionsDue();
    return dtos.map((d) => d.toDomain()).toList();
  }
}

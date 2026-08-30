import '../../domain/entities/learning.dart';
import '../../domain/repositories/learning_repository.dart';
import '../datasources/learning_remote_data_source.dart';

class LearningRepositoryImpl implements LearningRepository {
  const LearningRepositoryImpl(this._remote);
  final LearningRemoteDataSource _remote;

  @override
  Future<List<LearningTrack>> getTracks() async {
    final dtos = await _remote.getTracks();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<List<LearningGoal>> getGoals() async {
    final dtos = await _remote.getGoals();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<LearningGoal> createGoal({
    required int trackId,
    String? targetDate,
    int? dailyMinutes,
    String? intensity,
    Map<String, dynamic>? placementMeta,
    String? idempotencyKey,
  }) async {
    final dto = await _remote.createGoal(
      trackId: trackId,
      targetDate: targetDate,
      dailyMinutes: dailyMinutes,
      intensity: intensity,
      placementMeta: placementMeta,
      idempotencyKey: idempotencyKey,
    );
    return dto.toDomain();
  }

  @override
  Future<LearningGoal> getGoal(int goalId) async {
    final dto = await _remote.getGoal(goalId);
    return dto.toDomain();
  }

  @override
  Future<LearningGoalReadiness> getGoalReadiness(int goalId) async {
    final dto = await _remote.getGoalReadiness(goalId);
    return dto.toDomain();
  }

  @override
  Future<void> deleteGoal(int goalId) => _remote.deleteGoal(goalId);

  @override
  Future<DailyPlan?> getToday() async {
    final dto = await _remote.getToday();
    return dto?.toDomain();
  }

  @override
  Future<DailyPlan> completeTodayItem(int planId, int itemIndex, {String? idempotencyKey}) async {
    final dto = await _remote.completeTodayItem(planId, itemIndex, idempotencyKey: idempotencyKey);
    return dto.toDomain();
  }

  @override
  Future<List<ReviewItem>> getReviewsDue() async {
    final dtos = await _remote.getReviewsDue();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<ReviewItem> gradeReview(int reviewId, String outcome, {String? idempotencyKey}) async {
    final dto = await _remote.gradeReview(reviewId, outcome, idempotencyKey: idempotencyKey);
    return dto.toDomain();
  }

  @override
  Future<TutorReply> askTutor({
    required String topic,
    required String question,
    String? learnerAnswer,
    String? misconception,
    String? idempotencyKey,
  }) async {
    final dto = await _remote.askTutor(
      topic: topic,
      question: question,
      learnerAnswer: learnerAnswer,
      misconception: misconception,
      idempotencyKey: idempotencyKey,
    );
    return dto.toDomain();
  }

  @override
  Future<String> askTutorLegacy(String prompt, {List<TutorMessage>? history}) async {
    final hist = history?.map((m) => {'role': m.role, 'content': m.content}).toList();
    return _remote.askTutorLegacy(prompt, history: hist);
  }
}

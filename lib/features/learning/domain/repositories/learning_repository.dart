import '../entities/learning.dart';

abstract class LearningRepository {
  // Tracks
  Future<List<LearningTrack>> getTracks();

  // Goals
  Future<List<LearningGoal>> getGoals();
  Future<LearningGoal> createGoal({
    required int trackId,
    String? targetDate,
    int? dailyMinutes,
    String? intensity,
    Map<String, dynamic>? placementMeta,
    String? idempotencyKey,
  });
  Future<LearningGoal> getGoal(int goalId);
  Future<LearningGoalReadiness> getGoalReadiness(int goalId);
  Future<void> deleteGoal(int goalId);

  // Today
  Future<DailyPlan?> getToday();
  Future<DailyPlan> completeTodayItem(int planId, int itemIndex, {String? idempotencyKey});

  // Reviews (SRS)
  Future<List<ReviewItem>> getReviewsDue();
  Future<ReviewItem> gradeReview(int reviewId, String outcome, {String? idempotencyKey});

  // Tutor (POST /learning/tutor non-streaming)
  Future<TutorReply> askTutor({
    required String topic,
    required String question,
    String? learnerAnswer,
    String? misconception,
    String? idempotencyKey,
  });

  // Legacy chat alias — history is TutorMessage list for convenience
  Future<String> askTutorLegacy(String prompt, {List<TutorMessage>? history});
}

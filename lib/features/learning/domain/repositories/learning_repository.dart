import '../entities/learning.dart';

abstract class LearningRepository {
  Future<List<LearningTrack>> getTracks();
  Future<TodayPlan> getToday();
  Future<List<ReviewItem>> getReviewsDue();
  Future<String> askTutor(String prompt, {List<TutorMessage>? history});
}

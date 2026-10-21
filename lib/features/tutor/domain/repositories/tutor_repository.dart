import '../entities/tutor.dart';

abstract class TutorRepository {
  // Onboarding
  Future<TutorOnboardingSession> startOnboarding({Map<String, dynamic>? payload});
  Future<void> completeOnboarding(String sessionId, {Map<String, dynamic>? payload});

  // Chat
  ///
  /// Posts to `POST /learning/tutor`, the route the server records in the AI
  /// usage ledger.
  Future<TutorChatResult> chat(
    String message, {
    List<TutorMessage>? history,
    String topic,
  });

  // Plan
  Future<TutorPlan> getPlan();
  Future<TutorToday> getToday();
  Future<void> completeDay({String? dayId, int? dayIndex});
  Future<void> adjustPlan(Map<String, dynamic> adjustments);

  // Insights
  Future<List<WeakArea>> getWeakAreas();
  Future<ProjectedScore> getProjectedScore();
  Future<WeeklyReport> getWeeklyReport();
  Future<List<RevisionItem>> getRevisionsDue();
}

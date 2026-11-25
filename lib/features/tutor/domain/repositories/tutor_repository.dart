import '../entities/tutor.dart';

abstract class TutorRepository implements LearningAnalyticsSource {
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

  // Insights — also satisfy LearningAnalyticsSource for cross-feature use.
  @override
  Future<List<WeakArea>> getWeakAreas();
  @override
  Future<ProjectedScore> getProjectedScore();
  @override
  Future<WeeklyReport> getWeeklyReport();
  @override
  Future<List<RevisionItem>> getRevisionsDue();
}

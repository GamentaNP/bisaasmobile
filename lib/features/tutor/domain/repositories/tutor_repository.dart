import '../entities/tutor.dart';

abstract class TutorRepository {
  // Onboarding
  Future<TutorOnboardingSession> startOnboarding({Map<String, dynamic>? payload});
  Future<void> completeOnboarding(String sessionId, {Map<String, dynamic>? payload});

  // Chat
  Future<TutorChatResult> chat(String message, {List<TutorMessage>? history});
  Future<String> askLegacyTutor(String prompt, {List<TutorMessage>? history});

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

import '../entities/eice_data.dart';

/// Study-planner reads and sprint grading, server-authoritative.
///
/// A null result means the server published no payload; a transport or
/// contract failure throws (it never becomes null or an empty list).
abstract class EiceRepository {
  /// `GET /quiz/coach` - exam resolved server-side.
  Future<EicePayload?> getCoach();

  /// `GET /quiz/study-planner/combined` - all enrolled courses in one plan.
  Future<EicePayload?> getCombinedStudyPlan();

  /// `GET /quiz/study-planner/{examId}` - full mode-aware plan.
  Future<EicePayload?> getStudyPlan(int examId);

  /// `GET /quiz/study-planner/{examId}/readiness` - strict verdict.
  Future<EicePayload?> getReadiness(int examId);

  /// `GET /quiz/study-planner/{examId}/triage`
  Future<EicePayload?> getTriage(int examId);

  /// `GET /quiz/topics/{topicId}/pattern` - one topic's past-paper frequency.
  Future<EicePayload?> getTopicPattern(int topicId);

  /// `GET /quiz/courses/{courseId}/patterns` - the course heatmap.
  Future<EicePayload?> getCoursePatterns(int courseId);

  /// `GET /quiz/sprint`
  Future<List<EicePayload>> getSprint();

  /// `GET /quiz/reports/weekly`
  Future<EicePayload?> getWeekly();

  /// `GET /quiz/reports/weekly/history` - past reports, newest week first.
  Future<List<EicePayload>> getWeeklyHistory();

  /// `PUT /quiz/sprint/{questionId}/grade`
  Future<bool> gradeSprint(String questionId, int grade);
}

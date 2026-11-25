import '../entities/eice_data.dart';

/// Study-planner reads and sprint grading, server-authoritative.
///
/// A null result means the server published no payload; a transport or
/// contract failure throws (it never becomes null or an empty list).
abstract class EiceRepository {
  /// `GET /quiz/coach` - exam resolved server-side.
  Future<EicePayload?> getCoach();

  /// `GET /quiz/study-planner/{examId}/triage`
  Future<EicePayload?> getTriage(int examId);

  /// `GET /quiz/sprint`
  Future<List<EicePayload>> getSprint();

  /// `GET /quiz/reports/weekly`
  Future<EicePayload?> getWeekly();

  /// `PUT /quiz/sprint/{questionId}/grade`
  Future<bool> gradeSprint(String questionId, int grade);
}

import '../entities/psc.dart';

/// PSC blueprint catalogue and the exam lifecycle.
///
/// Failures propagate - an outage is never rendered as "no blueprints".
abstract class PscRepository {
  Future<List<PscBlueprint>> getBlueprints();
  Future<PscExam?> startExam(String id);
  Future<PscSubmission?> submit(String id, Map<String, dynamic> payload);
}

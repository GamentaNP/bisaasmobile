import '../entities/coaching.dart';
import '../../../tutor/domain/entities/tutor.dart';

abstract class CoachingRepository {
  Future<Readiness?> getReadiness(String goalId);
  Future<CoachingToday?> getToday();
  Future<List<CoachingTrack>> getTracks();
  Future<List<WeakArea>> getWeakAreas();
  Future<ProjectedScore?> getProjectedScore();
  Future<WeeklyReport?> getWeeklyReport();
  Future<List<RevisionItem>> getRevisionsDue();

  /// Aggregated dashboard — tolerant: partial failures return partial data,
  /// never throws on single source failure. Coaching is presentation-layer
  /// aggregation per spec when no dedicated route exists.
  Future<CoachingDashboardData> getDashboard({String? goalId});
}

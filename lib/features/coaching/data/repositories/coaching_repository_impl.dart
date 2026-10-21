// ignore_for_file: omit_local_variable_types
import '../../domain/entities/coaching.dart';
import '../../domain/repositories/coaching_repository.dart';
import '../datasources/coaching_remote_data_source.dart';
import '../../../tutor/domain/entities/tutor.dart';
import '../../../tutor/domain/repositories/tutor_repository.dart';

class CoachingRepositoryImpl implements CoachingRepository {
  const CoachingRepositoryImpl(
    this._remote,
    this._tutorRepo,
  );

  final CoachingRemoteDataSource _remote;
  final TutorRepository _tutorRepo;

  @override
  Future<Readiness?> getReadiness(String goalId) async {
    final dto = await _remote.getReadiness(goalId);
    return dto?.toDomain();
  }

  @override
  Future<CoachingToday?> getToday() async {
    final dto = await _remote.getToday();
    return dto?.toDomain();
  }

  @override
  Future<List<CoachingTrack>> getTracks() async {
    final dtos = await _remote.getTracks();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<List<WeakArea>> getWeakAreas() => _tutorRepo.getWeakAreas();

  @override
  Future<ProjectedScore?> getProjectedScore() => _tutorRepo.getProjectedScore();

  @override
  Future<WeeklyReport?> getWeeklyReport() => _tutorRepo.getWeeklyReport();

  @override
  Future<List<RevisionItem>> getRevisionsDue() => _tutorRepo.getRevisionsDue();

  @override
  Future<CoachingDashboardData> getDashboard({String? goalId}) async {
    // Fan-out with tolerant individual failures — the dashboard itself never
    // throws, but a section that failed is **recorded** rather than rendered
    // as "no weak areas" / "projected score 0.0".
    Readiness? readiness;
    CoachingToday? today;
    List<CoachingTrack> tracks = [];
    List<WeakArea> weakAreas = [];
    ProjectedScore? projectedScore;
    WeeklyReport? weeklyReport;
    List<RevisionItem> revisionsDue = [];

    final failedSections = <String>[];

    Future<void> section(
      String name,
      Future<void> Function() run,
    ) async {
      try {
        await run();
      } on Object {
        failedSections.add(name);
      }
    }

    await Future.wait([
      section('readiness', () async {
        if (goalId != null && goalId.isNotEmpty) {
          readiness = await getReadiness(goalId);
        }
      }),
      section('today', () async {
        today = await getToday();
      }),
      section('tracks', () async {
        tracks = await getTracks();
      }),
      section('weakAreas', () async {
        weakAreas = await getWeakAreas();
      }),
      section('projectedScore', () async {
        projectedScore = await getProjectedScore();
      }),
      section('weeklyReport', () async {
        weeklyReport = await getWeeklyReport();
      }),
      section('revisionsDue', () async {
        revisionsDue = await getRevisionsDue();
      }),
    ]);

    // A section that failed is not the same as a section that is empty, so
    // the banner names the failures instead of implying a quiet account.
    final isDegraded = failedSections.isNotEmpty;

    return CoachingDashboardData(
      readiness: readiness,
      today: today,
      tracks: tracks,
      weakAreas: weakAreas,
      projectedScore: projectedScore,
      weeklyReport: weeklyReport,
      revisionsDue: revisionsDue,
      isDegraded: isDegraded,
      failedSections: failedSections,
    );
  }
}

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
  Future<List<WeakArea>> getWeakAreas() async {
    try {
      return await _tutorRepo.getWeakAreas();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ProjectedScore?> getProjectedScore() async {
    try {
      return await _tutorRepo.getProjectedScore();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WeeklyReport?> getWeeklyReport() async {
    try {
      return await _tutorRepo.getWeeklyReport();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<RevisionItem>> getRevisionsDue() async {
    try {
      return await _tutorRepo.getRevisionsDue();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<CoachingDashboardData> getDashboard({String? goalId}) async {
    // Fan-out with tolerant individual failures — dashboard never throws.
    Readiness? readiness;
    CoachingToday? today;
    List<CoachingTrack> tracks = [];
    List<WeakArea> weakAreas = [];
    ProjectedScore? projectedScore;
    WeeklyReport? weeklyReport;
    List<RevisionItem> revisionsDue = [];

    final futures = <Future<void>>[
      () async {
        if (goalId != null && goalId.isNotEmpty) {
          readiness = await getReadiness(goalId);
        }
      }(),
      () async {
        today = await getToday();
      }(),
      () async {
        tracks = await getTracks();
      }(),
      () async {
        weakAreas = await getWeakAreas();
      }(),
      () async {
        projectedScore = await getProjectedScore();
      }(),
      () async {
        weeklyReport = await getWeeklyReport();
      }(),
      () async {
        revisionsDue = await getRevisionsDue();
      }(),
    ];

    await Future.wait(futures.map((f) => f.catchError((_) {})));

    final isDegraded = readiness == null && today == null && weakAreas.isEmpty && projectedScore == null;

    return CoachingDashboardData(
      readiness: readiness,
      today: today,
      tracks: tracks,
      weakAreas: weakAreas,
      projectedScore: projectedScore,
      weeklyReport: weeklyReport,
      revisionsDue: revisionsDue,
      isDegraded: isDegraded,
    );
  }
}

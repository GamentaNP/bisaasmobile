import 'package:meta/meta.dart';

import '../../../tutor/domain/entities/tutor.dart';

@immutable
class Readiness {
  const Readiness({
    required this.goalId,
    this.score,
    this.level,
    this.breakdown = const {},
    this.missingTopics = const [],
    this.nextSteps = const [],
    this.updatedAt,
  });

  final String goalId;
  final double? score;
  final String? level;
  final Map<String, dynamic> breakdown;
  final List<String> missingTopics;
  final List<String> nextSteps;
  final DateTime? updatedAt;

  bool get hasData => score != null;
  double get percentage => score == null ? 0 : score!.clamp(0, 100);
}

@immutable
class CoachingTrack {
  const CoachingTrack({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
  });

  final String id;
  final String slug;
  final String name;
  final String? description;
}

@immutable
class CoachingToday {
  const CoachingToday({
    required this.date,
    this.title = 'Today',
    this.tasks = const [],
    this.completedCount = 0,
    this.totalCount = 0,
    this.summary,
  });

  final DateTime date;
  final String title;
  final List<String> tasks;
  final int completedCount;
  final int totalCount;
  final String? summary;

  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;
}

@immutable
class CoachingDashboardData {
  const CoachingDashboardData({
    this.readiness,
    this.today,
    this.tracks = const [],
    this.weakAreas = const [],
    this.projectedScore,
    this.weeklyReport,
    this.revisionsDue = const [],
    this.isDegraded = false,
  });

  final Readiness? readiness;
  final CoachingToday? today;
  final List<CoachingTrack> tracks;
  final List<WeakArea> weakAreas;
  final ProjectedScore? projectedScore;
  final WeeklyReport? weeklyReport;
  final List<RevisionItem> revisionsDue;
  final bool isDegraded;

  bool get hasAnyData =>
      readiness != null ||
      today != null ||
      tracks.isNotEmpty ||
      weakAreas.isNotEmpty ||
      projectedScore != null ||
      weeklyReport != null ||
      revisionsDue.isNotEmpty;
}
